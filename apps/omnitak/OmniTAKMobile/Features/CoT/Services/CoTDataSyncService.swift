//
//  CoTDataSyncService.swift
//  OmniTAKMobile
//
//  CoT message persistence and synchronization service
//  Handles offline storage, message history, and data sync
//

import Foundation
import Combine
import CoreLocation

// MARK: - Persisted CoT Message

struct PersistedCoTMessage: Codable, Identifiable {
    let id: UUID
    let uid: String
    let type: String
    let xmlContent: String
    let timestamp: Date
    let coordinate: CoordinateData
    let callsign: String?
    let status: MessageStatus
    let direction: MessageDirection

    enum MessageStatus: String, Codable {
        case pending        // Waiting to be sent
        case sent           // Successfully sent to server
        case received       // Received from server
        case failed         // Failed to send
    }

    enum MessageDirection: String, Codable {
        case outbound       // Sent by this client
        case inbound        // Received from server/other clients
    }

    struct CoordinateData: Codable {
        let latitude: Double
        let longitude: Double
        let altitude: Double?
    }

    init(
        id: UUID = UUID(),
        uid: String,
        type: String,
        xmlContent: String,
        timestamp: Date = Date(),
        coordinate: CLLocationCoordinate2D,
        altitude: Double? = nil,
        callsign: String? = nil,
        status: MessageStatus = .pending,
        direction: MessageDirection = .outbound
    ) {
        self.id = id
        self.uid = uid
        self.type = type
        self.xmlContent = xmlContent
        self.timestamp = timestamp
        self.coordinate = CoordinateData(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: altitude
        )
        self.callsign = callsign
        self.status = status
        self.direction = direction
    }

    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}

// MARK: - Sync Statistics

struct CoTSyncStatistics: Codable {
    var totalMessagesSent: Int = 0
    var totalMessagesReceived: Int = 0
    var failedMessages: Int = 0
    var lastSyncTime: Date?
    var pendingMessages: Int = 0

    var description: String {
        """
        Sent: \(totalMessagesSent)
        Received: \(totalMessagesReceived)
        Failed: \(failedMessages)
        Pending: \(pendingMessages)
        Last Sync: \(lastSyncTime?.formatted() ?? "Never")
        """
    }
}

// MARK: - CoT Data Sync Service

class CoTDataSyncService: ObservableObject {
    static let shared = CoTDataSyncService()

    // MARK: - Published Properties

    @Published var messages: [PersistedCoTMessage] = []
    @Published var statistics: CoTSyncStatistics = CoTSyncStatistics()
    @Published var isEnabled: Bool = true
    @Published var retentionDays: Int = 7  // Keep messages for 7 days by default

    // MARK: - Private Properties

    private let messagesKey = "cot_persisted_messages"
    private let statisticsKey = "cot_sync_statistics"
    private let maxMessagesInMemory = 1000  // Limit in-memory storage
    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()

    // File-based storage directory
    private var storageDirectory: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let cotDirectory = documentsDirectory.appendingPathComponent("CoTMessages")

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: cotDirectory.path) {
            try? fileManager.createDirectory(at: cotDirectory, withIntermediateDirectories: true)
        }

        return cotDirectory
    }

    // MARK: - Initialization

    private init() {
        loadMessages()
        loadStatistics()
        setupAutoSave()
        startCleanupTimer()

        print("[CoTSync] Data sync service initialized")
        print("[CoTSync] Storage directory: \(storageDirectory.path)")
    }

    // MARK: - Message Persistence

    /// Save a CoT message to persistent storage
    func saveMessage(_ message: PersistedCoTMessage) {
        // Add to in-memory array
        messages.append(message)

        // Update statistics
        switch message.direction {
        case .outbound:
            statistics.totalMessagesSent += 1
            if message.status == .pending {
                statistics.pendingMessages += 1
            } else if message.status == .failed {
                statistics.failedMessages += 1
            }
        case .inbound:
            statistics.totalMessagesReceived += 1
        }

        statistics.lastSyncTime = Date()

        // Limit in-memory messages
        if messages.count > maxMessagesInMemory {
            let oldMessages = messages.prefix(messages.count - maxMessagesInMemory)
            messages = Array(messages.suffix(maxMessagesInMemory))

            // Archive old messages to disk
            archiveMessages(Array(oldMessages))
        }

        // Save to disk
        saveMessages()
        saveStatistics()

        print("[CoTSync] Saved message: \(message.uid) (\(message.type))")
    }

    /// Save a CoT XML message (convenience method)
    func saveCoTXML(
        _ xml: String,
        uid: String,
        type: String,
        coordinate: CLLocationCoordinate2D,
        altitude: Double? = nil,
        callsign: String? = nil,
        direction: PersistedCoTMessage.MessageDirection = .outbound
    ) {
        let message = PersistedCoTMessage(
            uid: uid,
            type: type,
            xmlContent: xml,
            coordinate: coordinate,
            altitude: altitude,
            callsign: callsign,
            status: .sent,
            direction: direction
        )

        saveMessage(message)
    }

    /// Update message status
    func updateMessageStatus(_ messageId: UUID, status: PersistedCoTMessage.MessageStatus) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else {
            return
        }

        var updatedMessage = messages[index]
        let oldStatus = updatedMessage.status

        // Update statistics
        if oldStatus == .pending && status != .pending {
            statistics.pendingMessages = max(0, statistics.pendingMessages - 1)
        }

        if status == .failed && oldStatus != .failed {
            statistics.failedMessages += 1
        }

        messages[index] = PersistedCoTMessage(
            id: updatedMessage.id,
            uid: updatedMessage.uid,
            type: updatedMessage.type,
            xmlContent: updatedMessage.xmlContent,
            timestamp: updatedMessage.timestamp,
            coordinate: updatedMessage.clCoordinate,
            altitude: updatedMessage.coordinate.altitude,
            callsign: updatedMessage.callsign,
            status: status,
            direction: updatedMessage.direction
        )

        saveMessages()
        saveStatistics()

        print("[CoTSync] Updated message \(messageId) status: \(oldStatus) → \(status)")
    }

    // MARK: - Message Retrieval

    /// Get all messages
    func getAllMessages() -> [PersistedCoTMessage] {
        return messages
    }

    /// Get messages filtered by criteria
    func getMessages(
        direction: PersistedCoTMessage.MessageDirection? = nil,
        status: PersistedCoTMessage.MessageStatus? = nil,
        type: String? = nil,
        since: Date? = nil
    ) -> [PersistedCoTMessage] {
        return messages.filter { message in
            if let direction = direction, message.direction != direction {
                return false
            }

            if let status = status, message.status != status {
                return false
            }

            if let type = type, message.type != type {
                return false
            }

            if let since = since, message.timestamp < since {
                return false
            }

            return true
        }
    }

    /// Get pending outbound messages (for retry logic)
    func getPendingMessages() -> [PersistedCoTMessage] {
        return getMessages(direction: .outbound, status: .pending)
    }

    /// Get failed messages
    func getFailedMessages() -> [PersistedCoTMessage] {
        return getMessages(status: .failed)
    }

    /// Get recent messages (last 24 hours)
    func getRecentMessages() -> [PersistedCoTMessage] {
        let yesterday = Date().addingTimeInterval(-24 * 3600)
        return getMessages(since: yesterday)
    }

    /// Get message by UID
    func getMessage(uid: String) -> PersistedCoTMessage? {
        return messages.first { $0.uid == uid }
    }

    // MARK: - Message History Management

    /// Delete old messages beyond retention period
    func cleanupOldMessages() {
        let cutoffDate = Date().addingTimeInterval(-Double(retentionDays) * 24 * 3600)
        let oldMessageCount = messages.count

        messages = messages.filter { $0.timestamp > cutoffDate }

        let deletedCount = oldMessageCount - messages.count
        if deletedCount > 0 {
            saveMessages()
            print("[CoTSync] Cleaned up \(deletedCount) old messages")
        }
    }

    /// Clear all messages
    func clearAllMessages() {
        messages.removeAll()
        statistics = CoTSyncStatistics()
        saveMessages()
        saveStatistics()

        // Clear archived messages
        try? fileManager.removeItem(at: storageDirectory)

        print("[CoTSync] Cleared all messages")
    }

    /// Delete specific message
    func deleteMessage(_ messageId: UUID) {
        messages.removeAll { $0.id == messageId }
        saveMessages()

        print("[CoTSync] Deleted message: \(messageId)")
    }

    // MARK: - Sync Operations

    /// Retry sending failed messages
    func retryFailedMessages(sendHandler: (String) -> Bool) {
        let failedMessages = getFailedMessages()

        print("[CoTSync] Retrying \(failedMessages.count) failed messages")

        for message in failedMessages {
            let success = sendHandler(message.xmlContent)

            updateMessageStatus(
                message.id,
                status: success ? .sent : .failed
            )
        }
    }

    /// Export messages to file (for backup/sharing)
    func exportMessages(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(messages)
        try data.write(to: url)

        print("[CoTSync] Exported \(messages.count) messages to: \(url.path)")
    }

    /// Import messages from file
    func importMessages(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let importedMessages = try decoder.decode([PersistedCoTMessage].self, from: data)

        // Merge with existing messages (avoid duplicates by UID)
        let existingUIDs = Set(messages.map { $0.uid })
        let newMessages = importedMessages.filter { !existingUIDs.contains($0.uid) }

        messages.append(contentsOf: newMessages)
        saveMessages()

        print("[CoTSync] Imported \(newMessages.count) new messages")
    }

    // MARK: - Persistence (Disk I/O)

    private func saveMessages() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(messages) {
            UserDefaults.standard.set(data, forKey: messagesKey)
        }
    }

    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: messagesKey) else {
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let loadedMessages = try? decoder.decode([PersistedCoTMessage].self, from: data) {
            messages = loadedMessages
            print("[CoTSync] Loaded \(messages.count) messages from storage")
        }
    }

    private func saveStatistics() {
        let encoder = JSONEncoder()

        if let data = try? encoder.encode(statistics) {
            UserDefaults.standard.set(data, forKey: statisticsKey)
        }
    }

    private func loadStatistics() {
        guard let data = UserDefaults.standard.data(forKey: statisticsKey) else {
            return
        }

        if let loadedStats = try? JSONDecoder().decode(CoTSyncStatistics.self, from: data) {
            statistics = loadedStats
            print("[CoTSync] Loaded statistics: \(statistics.description)")
        }
    }

    private func archiveMessages(_ messages: [PersistedCoTMessage]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())

        let archiveFile = storageDirectory.appendingPathComponent("archive-\(dateStr).json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let data = try encoder.encode(messages)
            try data.write(to: archiveFile)

            print("[CoTSync] Archived \(messages.count) messages to: \(archiveFile.lastPathComponent)")
        } catch {
            print("[CoTSync] Failed to archive messages: \(error)")
        }
    }

    // MARK: - Auto-Save Setup

    private func setupAutoSave() {
        // Auto-save every 60 seconds
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.saveMessages()
                self?.saveStatistics()
            }
            .store(in: &cancellables)
    }

    private func startCleanupTimer() {
        // Cleanup old messages every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupOldMessages()
            }
            .store(in: &cancellables)
    }

    // MARK: - Settings

    func updateRetentionPeriod(days: Int) {
        retentionDays = max(1, min(days, 30))  // 1-30 days
        cleanupOldMessages()

        print("[CoTSync] Updated retention period to \(retentionDays) days")
    }

    // MARK: - Statistics

    func resetStatistics() {
        statistics = CoTSyncStatistics()
        saveStatistics()

        print("[CoTSync] Reset statistics")
    }

    func getStorageSize() -> String {
        var totalSize: Int64 = 0

        // Calculate size of in-memory storage (UserDefaults)
        if let data = UserDefaults.standard.data(forKey: messagesKey) {
            totalSize += Int64(data.count)
        }

        // Calculate size of archived files
        if let files = try? fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

// MARK: - Offline Queue Manager

extension CoTDataSyncService {

    /// Queue a message for later sending when offline
    func queueMessage(_ xml: String, uid: String, type: String, coordinate: CLLocationCoordinate2D) {
        let message = PersistedCoTMessage(
            uid: uid,
            type: type,
            xmlContent: xml,
            coordinate: coordinate,
            status: .pending,
            direction: .outbound
        )

        saveMessage(message)
        print("[CoTSync] Queued message for offline sending: \(uid)")
    }

    /// Process offline queue when connection is restored
    func processOfflineQueue(sendHandler: (String) -> Bool) {
        let pendingMessages = getPendingMessages()

        guard !pendingMessages.isEmpty else {
            print("[CoTSync] No pending messages to process")
            return
        }

        print("[CoTSync] Processing \(pendingMessages.count) pending messages")

        var successCount = 0
        var failCount = 0

        for message in pendingMessages {
            let success = sendHandler(message.xmlContent)

            if success {
                updateMessageStatus(message.id, status: .sent)
                successCount += 1
            } else {
                updateMessageStatus(message.id, status: .failed)
                failCount += 1
            }
        }

        print("[CoTSync] Processed offline queue: \(successCount) sent, \(failCount) failed")
    }
}
