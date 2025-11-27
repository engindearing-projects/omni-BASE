//
//  DeepLinkHandler.swift
//  OmniTAKMobile
//
//  Handles TAK deep links for enrollment (QR code scanning / ATAK links)
//  URL format: tak://com.atakmap.app/enroll?host=server.io&username=user&token=JWT
//

import Foundation
import Combine

// MARK: - Deep Link Types

enum TAKDeepLink {
    case enrollment(EnrollmentDeepLink)
    case connect(ConnectDeepLink)
    case unknown(URL)

    static func parse(url: URL) -> TAKDeepLink? {
        guard url.scheme?.lowercased() == "tak" else { return nil }

        let path = url.path.lowercased()
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let hasToken = queryItems.contains { $0.name.lowercased() == "token" && $0.value != nil }

        // If path contains "enroll" AND has a token, it's enrollment
        if path.contains("enroll") && hasToken {
            if let enrollment = EnrollmentDeepLink.parse(url: url) {
                return .enrollment(enrollment)
            }
        }

        // Otherwise try simple connect (host + optional port/protocol)
        if let connect = ConnectDeepLink.parse(url: url) {
            return .connect(connect)
        }

        return .unknown(url)
    }
}

// MARK: - Simple Connect Deep Link (TCP/UDP without auth)

struct ConnectDeepLink {
    let host: String
    let port: Int
    let protocolType: String  // tcp, udp, ssl
    let name: String?

    static func parse(url: URL) -> ConnectDeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        var params: [String: String] = [:]

        for item in queryItems {
            if let value = item.value {
                params[item.name.lowercased()] = value
            }
        }

        // Host is required
        guard let host = params["host"] else {
            print("[DeepLink] Connect: Missing required 'host' parameter")
            return nil
        }

        // Port defaults to 8087 for TCP (common TAK default)
        let port = params["port"].flatMap { Int($0) } ?? 8087

        // Protocol defaults to TCP
        let protocolType = params["protocol"]?.lowercased() ?? "tcp"

        // Optional friendly name
        let name = params["name"]

        return ConnectDeepLink(
            host: host,
            port: port,
            protocolType: protocolType,
            name: name
        )
    }
}

// MARK: - Enrollment Deep Link

struct EnrollmentDeepLink {
    let host: String
    let username: String
    let token: String
    let port: Int?
    let enrollmentPort: Int?

    static func parse(url: URL) -> EnrollmentDeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        var params: [String: String] = [:]

        for item in queryItems {
            if let value = item.value {
                params[item.name.lowercased()] = value
            }
        }

        // Required parameters
        guard let host = params["host"],
              let username = params["username"],
              let token = params["token"] else {
            print("[DeepLink] Missing required parameters: host, username, or token")
            return nil
        }

        // Optional parameters
        let port = params["port"].flatMap { Int($0) }
        let enrollmentPort = params["enrollmentport"].flatMap { Int($0) }

        return EnrollmentDeepLink(
            host: host,
            username: username,
            token: token,
            port: port,
            enrollmentPort: enrollmentPort
        )
    }
}

// MARK: - Deep Link Handler

class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()

    @Published var isProcessing = false
    @Published var lastError: String?
    @Published var showEnrollmentSuccess = false
    @Published var enrolledServerName: String?

    private let csrEnrollmentService = CSREnrollmentService()
    private let urlSession: URLSession

    init() {
        // Configure URLSession to accept self-signed certificates
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60

        self.urlSession = URLSession(
            configuration: configuration,
            delegate: SelfSignedCertDelegate(),
            delegateQueue: nil
        )
    }

    // MARK: - Handle Incoming URL

    func handleURL(_ url: URL) {
        print("[DeepLink] Received URL: \(url.absoluteString)")

        guard let deepLink = TAKDeepLink.parse(url: url) else {
            print("[DeepLink] Could not parse URL")
            lastError = "Invalid TAK URL"
            return
        }

        switch deepLink {
        case .enrollment(let enrollmentLink):
            Task {
                await processEnrollment(enrollmentLink)
            }
        case .connect(let connectLink):
            processSimpleConnect(connectLink)
        case .unknown(let unknownURL):
            print("[DeepLink] Unknown deep link type: \(unknownURL)")
            lastError = "Unknown link type"
        }
    }

    // MARK: - Simple TCP/UDP Connect (No Auth)

    private func processSimpleConnect(_ connect: ConnectDeepLink) {
        print("[DeepLink] Simple connect: \(connect.host):\(connect.port) via \(connect.protocolType)")

        isProcessing = true
        lastError = nil

        // Create server config
        let serverName = connect.name ?? "\(connect.host):\(connect.port)"
        let useTLS = connect.protocolType == "ssl" || connect.protocolType == "tls"

        let server = TAKServer(
            id: UUID(),
            name: serverName,
            host: connect.host,
            port: UInt16(connect.port),
            protocolType: connect.protocolType,
            useTLS: useTLS,
            isDefault: false,
            enabled: true,
            certificateName: nil,  // No cert for simple TCP
            certificatePassword: nil
        )

        // Add and connect
        ServerManager.shared.addServer(server)
        ServerManager.shared.setActiveServer(server)

        // Connect immediately
        TAKService.shared.connect(
            host: server.host,
            port: server.port,
            protocolType: server.protocolType,
            useTLS: server.useTLS,
            certificateName: nil,
            certificatePassword: nil
        )

        isProcessing = false
        enrolledServerName = serverName
        showEnrollmentSuccess = true

        print("[DeepLink] ✅ Connected to \(serverName) via \(connect.protocolType.uppercased())")
    }

    // MARK: - Token-Based Enrollment (OpenTAKServer)

    private func processEnrollment(_ enrollment: EnrollmentDeepLink) async {
        await MainActor.run {
            isProcessing = true
            lastError = nil
        }

        print("[DeepLink] Starting token-based enrollment for \(enrollment.username)@\(enrollment.host)")

        do {
            // OpenTAKServer token enrollment flow:
            // 1. Use JWT token to authenticate
            // 2. Generate CSR and submit to server
            // 3. Get signed certificate

            let server = try await enrollWithToken(enrollment)

            await MainActor.run {
                isProcessing = false
                enrolledServerName = server.name
                showEnrollmentSuccess = true
                print("[DeepLink] ✅ Enrollment successful: \(server.name)")
            }

        } catch {
            await MainActor.run {
                isProcessing = false
                lastError = error.localizedDescription
                print("[DeepLink] ❌ Enrollment failed: \(error)")
            }
        }
    }

    private func enrollWithToken(_ enrollment: EnrollmentDeepLink) async throws -> TAKServer {
        let host = enrollment.host
        let enrollmentPort = enrollment.enrollmentPort ?? 8446
        let streamingPort = enrollment.port ?? 8089

        // Determine protocol based on port (common TAK conventions)
        // 8089 = SSL/TLS streaming, 8088 = TCP streaming
        let useSSL = streamingPort != 8088

        // Build URLs
        let baseURL = "https://\(host):\(enrollmentPort)"
        let configURL = URL(string: "\(baseURL)/Marti/api/tls/config")!

        // Create Bearer token auth header
        let authHeader = "Bearer \(enrollment.token)"

        print("[DeepLink] Fetching CA config from \(configURL)")

        // Step 1: Get CA configuration
        var configRequest = URLRequest(url: configURL)
        configRequest.httpMethod = "GET"
        configRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        configRequest.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let (configData, configResponse) = try await urlSession.data(for: configRequest)

        guard let httpConfigResponse = configResponse as? HTTPURLResponse else {
            throw DeepLinkError.invalidResponse("Not an HTTP response")
        }

        print("[DeepLink] Config response: \(httpConfigResponse.statusCode)")

        guard (200...299).contains(httpConfigResponse.statusCode) else {
            if httpConfigResponse.statusCode == 401 {
                throw DeepLinkError.authenticationFailed("Token expired or invalid")
            }
            let errorBody = String(data: configData, encoding: .utf8) ?? ""
            throw DeepLinkError.serverError(httpConfigResponse.statusCode, errorBody)
        }

        // Parse CA configuration
        let caConfig = parseCAConfigXML(data: configData)
        print("[DeepLink] CA config: O=\(caConfig.organizationNames), OU=\(caConfig.organizationalUnitNames)")

        // Step 2: Generate CSR
        let certificateAlias = "omnitak-\(host)"
        let csrGenerator = CSRGenerator()

        print("[DeepLink] Generating CSR with alias: \(certificateAlias)")

        let csrResult = try csrGenerator.generateCSR(
            username: enrollment.username,
            caConfig: caConfig,
            keyTag: certificateAlias
        )

        // Step 3: Submit CSR with token authentication
        let clientUid = UUID().uuidString
        let clientVersion = "OmniTAK-1.0"
        let escapedUid = clientUid.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? clientUid
        let escapedVersion = clientVersion.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? clientVersion

        guard let csrSubmitURL = URL(string: "\(baseURL)/Marti/api/tls/signClient/v2?clientUid=\(escapedUid)&version=\(escapedVersion)") else {
            throw DeepLinkError.invalidURL("Invalid CSR submission URL")
        }

        print("[DeepLink] Submitting CSR to \(csrSubmitURL)")

        var csrRequest = URLRequest(url: csrSubmitURL)
        csrRequest.httpMethod = "POST"
        csrRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        csrRequest.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
        csrRequest.httpBody = csrResult.csrBase64.data(using: .utf8)

        var csrData: Data
        var csrResponse: URLResponse

        do {
            (csrData, csrResponse) = try await urlSession.data(for: csrRequest)

            // If Bearer auth failed, try alternative methods
            if let httpResp = csrResponse as? HTTPURLResponse, httpResp.statusCode == 401 {
                print("[DeepLink] Bearer auth failed (401), trying alternatives...")

                // Try 1: Basic auth with token as password
                print("[DeepLink] Trying Basic auth with token as password")
                let basicCredentials = "\(enrollment.username):\(enrollment.token)"
                let basicAuth = "Basic \(Data(basicCredentials.utf8).base64EncodedString())"

                var basicRequest = URLRequest(url: csrSubmitURL)
                basicRequest.httpMethod = "POST"
                basicRequest.setValue(basicAuth, forHTTPHeaderField: "Authorization")
                basicRequest.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
                basicRequest.httpBody = csrResult.csrBase64.data(using: .utf8)

                (csrData, csrResponse) = try await urlSession.data(for: basicRequest)

                // Try 2: Token as query param if still 401
                if let httpResp2 = csrResponse as? HTTPURLResponse, httpResp2.statusCode == 401 {
                    print("[DeepLink] Basic auth also failed, trying token as query param")
                    let tokenParam = enrollment.token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? enrollment.token
                    guard let tokenURL = URL(string: "\(baseURL)/Marti/api/tls/signClient/v2?clientUid=\(escapedUid)&version=\(escapedVersion)&token=\(tokenParam)") else {
                        throw DeepLinkError.invalidURL("Invalid token URL")
                    }

                    var tokenRequest = URLRequest(url: tokenURL)
                    tokenRequest.httpMethod = "POST"
                    tokenRequest.setValue("text/plain; charset=utf-8", forHTTPHeaderField: "Content-Type")
                    tokenRequest.httpBody = csrResult.csrBase64.data(using: .utf8)

                    (csrData, csrResponse) = try await urlSession.data(for: tokenRequest)
                }
            }
        } catch {
            throw DeepLinkError.invalidResponse("Network error: \(error)")
        }

        guard let httpCSRResponse = csrResponse as? HTTPURLResponse else {
            throw DeepLinkError.invalidResponse("Not an HTTP response")
        }

        print("[DeepLink] CSR response: \(httpCSRResponse.statusCode)")

        guard (200...299).contains(httpCSRResponse.statusCode) else {
            if httpCSRResponse.statusCode == 401 {
                throw DeepLinkError.authenticationFailed("Token expired or invalid")
            }
            let errorBody = String(data: csrData, encoding: .utf8) ?? ""
            throw DeepLinkError.serverError(httpCSRResponse.statusCode, errorBody)
        }

        // Step 4: Parse enrollment response
        let enrollmentResponse = try parseEnrollmentResponse(data: csrData)
        print("[DeepLink] Received signed certificate")

        // Step 5: Store certificate
        try storeCertificateIdentity(
            response: enrollmentResponse,
            privateKeyTag: csrResult.privateKeyTag,
            certificateAlias: certificateAlias
        )
        print("[DeepLink] Certificate stored successfully")

        // Step 6: Create and save server configuration
        let serverInstance = TAKServer(
            id: UUID(),
            name: "\(host) (\(enrollment.username))",
            host: host,
            port: UInt16(streamingPort),
            protocolType: useSSL ? "ssl" : "tcp",
            useTLS: useSSL,
            isDefault: false,
            enabled: true,
            certificateName: certificateAlias,
            certificatePassword: "omnitak",
            username: enrollment.username
        )

        // Add to server manager on main thread
        await MainActor.run {
            ServerManager.shared.addServer(serverInstance)
            ServerManager.shared.setActiveServer(serverInstance)

            // Auto-connect to the server
            TAKService.shared.connect(
                host: serverInstance.host,
                port: serverInstance.port,
                protocolType: serverInstance.protocolType,
                useTLS: serverInstance.useTLS,
                certificateName: serverInstance.certificateName,
                certificatePassword: serverInstance.certificatePassword
            )
        }

        return serverInstance
    }

    // MARK: - XML Parsing

    private func parseCAConfigXML(data: Data) -> CAConfiguration {
        var caConfig = CAConfiguration()

        guard let xmlString = String(data: data, encoding: .utf8) else {
            return caConfig
        }

        let pattern = #"<nameEntry\s+name="([^"]+)"\s+value="([^"]+)"/?"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
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
            case "O": caConfig.organizationNames.append(value)
            case "OU": caConfig.organizationalUnitNames.append(value)
            case "DC": caConfig.domainComponents.append(value)
            default: break
            }
        }

        return caConfig
    }

    // MARK: - Response Parsing

    private func parseEnrollmentResponse(data: Data) throws -> EnrollmentResponse {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            let responseStr = String(data: data, encoding: .utf8) ?? "Unable to decode"
            throw DeepLinkError.invalidResponse("Invalid JSON: \(responseStr)")
        }

        guard let signedCertPEM = json["signedCert"] else {
            throw DeepLinkError.invalidResponse("Missing signedCert")
        }

        let signedCertDER = try pemToDER(signedCertPEM)

        var trustChain: [Data] = []
        let caEntries = json.filter { $0.key.starts(with: "ca") }.sorted { $0.key < $1.key }

        for (_, caPEM) in caEntries {
            if let caDER = try? pemToDER(caPEM) {
                trustChain.append(caDER)
            }
        }

        return EnrollmentResponse(
            signedCertificate: signedCertDER,
            trustChain: trustChain,
            privateKeyTag: "temp"
        )
    }

    private func pemToDER(_ pem: String) throws -> Data {
        var lines = pem.components(separatedBy: .newlines)
        lines = lines.filter { line in
            !line.contains("-----BEGIN") &&
            !line.contains("-----END") &&
            !line.trimmingCharacters(in: .whitespaces).isEmpty
        }

        let base64String = lines.joined()

        guard let derData = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
            throw DeepLinkError.invalidResponse("Failed to decode PEM")
        }

        return derData
    }

    // MARK: - Certificate Storage

    private func storeCertificateIdentity(
        response: EnrollmentResponse,
        privateKeyTag: String,
        certificateAlias: String
    ) throws {
        guard let certificate = SecCertificateCreateWithData(nil, response.signedCertificate as CFData) else {
            throw DeepLinkError.certificateStorageFailed("Failed to create certificate")
        }

        // Clear existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: certificateAlias
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add certificate
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrLabel as String: certificateAlias,
            kSecValueRef as String: certificate,
            kSecReturnAttributes as String: true
        ]

        var resultRef: AnyObject?
        let status = SecItemAdd(addQuery as CFDictionary, &resultRef)

        guard status == errSecSuccess else {
            throw DeepLinkError.certificateStorageFailed("Failed to add certificate: \(status)")
        }

        // Store mapping for TAKService
        UserDefaults.standard.set(privateKeyTag, forKey: "csr_key_tag_\(certificateAlias)")
        UserDefaults.standard.set(response.signedCertificate, forKey: "csr_cert_data_\(certificateAlias)")

        // Store CA chain
        for (index, caData) in response.trustChain.enumerated() {
            if let caCert = SecCertificateCreateWithData(nil, caData as CFData) {
                let caQuery: [String: Any] = [
                    kSecClass as String: kSecClassCertificate,
                    kSecValueRef as String: caCert,
                    kSecAttrLabel as String: "\(certificateAlias)-ca-\(index)",
                    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                ]
                SecItemDelete(caQuery as CFDictionary)
                SecItemAdd(caQuery as CFDictionary, nil)
            }
        }

        print("[DeepLink] ✅ Certificate identity stored")
    }
}

// MARK: - Deep Link Errors

enum DeepLinkError: LocalizedError {
    case invalidURL(String)
    case invalidResponse(String)
    case authenticationFailed(String)
    case serverError(Int, String)
    case certificateStorageFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let msg): return "Invalid URL: \(msg)"
        case .invalidResponse(let msg): return "Invalid response: \(msg)"
        case .authenticationFailed(let msg): return "Auth failed: \(msg)"
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        case .certificateStorageFailed(let msg): return "Certificate storage failed: \(msg)"
        }
    }
}

// MARK: - Self-Signed Certificate Delegate

private class SelfSignedCertDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }
        completionHandler(.performDefaultHandling, nil)
    }
}
