//
//  ServerDiscoveryService.swift
//  OmniTAKMobile
//
//  mDNS/Bonjour service discovery for TAK servers
//  Automatically discovers TAK servers on the local network
//

import Foundation
import Combine

// MARK: - Discovered TAK Server (via mDNS/Bonjour)

struct DiscoveredTAKServer: Identifiable, Equatable {
    let id: UUID
    let name: String
    let host: String
    let port: UInt16
    let txtRecords: [String: String]
    let discoveryDate: Date

    var protocolType: String {
        txtRecords["protocol"] ?? "tcp"
    }

    var useTLS: Bool {
        txtRecords["tls"]?.lowercased() == "true" || txtRecords["ssl"]?.lowercased() == "true"
    }

    var version: String? {
        txtRecords["version"]
    }

    var serverType: String? {
        txtRecords["type"]
    }

    var displayName: String {
        "\(name) (\(host):\(port))"
    }

    /// Convert to TAKServer model for connection
    func toTAKServer(certificateName: String? = nil, certificatePassword: String? = nil) -> TAKServer {
        return TAKServer(
            id: id,
            name: name,
            host: host,
            port: port,
            protocolType: protocolType,
            useTLS: useTLS,
            isDefault: false,
            certificateName: certificateName,
            certificatePassword: certificatePassword
        )
    }

    static func == (lhs: DiscoveredTAKServer, rhs: DiscoveredTAKServer) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Discovery State

enum DiscoveryState {
    case idle
    case discovering
    case stopped
    case error(String)

    var isDiscovering: Bool {
        if case .discovering = self {
            return true
        }
        return false
    }
}

// MARK: - Server Discovery Service

class ServerDiscoveryService: NSObject, ObservableObject {

    static let shared = ServerDiscoveryService()

    // MARK: - Published Properties

    @Published var discoveredServers: [DiscoveredTAKServer] = []
    @Published var discoveryState: DiscoveryState = .idle
    @Published var isDiscovering: Bool = false

    // MARK: - Private Properties

    private var serviceBrowser: NetServiceBrowser?
    private var resolvingServices: [NetService] = []
    private var resolvedServices: Set<String> = []  // Track by name to avoid duplicates

    // Configuration
    private let serviceType = "_tak._tcp."  // Standard TAK service type
    private let serviceDomain = ""  // Empty means local domain
    private let resolveTimeout: TimeInterval = 30.0

    // Timeout handling
    private var discoveryTimer: Timer?

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Discovery Control

    /// Start discovering TAK servers on the local network
    func startDiscovery() {
        guard !isDiscovering else {
            #if DEBUG
            print("🔍 Discovery already in progress")
            #endif
            return
        }

        #if DEBUG
        print("🔍 Starting TAK server discovery...")
        #endif

        // Clear previous results
        DispatchQueue.main.async {
            self.discoveredServers.removeAll()
            self.discoveryState = .discovering
            self.isDiscovering = true
        }

        resolvedServices.removeAll()
        resolvingServices.removeAll()

        // Create and configure browser
        serviceBrowser = NetServiceBrowser()
        serviceBrowser?.delegate = self
        serviceBrowser?.searchForServices(ofType: serviceType, inDomain: serviceDomain)

        // Set timeout for discovery
        setupDiscoveryTimeout()
    }

    /// Stop discovery
    func stopDiscovery() {
        guard isDiscovering else { return }

        #if DEBUG
        print("🔍 Stopping TAK server discovery")
        #endif

        serviceBrowser?.stop()
        serviceBrowser?.delegate = nil
        serviceBrowser = nil

        // Stop resolving any pending services
        for service in resolvingServices {
            service.stop()
            service.delegate = nil
        }
        resolvingServices.removeAll()

        // Cancel timeout
        discoveryTimer?.invalidate()
        discoveryTimer = nil

        DispatchQueue.main.async {
            self.discoveryState = .stopped
            self.isDiscovering = false
        }
    }

    /// Refresh discovery (restart)
    func refresh() {
        stopDiscovery()

        // Small delay before restarting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startDiscovery()
        }
    }

    // MARK: - Timeout Handling

    private func setupDiscoveryTimeout() {
        discoveryTimer?.invalidate()

        discoveryTimer = Timer.scheduledTimer(
            withTimeInterval: resolveTimeout,
            repeats: false
        ) { [weak self] _ in
            self?.handleDiscoveryTimeout()
        }
    }

    private func handleDiscoveryTimeout() {
        #if DEBUG
        print("🔍 Discovery timeout reached")
        #endif

        // Stop any pending resolutions
        for service in resolvingServices {
            service.stop()
            service.delegate = nil
        }
        resolvingServices.removeAll()

        DispatchQueue.main.async {
            if self.discoveredServers.isEmpty {
                self.discoveryState = .error("No TAK servers found on local network")
            } else {
                self.discoveryState = .stopped
            }
            self.isDiscovering = false
        }
    }

    // MARK: - Service Resolution

    private func resolveService(_ service: NetService) {
        // Check if already resolved
        guard !resolvedServices.contains(service.name) else {
            #if DEBUG
            print("🔍 Service already resolved: \(service.name)")
            #endif
            return
        }

        #if DEBUG
        print("🔍 Resolving service: \(service.name)")
        #endif

        service.delegate = self
        resolvingServices.append(service)

        // Resolve with timeout
        service.resolve(withTimeout: 10.0)
    }

    private func handleResolvedService(_ service: NetService) {
        guard let addresses = service.addresses, !addresses.isEmpty else {
            #if DEBUG
            print("⚠️ Service has no addresses: \(service.name)")
            #endif
            return
        }

        // Mark as resolved
        resolvedServices.insert(service.name)

        // Extract host and port
        guard let hostString = getHostString(from: addresses.first!),
              service.port >= 0 else {
            #if DEBUG
            print("⚠️ Failed to extract host/port from service: \(service.name)")
            #endif
            return
        }

        let port = UInt16(service.port)

        // Extract TXT records
        var txtRecords: [String: String] = [:]
        if let txtData = service.txtRecordData() {
            txtRecords = NetService.dictionary(fromTXTRecord: txtData)
                .reduce(into: [:]) { result, entry in
                    if let value = String(data: entry.value, encoding: .utf8) {
                        result[entry.key] = value
                    }
                }
        }

        // Create discovered server
        let discoveredServer = DiscoveredTAKServer(
            id: UUID(),
            name: service.name,
            host: hostString,
            port: port,
            txtRecords: txtRecords,
            discoveryDate: Date()
        )

        // Add to discovered servers
        DispatchQueue.main.async {
            // Check for duplicates by host:port
            if !self.discoveredServers.contains(where: { $0.host == hostString && $0.port == port }) {
                self.discoveredServers.append(discoveredServer)

                #if DEBUG
                print("✅ Discovered TAK server: \(discoveredServer.displayName)")
                print("   Protocol: \(discoveredServer.protocolType), TLS: \(discoveredServer.useTLS)")
                if let version = discoveredServer.version {
                    print("   Version: \(version)")
                }
                #endif
            }
        }

        // Remove from resolving list
        if let index = resolvingServices.firstIndex(of: service) {
            resolvingServices.remove(at: index)
        }
    }

    // MARK: - Helper Methods

    private func getHostString(from addressData: Data) -> String? {
        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

        addressData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
            guard let baseAddress = pointer.baseAddress else { return }

            let sockaddrPtr = baseAddress.assumingMemoryBound(to: sockaddr.self)

            getnameinfo(
                sockaddrPtr,
                socklen_t(addressData.count),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
        }

        return String(cString: hostname)
    }

    // MARK: - Manual Server Addition

    /// Manually add a server (not discovered via mDNS)
    func addManualServer(
        name: String,
        host: String,
        port: UInt16,
        protocolType: String = "tcp",
        useTLS: Bool = false
    ) {
        let txtRecords: [String: String] = [
            "protocol": protocolType,
            "tls": useTLS ? "true" : "false",
            "manual": "true"
        ]

        let server = DiscoveredTAKServer(
            id: UUID(),
            name: name,
            host: host,
            port: port,
            txtRecords: txtRecords,
            discoveryDate: Date()
        )

        DispatchQueue.main.async {
            if !self.discoveredServers.contains(where: { $0.host == host && $0.port == port }) {
                self.discoveredServers.append(server)
            }
        }
    }

    /// Remove a discovered server from the list
    func removeServer(_ server: DiscoveredTAKServer) {
        DispatchQueue.main.async {
            self.discoveredServers.removeAll { $0.id == server.id }
        }
    }

    /// Clear all discovered servers
    func clearDiscoveredServers() {
        DispatchQueue.main.async {
            self.discoveredServers.removeAll()
            self.resolvedServices.removeAll()
        }
    }
}

// MARK: - NetServiceBrowserDelegate

extension ServerDiscoveryService: NetServiceBrowserDelegate {

    func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        #if DEBUG
        print("🔍 NetServiceBrowser will search for TAK servers")
        #endif
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        #if DEBUG
        print("🔍 Found service: \(service.name) (more coming: \(moreComing))")
        #endif

        // Resolve the service
        resolveService(service)

        // If no more services are coming, we can consider discovery complete after a delay
        if !moreComing {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                guard let self = self else { return }

                // If all services are resolved, mark as complete
                if self.resolvingServices.isEmpty && self.isDiscovering {
                    self.discoveryTimer?.invalidate()

                    DispatchQueue.main.async {
                        if self.discoveredServers.isEmpty {
                            self.discoveryState = .error("No TAK servers found")
                        } else {
                            self.discoveryState = .stopped
                        }
                        self.isDiscovering = false
                    }
                }
            }
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        #if DEBUG
        print("🔍 Service removed: \(service.name)")
        #endif

        // Remove from discovered servers
        DispatchQueue.main.async {
            self.discoveredServers.removeAll { $0.name == service.name }
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        let errorCode = errorDict[NetService.errorCode] ?? -1
        let errorDomain = errorDict[NetService.errorDomain] ?? -1

        let errorMessage = "Discovery failed (code: \(errorCode), domain: \(errorDomain))"

        #if DEBUG
        print("❌ NetServiceBrowser error: \(errorMessage)")
        #endif

        DispatchQueue.main.async {
            self.discoveryState = .error(errorMessage)
            self.isDiscovering = false
        }
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        #if DEBUG
        print("🔍 NetServiceBrowser stopped searching")
        #endif

        DispatchQueue.main.async {
            self.discoveryState = .stopped
            self.isDiscovering = false
        }
    }
}

// MARK: - NetServiceDelegate

extension ServerDiscoveryService: NetServiceDelegate {

    func netServiceDidResolveAddress(_ sender: NetService) {
        #if DEBUG
        print("✅ Service resolved: \(sender.name)")
        #endif

        handleResolvedService(sender)
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        let errorCode = errorDict[NetService.errorCode] ?? -1

        #if DEBUG
        print("❌ Failed to resolve service \(sender.name): error \(errorCode)")
        #endif

        // Remove from resolving list
        if let index = resolvingServices.firstIndex(of: sender) {
            resolvingServices.remove(at: index)
        }
    }

    func netServiceDidStop(_ sender: NetService) {
        #if DEBUG
        print("🔍 Service stopped: \(sender.name)")
        #endif

        // Remove from resolving list
        if let index = resolvingServices.firstIndex(of: sender) {
            resolvingServices.remove(at: index)
        }
    }
}
