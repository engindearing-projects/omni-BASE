//
//  OmniTAKNativeBridge.swift
//  OmniTAK Mobile - iOS Native Bridge
//
//  Swift wrapper around omnitak-mobile C FFI for Valdi polyglot integration
//

import Foundation

// MARK: - C FFI Import

// Import the C functions from the XCFramework
// Note: These declarations match omnitak_mobile.h
@_silgen_name("omnitak_init")
private func omnitak_init() -> Int32

@_silgen_name("omnitak_shutdown")
private func omnitak_shutdown()

@_silgen_name("omnitak_connect")
private func omnitak_connect(
    _ host: UnsafePointer<CChar>,
    _ port: UInt16,
    _ protocol: Int32,
    _ use_tls: Int32,
    _ cert_pem: UnsafePointer<CChar>?,
    _ key_pem: UnsafePointer<CChar>?,
    _ ca_pem: UnsafePointer<CChar>?
) -> UInt64

@_silgen_name("omnitak_disconnect")
private func omnitak_disconnect(_ connection_id: UInt64) -> Int32

@_silgen_name("omnitak_send_cot")
private func omnitak_send_cot(_ connection_id: UInt64, _ cot_xml: UnsafePointer<CChar>) -> Int32

@_silgen_name("omnitak_register_callback")
private func omnitak_register_callback(
    _ connection_id: UInt64,
    _ callback: @escaping @convention(c) (UnsafeMutableRawPointer?, UInt64, UnsafePointer<CChar>) -> Void,
    _ user_data: UnsafeMutableRawPointer?
) -> Int32

@_silgen_name("omnitak_unregister_callback")
private func omnitak_unregister_callback(_ connection_id: UInt64) -> Int32

@_silgen_name("omnitak_get_status")
private func omnitak_get_status(_ connection_id: UInt64, _ status_out: UnsafeMutablePointer<ConnectionStatus>) -> Int32

@_silgen_name("omnitak_version")
private func omnitak_version() -> UnsafePointer<CChar>

// MARK: - Enrollment FFI

@_silgen_name("omnitak_enrollment_init")
private func omnitak_enrollment_init() -> Int32

@_silgen_name("omnitak_enroll")
private func omnitak_enroll(
    _ server_url: UnsafePointer<CChar>,
    _ username: UnsafePointer<CChar>,
    _ password: UnsafePointer<CChar>,
    _ validity_days: UInt32
) -> Int32

@_silgen_name("omnitak_enrollment_get_result")
private func omnitak_enrollment_get_result(
    _ cert_pem_out: UnsafeMutablePointer<CChar>?,
    _ cert_pem_len: Int,
    _ key_pem_out: UnsafeMutablePointer<CChar>?,
    _ key_pem_len: Int,
    _ ca_pem_out: UnsafeMutablePointer<CChar>?,
    _ ca_pem_len: Int,
    _ server_host_out: UnsafeMutablePointer<CChar>?,
    _ server_host_len: Int,
    _ server_port_out: UnsafeMutablePointer<UInt16>?
) -> Int32

@_silgen_name("omnitak_enrollment_clear_result")
private func omnitak_enrollment_clear_result()

// MARK: - C Structs

private struct ConnectionStatus {
    var is_connected: Int32
    var messages_sent: UInt64
    var messages_received: UInt64
    var last_error_code: Int32
}

// MARK: - Protocol Constants

private enum OmniTAKProtocol: Int32 {
    case tcp = 0
    case udp = 1
    case tls = 2
    case websocket = 3
}

// MARK: - Swift Bridge Types

public struct ServerConfig: Codable {
    public let host: String
    public let port: Int
    public let `protocol`: String  // Escaped keyword with backticks
    public let useTls: Bool
    public let certificateId: String?
    public let reconnect: Bool
    public let reconnectDelayMs: Int

    enum CodingKeys: String, CodingKey {
        case host, port
        case `protocol` = "protocol"  // Escaped keyword with backticks
        case useTls, certificateId, reconnect, reconnectDelayMs
    }
}

public struct ConnectionInfo: Codable {
    public let id: Int
    public let status: String
    public let host: String
    public let port: Int
    public let protocolType: String
    public let latencyMs: Int
    public let messagesReceived: Int
    public let messagesSent: Int
    public let lastError: String?

    enum CodingKeys: String, CodingKey {
        case id, status, host, port
        case protocolType = "protocol"
        case latencyMs, messagesReceived, messagesSent, lastError
    }
}

// MARK: - Certificate Storage

private struct CertificateBundle {
    let certPem: String
    let keyPem: String
    let caPem: String?
}

// MARK: - Native Bridge Class

@objc(OmniTAKNativeBridge)
public class OmniTAKNativeBridge: NSObject {

    // Singleton instance for callback management
    private static var shared: OmniTAKNativeBridge?

    // Certificate storage
    private var certificates: [String: CertificateBundle] = [:]

    // Callback storage: connection_id -> callback closure
    private var callbacks: [UInt64: (String) -> Void] = [:]

    // Thread-safe access to callbacks
    private let callbackQueue = DispatchQueue(label: "com.engindearing.omnitak.callbacks")

    // Initialization state
    private var isInitialized = false
    private let initLock = NSLock()

    public override init() {
        super.init()
        Self.shared = self
        ensureInitialized()
    }

    deinit {
        omnitak_shutdown()
    }

    // MARK: - Initialization

    private func ensureInitialized() {
        initLock.lock()
        defer { initLock.unlock() }

        if !isInitialized {
            let result = omnitak_init()
            if result == 0 {
                isInitialized = true
                print("[OmniTAK] Native library initialized successfully")
            } else {
                print("[OmniTAK] Failed to initialize native library: \(result)")
            }
        }
    }

    // MARK: - Public API

    @objc public func getVersion() -> String {
        let versionPtr = omnitak_version()
        return String(cString: versionPtr)
    }

    @objc public func connect(config: [String: Any], completion: @escaping (NSNumber?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }

            self.ensureInitialized()

            // Parse configuration
            guard let host = config["host"] as? String,
                  let port = config["port"] as? Int,
                  let protocolStr = config["protocol"] as? String,
                  let useTls = config["useTls"] as? Bool else {
                print("[OmniTAK] Invalid connection configuration")
                completion(nil)
                return
            }

            // Convert protocol string to enum
            let protocolType: OmniTAKProtocol
            switch protocolStr.lowercased() {
            case "tcp": protocolType = .tcp
            case "udp": protocolType = .udp
            case "tls": protocolType = .tls
            case "websocket": protocolType = .websocket
            default:
                print("[OmniTAK] Unknown protocol: \(protocolStr)")
                completion(nil)
                return
            }

            // Get certificates if provided
            var certPem: UnsafePointer<CChar>? = nil
            var keyPem: UnsafePointer<CChar>? = nil
            var caPem: UnsafePointer<CChar>? = nil

            if let certId = config["certificateId"] as? String,
               let bundle = self.certificates[certId] {
                certPem = bundle.certPem.withCString { $0 }
                keyPem = bundle.keyPem.withCString { $0 }
                if let ca = bundle.caPem {
                    caPem = ca.withCString { $0 }
                }
            }

            // Call C FFI
            let connectionId = host.withCString { hostPtr in
                omnitak_connect(
                    hostPtr,
                    UInt16(port),
                    protocolType.rawValue,
                    useTls ? 1 : 0,
                    certPem,
                    keyPem,
                    caPem
                )
            }

            if connectionId > 0 {
                print("[OmniTAK] Connected successfully: \(connectionId)")
                completion(NSNumber(value: connectionId))
            } else {
                print("[OmniTAK] Connection failed")
                completion(nil)
            }
        }
    }

    @objc public func disconnect(connectionId: Int, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion()
                return
            }

            let result = omnitak_disconnect(UInt64(connectionId))

            // Clean up callback
            self.callbackQueue.sync {
                self.callbacks.removeValue(forKey: UInt64(connectionId))
            }

            if result == 0 {
                print("[OmniTAK] Disconnected: \(connectionId)")
            } else {
                print("[OmniTAK] Disconnect failed: \(connectionId)")
            }

            completion()
        }
    }

    @objc public func sendCot(connectionId: Int, cotXml: String, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = cotXml.withCString { xmlPtr in
                omnitak_send_cot(UInt64(connectionId), xmlPtr)
            }

            let success = (result == 0)
            if success {
                print("[OmniTAK] CoT sent on connection \(connectionId)")
            } else {
                print("[OmniTAK] Failed to send CoT on connection \(connectionId)")
            }

            completion(success)
        }
    }

    @objc public func registerCotCallback(connectionId: Int, callback: @escaping (String) -> Void) {
        callbackQueue.sync {
            callbacks[UInt64(connectionId)] = callback
        }

        // Create C callback that bridges to Swift
        let cCallback: @convention(c) (UnsafeMutableRawPointer?, UInt64, UnsafePointer<CChar>) -> Void = { userDataPtr, connId, xmlPtr in
            // This runs on the Rust background thread
            guard let bridge = OmniTAKNativeBridge.shared else { return }

            let xml = String(cString: xmlPtr)

            // Dispatch to main queue for safety
            DispatchQueue.main.async {
                bridge.callbackQueue.sync {
                    if let swiftCallback = bridge.callbacks[connId] {
                        swiftCallback(xml)
                    }
                }
            }
        }

        // Register with C layer (pass self as user_data)
        let userDataPtr = Unmanaged.passUnretained(self).toOpaque()
        let result = omnitak_register_callback(UInt64(connectionId), cCallback, userDataPtr)

        if result == 0 {
            print("[OmniTAK] Callback registered for connection \(connectionId)")
        } else {
            print("[OmniTAK] Failed to register callback for connection \(connectionId)")
        }
    }

    @objc public func getConnectionStatus(connectionId: Int, completion: @escaping ([String: Any]?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var status = ConnectionStatus(
                is_connected: 0,
                messages_sent: 0,
                messages_received: 0,
                last_error_code: 0
            )

            let result = omnitak_get_status(UInt64(connectionId), &status)

            if result == 0 {
                let statusDict: [String: Any] = [
                    "id": connectionId,
                    "status": status.is_connected != 0 ? "connected" : "disconnected",
                    "messagesSent": status.messages_sent,
                    "messagesReceived": status.messages_received,
                    "lastErrorCode": status.last_error_code
                ]
                completion(statusDict)
            } else {
                print("[OmniTAK] Failed to get status for connection \(connectionId)")
                completion(nil)
            }
        }
    }

    @objc public func importCertificate(certPem: String, keyPem: String, caPem: String?, completion: @escaping (String?) -> Void) {
        // Generate a unique ID for this certificate bundle
        let certId = UUID().uuidString

        let bundle = CertificateBundle(
            certPem: certPem,
            keyPem: keyPem,
            caPem: caPem
        )

        certificates[certId] = bundle

        print("[OmniTAK] Certificate imported: \(certId)")
        completion(certId)
    }

    // MARK: - Certificate Enrollment

    /// Enroll with a TAK server to obtain a client certificate
    ///
    /// - Parameters:
    ///   - serverUrl: TAK server URL (e.g., "https://tak-server.example.com:8443")
    ///   - username: Username for authentication
    ///   - password: Password for authentication
    ///   - validityDays: Certificate validity period in days (default: 365)
    ///   - completion: Completion handler with certificate ID on success, nil on failure
    @objc public func enrollCertificate(
        serverUrl: String,
        username: String,
        password: String,
        validityDays: Int = 365,
        completion: @escaping (String?, String?) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Initialize enrollment client
            let initResult = omnitak_enrollment_init()
            if initResult != 0 {
                print("[OmniTAK] Failed to initialize enrollment client")
                completion(nil, "Failed to initialize enrollment client")
                return
            }

            // Start enrollment
            let enrollResult = serverUrl.withCString { serverUrlPtr in
                username.withCString { usernamePtr in
                    password.withCString { passwordPtr in
                        omnitak_enroll(serverUrlPtr, usernamePtr, passwordPtr, UInt32(validityDays))
                    }
                }
            }

            if enrollResult != 0 {
                print("[OmniTAK] Failed to start enrollment")
                completion(nil, "Failed to start enrollment")
                return
            }

            // Poll for result (wait up to 30 seconds)
            var attempts = 0
            var success = false

            while attempts < 60 {
                Thread.sleep(forTimeInterval: 0.5)

                let bufferSize = 8192
                let certBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize)
                let keyBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize)
                let caBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize)
                let hostBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: 256)
                var port: UInt16 = 0

                defer {
                    certBuffer.deallocate()
                    keyBuffer.deallocate()
                    caBuffer.deallocate()
                    hostBuffer.deallocate()
                }

                let result = omnitak_enrollment_get_result(
                    certBuffer, bufferSize,
                    keyBuffer, bufferSize,
                    caBuffer, bufferSize,
                    hostBuffer, 256,
                    &port
                )

                if result == 1 {
                    // Success! Convert to Swift strings
                    let certPem = String(cString: certBuffer)
                    let keyPem = String(cString: keyBuffer)
                    let caPem = String(cString: caBuffer)
                    let serverHost = String(cString: hostBuffer)

                    // Clear result
                    omnitak_enrollment_clear_result()

                    // Import the certificate
                    let certId = UUID().uuidString
                    let bundle = CertificateBundle(
                        certPem: certPem,
                        keyPem: keyPem,
                        caPem: caPem.isEmpty ? nil : caPem
                    )

                    self.certificates[certId] = bundle

                    print("[OmniTAK] Enrollment successful: \(certId), server: \(serverHost):\(port)")
                    success = true
                    completion(certId, nil)
                    break
                } else if result == -1 {
                    // Failed
                    omnitak_enrollment_clear_result()
                    print("[OmniTAK] Enrollment failed")
                    completion(nil, "Enrollment failed - check credentials")
                    break
                }

                attempts += 1
            }

            if !success && attempts >= 60 {
                completion(nil, "Enrollment timed out")
            }
        }
    }
}

// MARK: - Valdi Integration Helper

extension OmniTAKNativeBridge {

    /// Convert dictionary to ServerConfig for type safety
    public static func parseServerConfig(from dict: [String: Any]) -> ServerConfig? {
        guard let host = dict["host"] as? String,
              let port = dict["port"] as? Int,
              let protocolStr = dict["protocol"] as? String,
              let useTls = dict["useTls"] as? Bool,
              let reconnect = dict["reconnect"] as? Bool,
              let reconnectDelayMs = dict["reconnectDelayMs"] as? Int else {
            return nil
        }

        return ServerConfig(
            host: host,
            port: port,
            `protocol`: protocolStr,
            useTls: useTls,
            certificateId: dict["certificateId"] as? String,
            reconnect: reconnect,
            reconnectDelayMs: reconnectDelayMs
        )
    }
}
