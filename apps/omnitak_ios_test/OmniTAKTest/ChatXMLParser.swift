//
//  ChatXMLParser.swift
//  OmniTAKTest
//
//  Parse incoming GeoChat CoT messages, extract sender, recipient, message text
//

import Foundation

class ChatXMLParser {

    // Parse a GeoChat message from CoT XML
    static func parseGeoChatMessage(xml: String) -> ChatMessage? {
        // Check if this is a GeoChat message (type="b-t-f")
        guard xml.contains("type=\"b-t-f\"") else {
            return nil
        }

        // Extract message UID
        guard let uid = extractAttribute("uid", from: xml) else {
            print("Failed to extract UID from GeoChat message")
            return nil
        }

        // Extract chat details from __chat element
        guard let chatId = extractChatAttribute("id", from: xml) else {
            print("Failed to extract chat ID")
            return nil
        }

        guard let senderCallsign = extractChatAttribute("senderCallsign", from: xml) else {
            print("Failed to extract sender callsign")
            return nil
        }

        let chatroom = extractChatAttribute("chatroom", from: xml)

        // Extract sender UID from chatgrp or link element
        var senderUid: String?
        if let uid0 = extractChatgrpAttribute("uid0", from: xml) {
            senderUid = uid0
        } else if let linkUid = extractLinkAttribute("uid", from: xml) {
            senderUid = linkUid
        }

        guard let senderId = senderUid else {
            print("Failed to extract sender UID")
            return nil
        }

        // Extract message text from remarks element
        guard let messageText = extractRemarksContent(from: xml) else {
            print("Failed to extract message text")
            return nil
        }

        // Extract timestamp
        let timestamp = extractTimestamp(from: xml) ?? Date()

        // Determine if this is a group message or direct message
        let isGroupChat = chatroom == ChatRoom.allUsersTitle || chatroom == "All Chat Users"

        // Extract recipient info (for direct messages)
        var recipientCallsign: String?
        var recipientId: String?

        if !isGroupChat, let chatroom = chatroom {
            recipientCallsign = chatroom
            if let uid1 = extractChatgrpAttribute("uid1", from: xml), uid1 != chatroom {
                recipientId = uid1
            }
        }

        // Create conversation ID
        let conversationId: String
        if isGroupChat {
            conversationId = ChatRoom.allUsersId
        } else {
            // For direct messages, use a consistent ID based on both participants
            conversationId = createDirectConversationId(uid1: senderId, uid2: recipientId ?? chatroom ?? "")
        }

        let message = ChatMessage(
            id: chatId,
            conversationId: conversationId,
            senderId: senderId,
            senderCallsign: senderCallsign,
            recipientId: recipientId,
            recipientCallsign: recipientCallsign,
            messageText: messageText,
            timestamp: timestamp,
            status: .delivered,
            type: .geochat,
            isFromSelf: false
        )

        print("Parsed GeoChat message from \(senderCallsign): \(messageText)")
        return message
    }

    // MARK: - Helper Functions

    private static func extractAttribute(_ name: String, from xml: String) -> String? {
        guard let range = xml.range(of: "\(name)=\"([^\"]+)\"", options: .regularExpression) else {
            return nil
        }
        let parts = xml[range].split(separator: "\"")
        return parts.count > 1 ? String(parts[1]) : nil
    }

    private static func extractChatAttribute(_ name: String, from xml: String) -> String? {
        // Extract attributes from __chat element
        guard let chatRange = xml.range(of: "<__chat[^>]+>", options: .regularExpression) else {
            return nil
        }
        let chatTag = String(xml[chatRange])
        return extractAttribute(name, from: chatTag)
    }

    private static func extractChatgrpAttribute(_ name: String, from xml: String) -> String? {
        // Extract attributes from chatgrp element
        guard let chatgrpRange = xml.range(of: "<chatgrp[^>]+/>", options: .regularExpression) else {
            return nil
        }
        let chatgrpTag = String(xml[chatgrpRange])
        return extractAttribute(name, from: chatgrpTag)
    }

    private static func extractLinkAttribute(_ name: String, from xml: String) -> String? {
        // Extract attributes from link element
        guard let linkRange = xml.range(of: "<link[^>]+/>", options: .regularExpression) else {
            return nil
        }
        let linkTag = String(xml[linkRange])
        return extractAttribute(name, from: linkTag)
    }

    private static func extractRemarksContent(from xml: String) -> String? {
        // Extract content from <remarks>...</remarks>
        guard let startRange = xml.range(of: "<remarks[^>]*>"),
              let endRange = xml.range(of: "</remarks>") else {
            return nil
        }

        let startIndex = xml.index(startRange.upperBound, offsetBy: 0)
        let endIndex = endRange.lowerBound

        guard startIndex < endIndex else {
            return nil
        }

        let content = String(xml[startIndex..<endIndex])

        // Decode XML entities
        return content
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
    }

    private static func extractTimestamp(from xml: String) -> Date? {
        guard let timeStr = extractAttribute("time", from: xml) else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timeStr)
    }

    private static func createDirectConversationId(uid1: String, uid2: String) -> String {
        // Create a consistent conversation ID for direct messages
        // Sort UIDs to ensure the same ID regardless of sender/recipient order
        let sorted = [uid1, uid2].sorted()
        return "DM-\(sorted[0])-\(sorted[1])"
    }

    // Parse participant information from presence CoT
    static func parseParticipantFromPresence(xml: String) -> ChatParticipant? {
        // Extract UID
        guard let uid = extractAttribute("uid", from: xml) else {
            return nil
        }

        // Extract callsign from contact element
        guard let contactRange = xml.range(of: "<contact[^>]+/>", options: .regularExpression) else {
            return nil
        }
        let contactTag = String(xml[contactRange])
        guard let callsign = extractAttribute("callsign", from: contactTag) else {
            return nil
        }

        // Extract endpoint if available
        let endpoint = extractAttribute("endpoint", from: contactTag)

        // Extract timestamp
        let lastSeen = extractTimestamp(from: xml) ?? Date()

        return ChatParticipant(
            id: uid,
            callsign: callsign,
            endpoint: endpoint,
            lastSeen: lastSeen,
            isOnline: true
        )
    }
}
