//
//  ConnectionCoordinator.swift
//  OmniTAKMobile
//
//  Multi-server TAK connection coordinator
//  Manages multiple simultaneous TAK server connections with message routing
//

import Foundation
import Combine
import CoreLocation

// MARK: - Connection State

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed(String)

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}

// MARK: - Message Queue Entry

struct NetworkQueuedMessage {
    let id: UUID
    let xml: String
    let priority: MessagePriority
    let timestamp: Date
    let retryCount: Int

    enum MessagePriority: Int, Comparable {
        case low = 0
        case normal = 1
        case high = 2
        case emergency = 3

        static func < (lhs: MessagePriority, rhs: MessagePriority) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - Connection Info

struct ConnectionInfo {
    let serverId: UUID
    let serverName: String
    var state: ConnectionState
    var lastConnected: Date?
    var messagesSent: Int
    var messagesReceived: Int
    var queuedMessages: Int

    var isHealthy: Bool {
        state.isConnected && queuedMessages < 100
    }
}

// MARK: - Connection Coordinator

class ConnectionCoordinator: ObservableObject {

    static let shared = ConnectionCoordinator()

    // MARK: - Published Properties

    @Published var activeConnections: [UUID: ConnectionInfo] = [:]
    @Published var primaryServerId: UUID?
    @Published var connectionStates: [UUID: ConnectionState] = [:]
    @Published var totalMessagesSent: Int = 0
    @Published var totalMessagesReceived: Int = 0

    // MARK: - Private Properties

    private var takServices: [UUID: TAKService] = [:]
    private var messageQueues: [UUID: [NetworkQueuedMessage]] = [:]
    private let queueLock = NSLock()
    private var cancellables = Set<AnyCancellable>()

    // Configuration
    private let maxQueueSize = 1000
    private let maxRetries = 3
    private let queueProcessingInterval: TimeInterval = 0.5
    private var queueTimer: Timer?

    // MARK: - Initialization

    private init() {
        setupQueueProcessing()

        #if DEBUG
        print("🔗 ConnectionCoordinator initialized")
        #endif
    }

    deinit {
        queueTimer?.invalidate()
        disconnectAll()
    }

    // MARK: - Connection Management

    /// Add a new TAK server connection
    func addConnection(
        for server: TAKServer,
        completion: @escaping (Bool, String?) -> Void
    ) {
        guard takServices[server.id] == nil else {
            completion(false, "Connection already exists for this server")
            return
        }

        #if DEBUG
        print("🔗 Adding connection for server: \(server.name)")
        #endif

        // Create new TAKService instance
        let takService = TAKService()
        takServices[server.id] = takService

        // Initialize connection info
        let connectionInfo = ConnectionInfo(
            serverId: server.id,
            serverName: server.name,
            state: .connecting,
            lastConnected: nil,
            messagesSent: 0,
            messagesReceived: 0,
            queuedMessages: 0
        )

        DispatchQueue.main.async {
            self.activeConnections[server.id] = connectionInfo
            self.connectionStates[server.id] = .connecting
            self.messageQueues[server.id] = []
        }

        // Setup message receiving
        setupReceiveHandler(for: server.id, takService: takService)

        // Setup state monitoring
        takService.$connectionState
            .sink { [weak self] state in
                self?.updateConnectionState(
                    serverId: server.id,
                    state: state.isConnected ? .connected : .disconnected
                )
            }
            .store(in: &cancellables)

        takService.$messagesReceived
            .sink { [weak self] count in
                self?.updateReceivedCount(serverId: server.id, count: count)
            }
            .store(in: &cancellables)

        takService.$messagesSent
            .sink { [weak self] count in
                self?.updateSentCount(serverId: server.id, count: count)
            }
            .store(in: &cancellables)

        // Connect to server
        takService.connect(
            host: server.host,
            port: server.port,
            protocolType: server.protocolType,
            useTLS: server.useTLS,
            certificateName: server.certificateName,
            certificatePassword: server.certificatePassword
        )

        // Wait for connection result
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }

            if takService.isConnected {
                self.updateConnectionState(serverId: server.id, state: .connected)

                // Set as primary if it's the first connection
                if self.primaryServerId == nil {
                    self.primaryServerId = server.id
                }

                completion(true, nil)

                #if DEBUG
                print("✅ Connection established for \(server.name)")
                #endif
            } else {
                self.updateConnectionState(
                    serverId: server.id,
                    state: .failed("Connection timeout")
                )
                completion(false, "Failed to connect to \(server.name)")
            }
        }
    }

    /// Remove a connection
    func removeConnection(serverId: UUID) {
        guard let takService = takServices[serverId] else { return }

        #if DEBUG
        print("🔗 Removing connection for server: \(serverId)")
        #endif

        // Disconnect
        takService.disconnect()

        // Remove from tracking
        takServices.removeValue(forKey: serverId)

        DispatchQueue.main.async {
            self.activeConnections.removeValue(forKey: serverId)
            self.connectionStates.removeValue(forKey: serverId)

            self.queueLock.lock()
            self.messageQueues.removeValue(forKey: serverId)
            self.queueLock.unlock()

            // Update primary server if needed
            if self.primaryServerId == serverId {
                self.primaryServerId = self.activeConnections.keys.first
            }
        }
    }

    /// Get a specific connection
    func getConnection(serverId: UUID) -> TAKService? {
        return takServices[serverId]
    }

    /// Get all connections
    func getAllConnections() -> [UUID: TAKService] {
        return takServices
    }

    /// Get connection info for all servers
    func getAllConnectionInfo() -> [ConnectionInfo] {
        return Array(activeConnections.values)
    }

    /// Disconnect all servers
    func disconnectAll() {
        #if DEBUG
        print("🔗 Disconnecting all servers")
        #endif

        for (_, takService) in takServices {
            takService.disconnect()
        }

        takServices.removeAll()

        DispatchQueue.main.async {
            self.activeConnections.removeAll()
            self.connectionStates.removeAll()
            self.messageQueues.removeAll()
            self.primaryServerId = nil
        }
    }

    /// Set primary server for default routing
    func setPrimaryServer(serverId: UUID) {
        guard activeConnections[serverId] != nil else {
            print("⚠️ Cannot set primary server: not connected")
            return
        }

        primaryServerId = serverId

        #if DEBUG
        print("🔗 Primary server set to: \(serverId)")
        #endif
    }

    // MARK: - Message Routing

    /// Send message to a specific server
    func sendMessage(
        _ xml: String,
        to serverId: UUID,
        priority: NetworkQueuedMessage.MessagePriority = .normal
    ) -> Bool {
        guard let takService = takServices[serverId] else {
            print("❌ No connection found for server: \(serverId)")
            return false
        }

        // Try immediate send if connected
        if takService.isConnected {
            let success = takService.sendCoT(xml: xml)
            if success {
                incrementSentCount(serverId: serverId)
                return true
            }
        }

        // Queue message if immediate send failed
        queueMessage(xml, for: serverId, priority: priority)
        return false
    }

    /// Broadcast message to all connected servers
    func broadcastMessage(
        _ xml: String,
        priority: NetworkQueuedMessage.MessagePriority = .normal
    ) -> [UUID: Bool] {
        var results: [UUID: Bool] = [:]

        for (serverId, takService) in takServices {
            if takService.isConnected {
                let success = takService.sendCoT(xml: xml)
                results[serverId] = success

                if success {
                    incrementSentCount(serverId: serverId)
                }
            } else {
                // Queue for later
                queueMessage(xml, for: serverId, priority: priority)
                results[serverId] = false
            }
        }

        return results
    }

    /// Send message to primary server
    func sendToPrimary(
        _ xml: String,
        priority: NetworkQueuedMessage.MessagePriority = .normal
    ) -> Bool {
        guard let primaryId = primaryServerId else {
            print("❌ No primary server set")
            return false
        }

        return sendMessage(xml, to: primaryId, priority: priority)
    }

    /// Send waypoint to specific server
    func sendWaypoint(
        _ waypoint: Waypoint,
        to serverId: UUID,
        staleTime: TimeInterval = 3600
    ) -> Bool {
        guard let takService = takServices[serverId] else {
            return false
        }

        let success = takService.sendWaypoint(waypoint, staleTime: staleTime)
        if success {
            incrementSentCount(serverId: serverId)
        }

        return success
    }

    /// Broadcast waypoint to all servers
    func broadcastWaypoint(
        _ waypoint: Waypoint,
        staleTime: TimeInterval = 3600
    ) -> [UUID: Bool] {
        var results: [UUID: Bool] = [:]

        for (serverId, takService) in takServices {
            if takService.isConnected {
                let success = takService.sendWaypoint(waypoint, staleTime: staleTime)
                results[serverId] = success

                if success {
                    incrementSentCount(serverId: serverId)
                }
            }
        }

        return results
    }

    // MARK: - Message Queue Management

    private func queueMessage(
        _ xml: String,
        for serverId: UUID,
        priority: NetworkQueuedMessage.MessagePriority
    ) {
        queueLock.lock()
        defer { queueLock.unlock() }

        guard var queue = messageQueues[serverId] else { return }

        // Check queue size limit
        if queue.count >= maxQueueSize {
            // Remove lowest priority message
            if let lowestIndex = queue.enumerated().min(by: { $0.element.priority < $1.element.priority })?.offset {
                queue.remove(at: lowestIndex)
                #if DEBUG
                print("⚠️ Queue full, removed lowest priority message")
                #endif
            }
        }

        let message = NetworkQueuedMessage(
            id: UUID(),
            xml: xml,
            priority: priority,
            timestamp: Date(),
            retryCount: 0
        )

        queue.append(message)

        // Sort by priority (highest first)
        queue.sort { $0.priority > $1.priority }

        messageQueues[serverId] = queue

        // Update connection info
        updateQueuedCount(serverId: serverId, count: queue.count)

        #if DEBUG
        print("📥 Message queued for server \(serverId), queue size: \(queue.count)")
        #endif
    }

    private func setupQueueProcessing() {
        queueTimer = Timer.scheduledTimer(
            withTimeInterval: queueProcessingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.processMessageQueues()
        }
    }

    private func processMessageQueues() {
        queueLock.lock()
        defer { queueLock.unlock() }

        for (serverId, var queue) in messageQueues {
            guard let takService = takServices[serverId],
                  takService.isConnected,
                  !queue.isEmpty else {
                continue
            }

            // Process messages in priority order
            var processedIndices: [Int] = []

            for (index, message) in queue.enumerated() {
                if takService.sendCoT(xml: message.xml) {
                    processedIndices.append(index)
                    incrementSentCount(serverId: serverId)
                } else if message.retryCount >= maxRetries {
                    // Remove message after max retries
                    processedIndices.append(index)
                    #if DEBUG
                    print("❌ Message dropped after \(maxRetries) retries")
                    #endif
                } else {
                    // Increment retry count
                    var updatedMessage = message
                    updatedMessage = NetworkQueuedMessage(
                        id: message.id,
                        xml: message.xml,
                        priority: message.priority,
                        timestamp: message.timestamp,
                        retryCount: message.retryCount + 1
                    )
                    queue[index] = updatedMessage
                }
            }

            // Remove processed messages
            for index in processedIndices.reversed() {
                queue.remove(at: index)
            }

            messageQueues[serverId] = queue
            updateQueuedCount(serverId: serverId, count: queue.count)
        }
    }

    /// Get queue size for a specific server
    func getQueueSize(serverId: UUID) -> Int {
        queueLock.lock()
        defer { queueLock.unlock() }

        return messageQueues[serverId]?.count ?? 0
    }

    /// Clear queue for a specific server
    func clearQueue(serverId: UUID) {
        queueLock.lock()
        defer { queueLock.unlock() }

        messageQueues[serverId] = []
        updateQueuedCount(serverId: serverId, count: 0)
    }

    // MARK: - Receive Handling

    private func setupReceiveHandler(for serverId: UUID, takService: TAKService) {
        // Forward CoT events
        takService.onCoTReceived = { [weak self] event in
            self?.handleReceivedCoT(event, from: serverId)
        }

        // Forward marker updates
        takService.onMarkerUpdated = { [weak self] marker in
            self?.handleMarkerUpdate(marker, from: serverId)
        }

        // Forward chat messages
        takService.onChatMessageReceived = { [weak self] chatMessage in
            self?.handleChatMessage(chatMessage, from: serverId)
        }
    }

    private func handleReceivedCoT(_ event: CoTEvent, from serverId: UUID) {
        // Could aggregate or deduplicate events from multiple servers here
        #if DEBUG
        print("📥 CoT event from server \(serverId): \(event.detail.callsign)")
        #endif
    }

    private func handleMarkerUpdate(_ marker: EnhancedCoTMarker, from serverId: UUID) {
        // Could merge marker data from multiple servers
        #if DEBUG
        print("📍 Marker update from server \(serverId): \(marker.callsign)")
        #endif
    }

    private func handleChatMessage(_ message: ChatMessage, from serverId: UUID) {
        // Chat messages are already handled by ChatManager
        #if DEBUG
        print("💬 Chat message from server \(serverId): \(message.senderCallsign)")
        #endif
    }

    // MARK: - State Management

    private func updateConnectionState(serverId: UUID, state: ConnectionState) {
        DispatchQueue.main.async {
            self.connectionStates[serverId] = state

            if var info = self.activeConnections[serverId] {
                info.state = state

                if state.isConnected {
                    info.lastConnected = Date()
                }

                self.activeConnections[serverId] = info
            }
        }
    }

    private func updateSentCount(serverId: UUID, count: Int) {
        DispatchQueue.main.async {
            if var info = self.activeConnections[serverId] {
                info.messagesSent = count
                self.activeConnections[serverId] = info
            }

            // Update total
            self.totalMessagesSent = self.activeConnections.values.reduce(0) { $0 + $1.messagesSent }
        }
    }

    private func updateReceivedCount(serverId: UUID, count: Int) {
        DispatchQueue.main.async {
            if var info = self.activeConnections[serverId] {
                info.messagesReceived = count
                self.activeConnections[serverId] = info
            }

            // Update total
            self.totalMessagesReceived = self.activeConnections.values.reduce(0) { $0 + $1.messagesReceived }
        }
    }

    private func incrementSentCount(serverId: UUID) {
        DispatchQueue.main.async {
            if var info = self.activeConnections[serverId] {
                info.messagesSent += 1
                self.activeConnections[serverId] = info
                self.totalMessagesSent += 1
            }
        }
    }

    private func updateQueuedCount(serverId: UUID, count: Int) {
        DispatchQueue.main.async {
            if var info = self.activeConnections[serverId] {
                info.queuedMessages = count
                self.activeConnections[serverId] = info
            }
        }
    }

    // MARK: - Utility

    /// Check if any server is connected
    var hasActiveConnection: Bool {
        return takServices.values.contains { $0.isConnected }
    }

    /// Get count of connected servers
    var connectedServerCount: Int {
        return takServices.values.filter { $0.isConnected }.count
    }

    /// Get list of connected server IDs
    var connectedServerIds: [UUID] {
        return takServices.filter { $0.value.isConnected }.map { $0.key }
    }
}
