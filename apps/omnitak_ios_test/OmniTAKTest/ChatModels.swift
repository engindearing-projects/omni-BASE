//
//  ChatModels.swift
//  OmniTAKTest
//
//  TAK GeoChat data models
//

import Foundation

// MARK: - Chat Message Status

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case failed
}

// MARK: - Chat Message Type

enum ChatMessageType: String, Codable {
    case text
    case geochat
    case system
}

// MARK: - Chat Participant

struct ChatParticipant: Identifiable, Codable, Equatable, Hashable {
    let id: String // UID from CoT
    var callsign: String
    var endpoint: String? // IP:port:protocol for direct messages
    var lastSeen: Date
    var isOnline: Bool

    init(id: String, callsign: String, endpoint: String? = nil, lastSeen: Date = Date(), isOnline: Bool = true) {
        self.id = id
        self.callsign = callsign
        self.endpoint = endpoint
        self.lastSeen = lastSeen
        self.isOnline = isOnline
    }

    static func == (lhs: ChatParticipant, rhs: ChatParticipant) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Chat Message

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: String // Message UID
    let conversationId: String
    let senderId: String // Sender UID
    let senderCallsign: String
    var recipientId: String? // nil for group messages
    var recipientCallsign: String?
    let messageText: String
    let timestamp: Date
    var status: MessageStatus
    let type: ChatMessageType
    var isFromSelf: Bool

    init(
        id: String = UUID().uuidString,
        conversationId: String,
        senderId: String,
        senderCallsign: String,
        recipientId: String? = nil,
        recipientCallsign: String? = nil,
        messageText: String,
        timestamp: Date = Date(),
        status: MessageStatus = .sending,
        type: ChatMessageType = .geochat,
        isFromSelf: Bool = false
    ) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.senderCallsign = senderCallsign
        self.recipientId = recipientId
        self.recipientCallsign = recipientCallsign
        self.messageText = messageText
        self.timestamp = timestamp
        self.status = status
        self.type = type
        self.isFromSelf = isFromSelf
    }
}

// MARK: - Conversation

struct Conversation: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var participants: [ChatParticipant]
    var lastMessage: ChatMessage?
    var unreadCount: Int
    var isGroupChat: Bool
    var lastActivity: Date

    init(
        id: String = UUID().uuidString,
        title: String,
        participants: [ChatParticipant] = [],
        lastMessage: ChatMessage? = nil,
        unreadCount: Int = 0,
        isGroupChat: Bool = false,
        lastActivity: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.participants = participants
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.isGroupChat = isGroupChat
        self.lastActivity = lastActivity
    }

    // Get the display title for the conversation
    var displayTitle: String {
        if isGroupChat {
            return title
        } else if let participant = participants.first {
            return participant.callsign
        } else {
            return title
        }
    }

    // Get the other participant in a direct conversation
    func otherParticipant(excludingId: String) -> ChatParticipant? {
        return participants.first { $0.id != excludingId }
    }
}

// MARK: - Chat Room (All Users)

struct ChatRoom {
    static let allUsersId = "All Chat Users"
    static let allUsersTitle = "All Chat Users"

    static func createAllUsersConversation() -> Conversation {
        return Conversation(
            id: allUsersId,
            title: allUsersTitle,
            participants: [],
            isGroupChat: true
        )
    }
}
