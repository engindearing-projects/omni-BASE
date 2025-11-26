//
//  NetworkMetricsService.swift
//  OmniTAKMobile
//
//  Real-time network statistics collection and monitoring
//  Tracks bandwidth, throughput, latency, and uptime metrics
//

import Foundation
import Combine

// MARK: - Metric Data Point

struct MetricDataPoint: Codable {
    let timestamp: Date
    let value: Double

    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}

// MARK: - Network Metrics

struct NetworkMetrics: Codable {
    let timestamp: Date
    let bytesPerSecond: Double
    let messagesPerSecond: Double
    let averageLatency: Double
    let uptime: TimeInterval
    let packetLoss: Double

    var formattedBytesPerSecond: String {
        formatBytes(bytesPerSecond)
    }

    var formattedLatency: String {
        String(format: "%.1f ms", averageLatency)
    }

    var formattedUptime: String {
        formatDuration(uptime)
    }

    private func formatBytes(_ bytes: Double) -> String {
        if bytes < 1024 {
            return String(format: "%.0f B/s", bytes)
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytes / 1024)
        } else {
            return String(format: "%.2f MB/s", bytes / (1024 * 1024))
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, secs)
        } else {
            return String(format: "%ds", secs)
        }
    }
}

// MARK: - Network Metrics Service

class NetworkMetricsService: ObservableObject {

    static let shared = NetworkMetricsService()

    // MARK: - Published Properties

    @Published var currentMetrics: NetworkMetrics
    @Published var bytesPerSecond: Double = 0
    @Published var messagesPerSecond: Double = 0
    @Published var averageLatency: Double = 0
    @Published var uptime: TimeInterval = 0
    @Published var packetLoss: Double = 0

    // History data
    @Published var bytesHistory: [MetricDataPoint] = []
    @Published var latencyHistory: [MetricDataPoint] = []
    @Published var messagesHistory: [MetricDataPoint] = []

    // MARK: - Private Properties

    private var connectionStartTime: Date?
    private var samplingTimer: Timer?

    // Sliding window configuration (60 minutes of history)
    private let historyWindow: TimeInterval = 3600
    private let samplingInterval: TimeInterval = 1.0

    // Counters for current sampling period
    private var bytesSentThisPeriod: Int = 0
    private var bytesReceivedThisPeriod: Int = 0
    private var messagesThisPeriod: Int = 0
    private var latencyMeasurements: [Double] = []

    // Packet loss tracking
    private var packetsSent: Int = 0
    private var packetsReceived: Int = 0
    private var expectedPackets: Int = 0

    // Thread safety
    private let metricsLock = NSLock()

    // MARK: - Initialization

    private init() {
        currentMetrics = NetworkMetrics(
            timestamp: Date(),
            bytesPerSecond: 0,
            messagesPerSecond: 0,
            averageLatency: 0,
            uptime: 0,
            packetLoss: 0
        )

        startSampling()
    }

    deinit {
        stopSampling()
    }

    // MARK: - Lifecycle

    /// Start collecting metrics
    func startConnection() {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        connectionStartTime = Date()
        resetCounters()

        #if DEBUG
        print("📊 NetworkMetrics: Started collecting metrics")
        #endif
    }

    /// Stop collecting metrics
    func stopConnection() {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        connectionStartTime = nil

        #if DEBUG
        print("📊 NetworkMetrics: Stopped collecting metrics")
        #endif
    }

    /// Reset all metrics and history
    func reset() {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        resetCounters()

        DispatchQueue.main.async {
            self.bytesHistory.removeAll()
            self.latencyHistory.removeAll()
            self.messagesHistory.removeAll()

            self.bytesPerSecond = 0
            self.messagesPerSecond = 0
            self.averageLatency = 0
            self.uptime = 0
            self.packetLoss = 0
        }

        #if DEBUG
        print("📊 NetworkMetrics: Reset all metrics")
        #endif
    }

    private func resetCounters() {
        bytesSentThisPeriod = 0
        bytesReceivedThisPeriod = 0
        messagesThisPeriod = 0
        latencyMeasurements.removeAll()
        packetsSent = 0
        packetsReceived = 0
        expectedPackets = 0
    }

    // MARK: - Recording Methods

    /// Record bytes sent
    func recordBytesSent(_ bytes: Int) {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        bytesSentThisPeriod += bytes
        packetsSent += 1
    }

    /// Record bytes received
    func recordBytesReceived(_ bytes: Int) {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        bytesReceivedThisPeriod += bytes
        packetsReceived += 1
    }

    /// Record a message sent or received
    func recordMessage() {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        messagesThisPeriod += 1
    }

    /// Record latency measurement (in milliseconds)
    func recordLatency(_ milliseconds: Double) {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        latencyMeasurements.append(milliseconds)
    }

    /// Record expected packet for packet loss calculation
    func recordExpectedPacket() {
        metricsLock.lock()
        defer { metricsLock.unlock() }

        expectedPackets += 1
    }

    // MARK: - Sampling

    private func startSampling() {
        samplingTimer = Timer.scheduledTimer(
            withTimeInterval: samplingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.performSampling()
        }
    }

    private func stopSampling() {
        samplingTimer?.invalidate()
        samplingTimer = nil
    }

    private func performSampling() {
        metricsLock.lock()

        // Calculate metrics for this period
        let totalBytes = bytesSentThisPeriod + bytesReceivedThisPeriod
        let bytesPS = Double(totalBytes) / samplingInterval
        let messagesPS = Double(messagesThisPeriod) / samplingInterval

        let avgLatency: Double
        if !latencyMeasurements.isEmpty {
            avgLatency = latencyMeasurements.reduce(0, +) / Double(latencyMeasurements.count)
        } else {
            avgLatency = averageLatency  // Keep previous value
        }

        let currentUptime: TimeInterval
        if let startTime = connectionStartTime {
            currentUptime = Date().timeIntervalSince(startTime)
        } else {
            currentUptime = 0
        }

        // Calculate packet loss
        let currentPacketLoss: Double
        if expectedPackets > 0 {
            let lostPackets = expectedPackets - packetsReceived
            currentPacketLoss = (Double(lostPackets) / Double(expectedPackets)) * 100
        } else if packetsSent > 0 {
            // Fallback: estimate based on sent vs received
            let lostPackets = max(0, packetsSent - packetsReceived)
            currentPacketLoss = (Double(lostPackets) / Double(packetsSent)) * 100
        } else {
            currentPacketLoss = 0
        }

        let timestamp = Date()

        // Create data points
        let bytesPoint = MetricDataPoint(timestamp: timestamp, value: bytesPS)
        let messagesPoint = MetricDataPoint(timestamp: timestamp, value: messagesPS)
        let latencyPoint = MetricDataPoint(timestamp: timestamp, value: avgLatency)

        // Reset period counters
        bytesSentThisPeriod = 0
        bytesReceivedThisPeriod = 0
        messagesThisPeriod = 0
        latencyMeasurements.removeAll()

        metricsLock.unlock()

        // Update published properties on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.bytesPerSecond = bytesPS
            self.messagesPerSecond = messagesPS
            self.averageLatency = avgLatency
            self.uptime = currentUptime
            self.packetLoss = currentPacketLoss

            // Update history
            self.bytesHistory.append(bytesPoint)
            self.messagesHistory.append(messagesPoint)
            self.latencyHistory.append(latencyPoint)

            // Trim history to window size
            self.trimHistory()

            // Update current metrics snapshot
            self.currentMetrics = NetworkMetrics(
                timestamp: timestamp,
                bytesPerSecond: bytesPS,
                messagesPerSecond: messagesPS,
                averageLatency: avgLatency,
                uptime: currentUptime,
                packetLoss: currentPacketLoss
            )
        }
    }

    private func trimHistory() {
        let cutoffTime = Date().addingTimeInterval(-historyWindow)

        bytesHistory.removeAll { $0.timestamp < cutoffTime }
        messagesHistory.removeAll { $0.timestamp < cutoffTime }
        latencyHistory.removeAll { $0.timestamp < cutoffTime }
    }

    // MARK: - Statistics

    /// Get peak bytes per second in history
    func getPeakBytesPerSecond() -> Double {
        return bytesHistory.map { $0.value }.max() ?? 0
    }

    /// Get peak messages per second in history
    func getPeakMessagesPerSecond() -> Double {
        return messagesHistory.map { $0.value }.max() ?? 0
    }

    /// Get minimum latency in history
    func getMinimumLatency() -> Double {
        return latencyHistory.map { $0.value }.min() ?? 0
    }

    /// Get maximum latency in history
    func getMaximumLatency() -> Double {
        return latencyHistory.map { $0.value }.max() ?? 0
    }

    /// Get average over entire history
    func getAverageBytesPerSecond() -> Double {
        guard !bytesHistory.isEmpty else { return 0 }
        let sum = bytesHistory.map { $0.value }.reduce(0, +)
        return sum / Double(bytesHistory.count)
    }

    func getAverageMessagesPerSecond() -> Double {
        guard !messagesHistory.isEmpty else { return 0 }
        let sum = messagesHistory.map { $0.value }.reduce(0, +)
        return sum / Double(messagesHistory.count)
    }

    func getAverageLatencyOverTime() -> Double {
        guard !latencyHistory.isEmpty else { return 0 }
        let sum = latencyHistory.map { $0.value }.reduce(0, +)
        return sum / Double(latencyHistory.count)
    }

    // MARK: - Export

    /// Export metrics to JSON for diagnostics
    func exportToJSON() -> String? {
        let exportData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "current": [
                "bytesPerSecond": bytesPerSecond,
                "messagesPerSecond": messagesPerSecond,
                "averageLatency": averageLatency,
                "uptime": uptime,
                "packetLoss": packetLoss
            ],
            "statistics": [
                "peakBytesPerSecond": getPeakBytesPerSecond(),
                "peakMessagesPerSecond": getPeakMessagesPerSecond(),
                "minimumLatency": getMinimumLatency(),
                "maximumLatency": getMaximumLatency(),
                "averageBytesPerSecond": getAverageBytesPerSecond(),
                "averageMessagesPerSecond": getAverageMessagesPerSecond(),
                "averageLatency": getAverageLatencyOverTime()
            ],
            "history": [
                "bytesHistory": bytesHistory.map { ["timestamp": ISO8601DateFormatter().string(from: $0.timestamp), "value": $0.value] },
                "messagesHistory": messagesHistory.map { ["timestamp": ISO8601DateFormatter().string(from: $0.timestamp), "value": $0.value] },
                "latencyHistory": latencyHistory.map { ["timestamp": ISO8601DateFormatter().string(from: $0.timestamp), "value": $0.value] }
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return jsonString
    }

    /// Export metrics to CSV format
    func exportToCSV() -> String {
        var csv = "Timestamp,BytesPerSecond,MessagesPerSecond,Latency\n"

        // Combine all timestamps
        let allTimestamps = Set(
            bytesHistory.map { $0.timestamp } +
            messagesHistory.map { $0.timestamp } +
            latencyHistory.map { $0.timestamp }
        ).sorted()

        for timestamp in allTimestamps {
            let bytes = bytesHistory.first(where: { $0.timestamp == timestamp })?.value ?? 0
            let messages = messagesHistory.first(where: { $0.timestamp == timestamp })?.value ?? 0
            let latency = latencyHistory.first(where: { $0.timestamp == timestamp })?.value ?? 0

            let timestampStr = ISO8601DateFormatter().string(from: timestamp)
            csv += "\(timestampStr),\(bytes),\(messages),\(latency)\n"
        }

        return csv
    }

    // MARK: - Convenience Methods

    /// Get metrics for a specific time range
    func getMetrics(from startDate: Date, to endDate: Date) -> [NetworkMetrics] {
        let timestamps = Set(
            bytesHistory.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }.map { $0.timestamp } +
            messagesHistory.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }.map { $0.timestamp } +
            latencyHistory.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }.map { $0.timestamp }
        ).sorted()

        return timestamps.map { timestamp in
            let bytes = bytesHistory.first(where: { $0.timestamp == timestamp })?.value ?? 0
            let messages = messagesHistory.first(where: { $0.timestamp == timestamp })?.value ?? 0
            let latency = latencyHistory.first(where: { $0.timestamp == timestamp })?.value ?? 0

            return NetworkMetrics(
                timestamp: timestamp,
                bytesPerSecond: bytes,
                messagesPerSecond: messages,
                averageLatency: latency,
                uptime: timestamp.timeIntervalSince(connectionStartTime ?? timestamp),
                packetLoss: packetLoss
            )
        }
    }

    /// Get recent metrics (last N seconds)
    func getRecentMetrics(seconds: TimeInterval) -> [NetworkMetrics] {
        let startDate = Date().addingTimeInterval(-seconds)
        return getMetrics(from: startDate, to: Date())
    }
}
