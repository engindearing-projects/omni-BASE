//
//  ConnectionHealthMonitor.swift
//  OmniTAKMobile
//
//  Health monitoring for TAK server connections
//  Tracks connection quality, latency, certificate validity, and reliability
//

import Foundation
import Combine
import Security

// MARK: - Health Status

enum HealthStatus: String {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case critical = "Critical"
    case unknown = "Unknown"

    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "lightgreen"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .critical: return "red"
        case .unknown: return "gray"
        }
    }

    static func from(score: Int) -> HealthStatus {
        switch score {
        case 90...100: return .excellent
        case 70..<90: return .good
        case 50..<70: return .fair
        case 30..<50: return .poor
        case 0..<30: return .critical
        default: return .unknown
        }
    }
}

// MARK: - Health Metrics

struct HealthMetrics {
    let timestamp: Date
    let healthScore: Int
    let status: HealthStatus

    // Component scores
    let connectionStability: Int  // 0-30 points
    let latencyScore: Int         // 0-30 points
    let messageSuccessRate: Int   // 0-20 points
    let certificateHealth: Int    // 0-20 points

    // Details
    let averageLatency: Double
    let packetLoss: Double
    let messageSuccessPercentage: Double
    let certificateExpiryDays: Int?
    let uptime: TimeInterval
}

// MARK: - Connection Health Monitor

class ConnectionHealthMonitor: ObservableObject {

    // MARK: - Published Properties

    @Published var healthScore: Int = 100
    @Published var healthStatus: HealthStatus = .excellent
    @Published var averageLatency: Double = 0
    @Published var packetLoss: Double = 0
    @Published var messageSuccessRate: Double = 100
    @Published var certificateExpiryDays: Int? = nil
    @Published var isHealthy: Bool = true

    @Published var currentMetrics: HealthMetrics?
    @Published var metricsHistory: [HealthMetrics] = []

    // MARK: - Private Properties

    private var takService: TAKService?
    private var serverId: UUID?
    private var serverConfig: TAKServer?

    private var monitoringTimer: Timer?
    private let monitoringInterval: TimeInterval = 5.0

    // Ping/keepalive
    private var pingTimer: Timer?
    private let pingInterval: TimeInterval = 30.0
    private var lastPingTime: Date?
    private var lastPongTime: Date?
    private var pingLatencies: [Double] = []

    // Message tracking
    private var messagesSent: Int = 0
    private var messagesAcknowledged: Int = 0
    private var messagesFailed: Int = 0

    // Connection stability tracking
    private var connectionEvents: [ConnectionEvent] = []
    private var lastDisconnectTime: Date?
    private var connectionStartTime: Date?

    // History configuration
    private let historyWindow: TimeInterval = 3600  // 1 hour
    private let maxPingLatencies = 10

    // Thread safety
    private let metricsLock = NSLock()

    // MARK: - Initialization

    init() {
        setupMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Configuration

    /// Attach to a TAK service for monitoring
    func attachTo(
        takService: TAKService,
        serverId: UUID,
        serverConfig: TAKServer
    ) {
        self.takService = takService
        self.serverId = serverId
        self.serverConfig = serverConfig

        connectionStartTime = Date()

        #if DEBUG
        print("💚 HealthMonitor: Attached to server \(serverConfig.name)")
        #endif

        startMonitoring()
        startPingService()
    }

    /// Detach from current service
    func detach() {
        stopMonitoring()
        stopPingService()

        takService = nil
        serverId = nil
        serverConfig = nil

        #if DEBUG
        print("💚 HealthMonitor: Detached")
        #endif
    }

    // MARK: - Monitoring

    private func setupMonitoring() {
        // Will start when attached
    }

    private func startMonitoring() {
        monitoringTimer?.invalidate()

        monitoringTimer = Timer.scheduledTimer(
            withTimeInterval: monitoringInterval,
            repeats: true
        ) { [weak self] _ in
            self?.performHealthCheck()
        }

        // Perform initial check
        performHealthCheck()
    }

    private func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    private func performHealthCheck() {
        guard let takService = takService else { return }

        metricsLock.lock()
        defer { metricsLock.unlock() }

        // Calculate component scores

        // 1. Connection Stability (30 points)
        let stabilityScore = calculateConnectionStability()

        // 2. Latency Score (30 points)
        let latencyScore = calculateLatencyScore()

        // 3. Message Success Rate (20 points)
        let messageScore = calculateMessageSuccessRate()

        // 4. Certificate Health (20 points)
        let certScore = calculateCertificateHealth()

        // Total health score
        let totalScore = stabilityScore + latencyScore + messageScore + certScore

        // Calculate averages
        let avgLatency = pingLatencies.isEmpty ? 0 : pingLatencies.reduce(0, +) / Double(pingLatencies.count)
        let totalMessages = messagesSent + messagesFailed
        let successRate = totalMessages > 0 ? (Double(messagesAcknowledged) / Double(totalMessages)) * 100 : 100
        let loss = totalMessages > 0 ? (Double(messagesFailed) / Double(totalMessages)) * 100 : 0

        let uptime = connectionStartTime.map { Date().timeIntervalSince($0) } ?? 0

        // Create metrics
        let metrics = HealthMetrics(
            timestamp: Date(),
            healthScore: totalScore,
            status: HealthStatus.from(score: totalScore),
            connectionStability: stabilityScore,
            latencyScore: latencyScore,
            messageSuccessRate: messageScore,
            certificateHealth: certScore,
            averageLatency: avgLatency,
            packetLoss: loss,
            messageSuccessPercentage: successRate,
            certificateExpiryDays: certificateExpiryDays,
            uptime: uptime
        )

        // Update published properties
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.healthScore = totalScore
            self.healthStatus = HealthStatus.from(score: totalScore)
            self.averageLatency = avgLatency
            self.packetLoss = loss
            self.messageSuccessRate = successRate
            self.isHealthy = totalScore >= 50

            self.currentMetrics = metrics
            self.metricsHistory.append(metrics)

            // Trim history
            let cutoff = Date().addingTimeInterval(-self.historyWindow)
            self.metricsHistory.removeAll { $0.timestamp < cutoff }

            // Send warning notification if health is poor
            if totalScore < 50 && totalScore > 0 {
                self.sendHealthWarning(score: totalScore)
            }
        }
    }

    // MARK: - Score Calculations

    private func calculateConnectionStability() -> Int {
        guard let startTime = connectionStartTime else { return 0 }

        let uptime = Date().timeIntervalSince(startTime)

        // Count disconnections in the last hour
        let recentEvents = connectionEvents.filter {
            $0.timestamp > Date().addingTimeInterval(-3600)
        }

        let disconnections = recentEvents.filter { $0.type == .disconnected }.count

        // Perfect: no disconnections = 30 points
        // Each disconnection removes 10 points
        let score = max(0, 30 - (disconnections * 10))

        // Bonus for long uptime (up to 5 points)
        let uptimeBonus = min(5, Int(uptime / 3600))  // 1 point per hour, max 5

        return min(30, score + uptimeBonus)
    }

    private func calculateLatencyScore() -> Int {
        guard !pingLatencies.isEmpty else { return 30 }  // No data = assume perfect

        let avgLatency = pingLatencies.reduce(0, +) / Double(pingLatencies.count)

        // Scoring:
        // < 50ms: 30 points (excellent)
        // 50-100ms: 25 points (good)
        // 100-200ms: 20 points (fair)
        // 200-500ms: 15 points (poor)
        // > 500ms: 5 points (critical)

        switch avgLatency {
        case 0..<50:
            return 30
        case 50..<100:
            return 25
        case 100..<200:
            return 20
        case 200..<500:
            return 15
        default:
            return 5
        }
    }

    private func calculateMessageSuccessRate() -> Int {
        let total = messagesSent + messagesFailed

        guard total > 0 else { return 20 }  // No data = assume perfect

        let successRate = Double(messagesAcknowledged) / Double(total)

        // Convert to 0-20 scale
        return Int(successRate * 20)
    }

    private func calculateCertificateHealth() -> Int {
        guard let serverConfig = serverConfig,
              serverConfig.useTLS,
              let certName = serverConfig.certificateName else {
            // No TLS or no cert required = full points
            return 20
        }

        // Check if certificate exists
        guard let cert = CertificateManager.shared.certificates.first(where: { $0.name == certName }) else {
            return 0  // Certificate not found
        }

        // Check expiry
        if cert.isExpired {
            return 0  // Expired certificate
        }

        guard let expiryDate = cert.expiryDate else {
            return 15  // No expiry info, assume OK
        }

        let daysUntilExpiry = Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: expiryDate
        ).day ?? 0

        // Update published property
        DispatchQueue.main.async { [weak self] in
            self?.certificateExpiryDays = daysUntilExpiry
        }

        // Scoring:
        // > 90 days: 20 points (excellent)
        // 30-90 days: 15 points (good)
        // 7-30 days: 10 points (warning)
        // < 7 days: 5 points (critical)

        switch daysUntilExpiry {
        case 90...:
            return 20
        case 30..<90:
            return 15
        case 7..<30:
            return 10
        default:
            return 5
        }
    }

    // MARK: - Ping Service

    private func startPingService() {
        pingTimer?.invalidate()

        pingTimer = Timer.scheduledTimer(
            withTimeInterval: pingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.sendPing()
        }

        // Send initial ping
        sendPing()
    }

    private func stopPingService() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendPing() {
        guard let takService = takService,
              takService.isConnected else { return }

        lastPingTime = Date()

        // Send a lightweight CoT ping message
        let pingXML = """
        <?xml version="1.0" encoding="UTF-8"?>
        <event version="2.0" uid="ping-\(UUID().uuidString)" type="t-x-c-t" time="\(ISO8601DateFormatter().string(from: Date()))" start="\(ISO8601DateFormatter().string(from: Date()))" stale="\(ISO8601DateFormatter().string(from: Date().addingTimeInterval(60)))" how="h-e">
            <point lat="0" lon="0" hae="0" ce="9999999" le="9999999"/>
            <detail>
                <takv version="1.0" platform="OmniTAK" device="iOS"/>
                <ping/>
            </detail>
        </event>
        """

        if takService.sendCoT(xml: pingXML) {
            #if DEBUG
            print("💚 Sent ping")
            #endif
        }
    }

    func recordPong() {
        guard let pingTime = lastPingTime else { return }

        lastPongTime = Date()
        let latency = lastPongTime!.timeIntervalSince(pingTime) * 1000  // Convert to ms

        metricsLock.lock()
        pingLatencies.append(latency)

        // Keep only recent latencies
        if pingLatencies.count > maxPingLatencies {
            pingLatencies.removeFirst()
        }
        metricsLock.unlock()

        #if DEBUG
        print("💚 Pong received, latency: \(String(format: "%.1f", latency))ms")
        #endif
    }

    // MARK: - Event Recording

    func recordConnectionEvent(_ type: ConnectionEventType) {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        let event = ConnectionEvent(timestamp: Date(), type: type)
        connectionEvents.append(event)

        // Keep only last hour of events
        let cutoff = Date().addingTimeInterval(-3600)
        connectionEvents.removeAll { $0.timestamp < cutoff }

        if type == .disconnected {
            lastDisconnectTime = Date()
        } else if type == .connected {
            connectionStartTime = Date()
        }
    }

    func recordMessageSent() {
        metricsLock.lock()
        messagesSent += 1
        metricsLock.unlock()
    }

    func recordMessageAcknowledged() {
        metricsLock.lock()
        messagesAcknowledged += 1
        metricsLock.unlock()
    }

    func recordMessageFailed() {
        metricsLock.lock()
        messagesFailed += 1
        metricsLock.unlock()
    }

    func recordLatency(_ milliseconds: Double) {
        metricsLock.lock()
        pingLatencies.append(milliseconds)

        if pingLatencies.count > maxPingLatencies {
            pingLatencies.removeFirst()
        }
        metricsLock.unlock()
    }

    // MARK: - Notifications

    private func sendHealthWarning(score: Int) {
        #if DEBUG
        print("⚠️ Health Warning: Connection health is poor (score: \(score))")
        #endif

        // In a real app, you would post a notification here
        // NotificationCenter.default.post(name: .healthWarning, object: self, userInfo: ["score": score])
    }

    // MARK: - Statistics

    func getAverageHealthScore() -> Int {
        guard !metricsHistory.isEmpty else { return 100 }

        let sum = metricsHistory.map { $0.healthScore }.reduce(0, +)
        return sum / metricsHistory.count
    }

    func getMinHealthScore() -> Int {
        return metricsHistory.map { $0.healthScore }.min() ?? 100
    }

    func getMaxHealthScore() -> Int {
        return metricsHistory.map { $0.healthScore }.max() ?? 100
    }

    func getTotalDisconnections() -> Int {
        return connectionEvents.filter { $0.type == .disconnected }.count
    }

    func getUptimePercentage() -> Double {
        guard let startTime = connectionStartTime else { return 0 }

        let totalTime = Date().timeIntervalSince(startTime)
        let disconnectTime = connectionEvents
            .filter { $0.type == .disconnected }
            .reduce(0) { sum, event in
                // Estimate 5 seconds per disconnection
                return sum + 5.0
            }

        guard totalTime > 0 else { return 100 }

        return max(0, ((totalTime - disconnectTime) / totalTime) * 100)
    }

    // MARK: - Reset

    func reset() {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        messagesSent = 0
        messagesAcknowledged = 0
        messagesFailed = 0
        pingLatencies.removeAll()
        connectionEvents.removeAll()

        DispatchQueue.main.async {
            self.metricsHistory.removeAll()
            self.healthScore = 100
            self.healthStatus = .excellent
            self.isHealthy = true
        }
    }
}

// MARK: - Connection Event

struct ConnectionEvent {
    let timestamp: Date
    let type: ConnectionEventType
}

enum ConnectionEventType {
    case connected
    case disconnected
    case reconnecting
    case error
}
