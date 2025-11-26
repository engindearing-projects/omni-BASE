//
//  CSREnrollmentService.swift
//  OmniTAKMobile
//
//  CSR-based certificate enrollment with TAK servers
//  Implements standard TAK enrollment flow: CSR generation → submission → certificate storage
//

import Foundation
import Security

// MARK: - Enrollment Errors

enum CSREnrollmentError: LocalizedError {
    case invalidServerURL
    case networkError(Error)
    case authenticationFailed
    case serverError(Int, String)
    case invalidResponse(String)
    case certificateStorageFailed(String)
    case configurationError(String)

    var errorDescription: String? {
        switch self {
        case .invalidServerURL:
            return "Invalid server URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Authentication failed - check username and password"
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .invalidResponse(let details):
            return "Invalid server response: \(details)"
        case .certificateStorageFailed(let details):
            return "Failed to store certificate: \(details)"
        case .configurationError(let details):
            return "Configuration error: \(details)"
        }
    }
}

// MARK: - Enrollment Configuration

struct CSREnrollmentConfiguration {
    let serverHost: String
    let serverPort: Int                 // CoT streaming port
    let enrollmentPort: Int             // API/enrollment port (usually 8446)
    let username: String
    let password: String
    let useSSL: Bool

    // Paths (TAK standard endpoints)
    let configPath: String = "/Marti/api/tls/config"
    let csrPath: String = "/Marti/api/tls/signClient/v2"

    // Client info for CSR submission
    let clientUid: String = UUID().uuidString
    let clientVersion: String = "OmniTAK-1.0"

    var baseURL: String {
        let scheme = useSSL ? "https" : "http"
        return "\(scheme)://\(serverHost):\(enrollmentPort)"
    }

    var configURL: URL? {
        URL(string: "\(baseURL)\(configPath)")
    }

    var csrURL: URL? {
        // TAKAware includes clientUid and version as query params
        let escapedUid = clientUid.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? clientUid
        let escapedVersion = clientVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? clientVersion
        return URL(string: "\(baseURL)\(csrPath)?clientUid=\(escapedUid)&version=\(escapedVersion)")
    }
}

// MARK: - CA Configuration (from server)

struct CAConfiguration {
    var organizationNames: [String] = []
    var organizationalUnitNames: [String] = []
    var domainComponents: [String] = []
}

// MARK: - Enrollment Response

struct EnrollmentResponse {
    let signedCertificate: Data         // DER-encoded signed certificate
    let trustChain: [Data]              // DER-encoded CA certificates
    let privateKeyTag: String           // Tag to retrieve private key from keychain
}

// MARK: - CSR Enrollment Service

class CSREnrollmentService {

    private let csrGenerator = CSRGenerator()
    private let urlSession: URLSession

    init() {
        // Configure URLSession to accept self-signed certificates (common in TAK deployments)
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60

        self.urlSession = URLSession(
            configuration: configuration,
            delegate: CSRSelfSignedCertificateDelegate(),
            delegateQueue: nil
        )
    }

    // MARK: - Main Enrollment Method

    /// Enroll with TAK server using CSR-based authentication
    /// - Parameter config: Enrollment configuration with server and credentials
    /// - Returns: TAKServer configuration with enrolled certificates
    func enrollWithCSR(config: CSREnrollmentConfiguration) async throws -> TAKServer {
        print("[CSREnroll] Starting CSR-based enrollment for user: \(config.username)")

        // Step 1: Get CA configuration from server (provides DN components)
        print("[CSREnroll] Fetching CA configuration from server...")
        let caConfig = try await fetchCAConfiguration(config: config)
        print("[CSREnroll] CA configuration retrieved: O=\(caConfig.organizationNames), OU=\(caConfig.organizationalUnitNames)")

        // Step 2: Generate CSR with DN from server
        print("[CSREnroll] Generating CSR...")
        let csrResult = try csrGenerator.generateCSR(
            username: config.username,
            caConfig: caConfig
        )
        print("[CSREnroll] CSR generated successfully")

        // Step 3: Submit CSR to server
        print("[CSREnroll] Submitting CSR to server...")
        let enrollmentResponse = try await submitCSR(
            csrBase64: csrResult.csrBase64,
            config: config
        )
        print("[CSREnroll] Received signed certificate from server")

        // Step 4: Store signed certificate with private key
        print("[CSREnroll] Storing certificate and creating identity...")
        let certificateAlias = try storeCertificateIdentity(
            response: enrollmentResponse,
            privateKeyTag: csrResult.privateKeyTag,
            serverHost: config.serverHost
        )
        print("[CSREnroll] Certificate identity stored successfully")

        // Step 5: Create server configuration
        let serverInstance = TAKServer(
            id: UUID(),
            name: "TAK Server (\(config.serverHost))",
            host: config.serverHost,
            port: UInt16(config.serverPort),
            protocolType: config.useSSL ? "ssl" : "tcp",
            useTLS: config.useSSL,
            isDefault: false,
            certificateName: certificateAlias,
            certificatePassword: nil
        )

        // Add server to manager (must be on main thread for @Published properties)
        await MainActor.run {
            ServerManager.shared.addServer(serverInstance)
        }

        print("[CSREnroll] Enrollment completed successfully")
        return serverInstance
    }

    // MARK: - CA Configuration Retrieval

    private func fetchCAConfiguration(config: CSREnrollmentConfiguration) async throws -> CAConfiguration {
        guard let url = config.configURL else {
            throw CSREnrollmentError.invalidServerURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue(generateAuthHeader(config: config), forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CSREnrollmentError.invalidResponse("Not an HTTP response")
            }

            print("[CSREnroll] Config response status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw CSREnrollmentError.authenticationFailed
                }
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw CSREnrollmentError.serverError(httpResponse.statusCode, errorMsg)
            }

            // Parse XML configuration (TAK servers return XML from /Marti/api/tls/config)
            return parseCAConfigXML(data: data)

        } catch let error as CSREnrollmentError {
            throw error
        } catch {
            throw CSREnrollmentError.networkError(error)
        }
    }

    /// Parse CA configuration XML response
    /// Format: <nameEntry name="O" value="Organization"/>
    private func parseCAConfigXML(data: Data) -> CAConfiguration {
        var caConfig = CAConfiguration()

        guard let xmlString = String(data: data, encoding: .utf8) else {
            print("[CSREnroll] Warning: Could not decode config response as UTF-8")
            return caConfig
        }

        print("[CSREnroll] Parsing CA config XML...")

        // Simple XML parsing for nameEntry elements
        // Format: <nameEntry name="O" value="OrganizationName"/>
        let pattern = #"<nameEntry\s+name="([^"]+)"\s+value="([^"]+)"/?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            print("[CSREnroll] Warning: Failed to create regex for XML parsing")
            return caConfig
        }

        let range = NSRange(xmlString.startIndex..., in: xmlString)
        let matches = regex.matches(in: xmlString, options: [], range: range)

        for match in matches {
            guard match.numberOfRanges == 3,
                  let nameRange = Range(match.range(at: 1), in: xmlString),
                  let valueRange = Range(match.range(at: 2), in: xmlString) else {
                continue
            }

            let name = String(xmlString[nameRange]).uppercased()
            let value = String(xmlString[valueRange])

            switch name {
            case "O":
                caConfig.organizationNames.append(value)
                print("[CSREnroll] Found O: \(value)")
            case "OU":
                caConfig.organizationalUnitNames.append(value)
                print("[CSREnroll] Found OU: \(value)")
            case "DC":
                caConfig.domainComponents.append(value)
                print("[CSREnroll] Found DC: \(value)")
            default:
                print("[CSREnroll] Ignoring nameEntry: \(name)=\(value)")
            }
        }

        return caConfig
    }

    // MARK: - CSR Submission

    private func submitCSR(
        csrBase64: String,
        config: CSREnrollmentConfiguration
    ) async throws -> EnrollmentResponse {
        guard let url = config.csrURL else {
            throw CSREnrollmentError.invalidServerURL
        }

        // TAKAware sends raw base64-encoded CSR as body (not JSON wrapped)
        // Content-Type: text/plain; charset=utf-8
        guard let bodyData = csrBase64.data(using: .utf8) else {
            throw CSREnrollmentError.invalidResponse("Failed to encode CSR as UTF-8")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(generateAuthHeader(config: config), forHTTPHeaderField: "Authorization")
        request.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        print("[CSREnroll] Submitting CSR to \(url.absoluteString)")

        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CSREnrollmentError.invalidResponse("Not an HTTP response")
            }

            print("[CSREnroll] CSR submission response status: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    throw CSREnrollmentError.authenticationFailed
                }
                let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw CSREnrollmentError.serverError(httpResponse.statusCode, errorMsg)
            }

            // Parse response
            return try parseEnrollmentResponse(data: data)

        } catch let error as CSREnrollmentError {
            throw error
        } catch {
            throw CSREnrollmentError.networkError(error)
        }
    }

    // MARK: - Response Parsing

    private func parseEnrollmentResponse(data: Data) throws -> EnrollmentResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            let responseStr = String(data: data, encoding: .utf8) ?? "Unable to decode"
            throw CSREnrollmentError.invalidResponse("Invalid JSON response: \(responseStr)")
        }

        print("[CSREnroll] Parsing enrollment response...")

        // Extract signed certificate
        guard let signedCertPEM = json["signedCert"] else {
            throw CSREnrollmentError.invalidResponse("Missing 'signedCert' in response")
        }

        let signedCertDER = try pemToDER(signedCertPEM)
        print("[CSREnroll] Signed certificate parsed (\(signedCertDER.count) bytes)")

        // Extract CA trust chain (entries prefixed with "ca")
        var trustChain: [Data] = []
        let caEntries = json.filter { $0.key.starts(with: "ca") }.sorted { $0.key < $1.key }

        for (key, caPEM) in caEntries {
            do {
                let caDER = try pemToDER(caPEM)
                trustChain.append(caDER)
                print("[CSREnroll] CA certificate '\(key)' parsed (\(caDER.count) bytes)")
            } catch {
                print("[CSREnroll] Warning: Failed to parse CA cert '\(key)': \(error)")
            }
        }

        print("[CSREnroll] Parsed \(trustChain.count) CA certificates")

        // Create temporary key tag (will be replaced by actual private key tag)
        let privateKeyTag = "temp"

        return EnrollmentResponse(
            signedCertificate: signedCertDER,
            trustChain: trustChain,
            privateKeyTag: privateKeyTag
        )
    }

    // MARK: - Certificate Storage

    private func storeCertificateIdentity(
        response: EnrollmentResponse,
        privateKeyTag: String,
        serverHost: String
    ) throws -> String {
        // Retrieve the private key we generated earlier (verify it exists)
        guard csrGenerator.retrievePrivateKey(tag: privateKeyTag) != nil else {
            throw CSREnrollmentError.certificateStorageFailed("Failed to retrieve private key from keychain")
        }

        // Create SecCertificate from DER data
        guard let certificate = SecCertificateCreateWithData(nil, response.signedCertificate as CFData) else {
            throw CSREnrollmentError.certificateStorageFailed("Failed to create certificate from DER data")
        }

        // Create identity by associating certificate with private key
        let certificateAlias = "omnitak-cert-\(serverHost)"

        // Store certificate in keychain
        let certQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: certificate,
            kSecAttrLabel as String: certificateAlias,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        // Delete existing if present
        SecItemDelete(certQuery as CFDictionary)

        let certStatus = SecItemAdd(certQuery as CFDictionary, nil)
        guard certStatus == errSecSuccess || certStatus == errSecDuplicateItem else {
            throw CSREnrollmentError.certificateStorageFailed("Failed to store certificate: \(certStatus)")
        }

        print("[CSREnroll] Stored certificate with alias: \(certificateAlias)")

        // Store CA trust chain
        for (index, caData) in response.trustChain.enumerated() {
            if let caCert = SecCertificateCreateWithData(nil, caData as CFData) {
                let caQuery: [String: Any] = [
                    kSecClass as String: kSecClassCertificate,
                    kSecValueRef as String: caCert,
                    kSecAttrLabel as String: "\(certificateAlias)-ca-\(index)",
                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                ]

                SecItemDelete(caQuery as CFDictionary)
                let caStatus = SecItemAdd(caQuery as CFDictionary, nil)

                if caStatus == errSecSuccess || caStatus == errSecDuplicateItem {
                    print("[CSREnroll] Stored CA certificate \(index)")
                } else {
                    print("[CSREnroll] Warning: Failed to store CA cert \(index): \(caStatus)")
                }
            }
        }

        return certificateAlias
    }

    // MARK: - Helper Methods

    private func generateAuthHeader(config: CSREnrollmentConfiguration) -> String {
        let credentials = "\(config.username):\(config.password)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        return "Basic \(base64Credentials)"
    }

    private func pemToDER(_ pem: String) throws -> Data {
        // Remove PEM headers/footers and whitespace
        var lines = pem.components(separatedBy: .newlines)
        lines = lines.filter { line in
            !line.contains("-----BEGIN") &&
            !line.contains("-----END") &&
            !line.trimmingCharacters(in: .whitespaces).isEmpty
        }

        let base64String = lines.joined()

        guard let derData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
            throw CSREnrollmentError.invalidResponse("Failed to decode PEM certificate")
        }

        return derData
    }
}

// MARK: - Self-Signed Certificate Delegate

/// URLSession delegate for CSR enrollment that accepts self-signed certificates
private class CSRSelfSignedCertificateDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Accept self-signed certificates for HTTPS (common in TAK deployments)
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }

        completionHandler(.performDefaultHandling, nil)
    }
}

// MARK: - Convenience Methods

extension CSREnrollmentService {

    /// Quick enrollment with common defaults
    func enroll(
        server: String,
        port: Int = 8089,
        enrollmentPort: Int = 8446,
        username: String,
        password: String
    ) async throws -> TAKServer {
        let config = CSREnrollmentConfiguration(
            serverHost: server,
            serverPort: port,
            enrollmentPort: enrollmentPort,
            username: username,
            password: password,
            useSSL: true
        )

        return try await enrollWithCSR(config: config)
    }
}
