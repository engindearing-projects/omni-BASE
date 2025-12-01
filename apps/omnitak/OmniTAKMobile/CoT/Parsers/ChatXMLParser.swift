//
//  ChatXMLParser.swift
//  OmniTAKTest
//
//  Parse incoming GeoChat CoT messages, extract sender, recipient, message text
//

import Foundation
import UIKit

class ChatXMLParser {

    // Parse a GeoChat message from CoT XML
    static func parseGeoChatMessage(xml: String) -> ChatMessage? {
        // Check if this is a GeoChat message (type="b-t-f")
        guard xml.contains("type=\"b-t-f\"") else {
            return nil
        }

        // DEBUG: Log raw chat XML for diagnosis
        #if DEBUG
        print("🔍 [CHAT DEBUG] ========== RAW CHAT XML ==========")
        print(xml)
        print("🔍 [CHAT DEBUG] ========== END RAW XML ==========")
        #endif

        // Extract message UID - this is the unique message identifier
        guard let eventUid = extractAttribute("uid", from: xml) else {
            print("❌ [CHAT DEBUG] Failed to extract UID from GeoChat message")
            return nil
        }
        #if DEBUG
        print("✅ [CHAT DEBUG] Event UID: \(eventUid)")
        #endif

        // Use event UID as the message ID (it's unique per message)
        // Format is typically: GeoChat.SENDER_UID.MESSAGE_ID
        let messageId = eventUid

        // Extract chat details from __chat element
        // Try multiple formats: __chat, _chat, chat
        var senderCallsign = extractChatAttribute("senderCallsign", from: xml)
        var chatroom = extractChatAttribute("chatroom", from: xml)

        // Also check the id attribute for chatroom (ATAK puts chatroom name here)
        if chatroom == nil {
            chatroom = extractChatAttribute("id", from: xml)
        }

        // Try alternate chat element formats if __chat didn't work
        if senderCallsign == nil {
            #if DEBUG
            print("⚠️ [CHAT DEBUG] __chat parsing failed, trying alternate formats...")
            print("⚠️ [CHAT DEBUG] Has __chat element: \(xml.contains("<__chat"))")
            print("⚠️ [CHAT DEBUG] Has _chat element: \(xml.contains("<_chat"))")
            print("⚠️ [CHAT DEBUG] Has chat element: \(xml.contains("<chat "))")
            #endif

            // Try _chat element (single underscore)
            if let altSender = extractAltChatAttribute("senderCallsign", elementName: "_chat", from: xml) {
                senderCallsign = altSender
            }
            if let altChatroom = extractAltChatAttribute("chatroom", elementName: "_chat", from: xml) {
                chatroom = altChatroom
            }
            if chatroom == nil {
                chatroom = extractAltChatAttribute("id", elementName: "_chat", from: xml)
            }
        }

        #if DEBUG
        print("✅ [CHAT DEBUG] Message ID: \(messageId)")
        print("✅ [CHAT DEBUG] Chatroom: \(chatroom ?? "nil")")
        #endif

        guard let senderCallsign = senderCallsign else {
            print("❌ [CHAT DEBUG] Failed to extract sender callsign")
            // Try to get callsign from link element as fallback
            if let linkCallsign = extractLinkAttribute("parent_callsign", from: xml) {
                #if DEBUG
                print("🔄 [CHAT DEBUG] Using link parent_callsign as fallback: \(linkCallsign)")
                #endif
            }
            return nil
        }
        #if DEBUG
        print("✅ [CHAT DEBUG] Sender callsign: \(senderCallsign)")
        print("✅ [CHAT DEBUG] Chatroom: \(chatroom ?? "nil")")
        #endif

        // Extract sender UID from chatgrp or link element
        var senderUid: String?
        if let uid0 = extractChatgrpAttribute("uid0", from: xml) {
            senderUid = uid0
            #if DEBUG
            print("✅ [CHAT DEBUG] Sender UID from chatgrp uid0: \(uid0)")
            #endif
        } else if let linkUid = extractLinkAttribute("uid", from: xml) {
            senderUid = linkUid
            #if DEBUG
            print("✅ [CHAT DEBUG] Sender UID from link uid: \(linkUid)")
            #endif
        } else {
            // Try to extract from event UID (GeoChat.SENDER_UID.MESSAGE_ID format)
            if eventUid.hasPrefix("GeoChat.") {
                let parts = eventUid.split(separator: ".")
                if parts.count >= 2 {
                    senderUid = String(parts[1])
                    #if DEBUG
                    print("🔄 [CHAT DEBUG] Extracted sender UID from event UID: \(senderUid ?? "nil")")
                    #endif
                }
            }
        }

        guard let senderId = senderUid else {
            print("❌ [CHAT DEBUG] Failed to extract sender UID - no chatgrp uid0 or link uid found")
            #if DEBUG
            print("⚠️ [CHAT DEBUG] Has chatgrp element: \(xml.contains("<chatgrp"))")
            print("⚠️ [CHAT DEBUG] Has link element: \(xml.contains("<link "))")
            #endif
            return nil
        }

        // Extract message text from remarks element
        guard let messageText = extractRemarksContent(from: xml) else {
            print("❌ [CHAT DEBUG] Failed to extract message text - no remarks element")
            #if DEBUG
            print("⚠️ [CHAT DEBUG] Has remarks element: \(xml.contains("<remarks"))")
            #endif
            return nil
        }
        #if DEBUG
        print("✅ [CHAT DEBUG] Message text: \(messageText)")
        #endif

        // Extract timestamp
        let timestamp = extractTimestamp(from: xml) ?? Date()

        // Determine if this is a group message or direct message
        // ATAK uses "All Chat Rooms" for group chat
        let chatroomLower = chatroom?.lowercased() ?? ""
        let isGroupChat = chatroom == ChatRoom.allUsersTitle ||
                          chatroom == ChatRoom.atakChatroomName ||
                          chatroom == "All Chat Users" ||
                          chatroom == "All Chat Rooms" ||
                          chatroomLower.contains("all chat") ||
                          chatroomLower == "broadcast" ||
                          chatroom == nil ||
                          chatroom?.isEmpty == true

        #if DEBUG
        print("🔍 [CHAT DEBUG] Group chat detection: chatroom='\(chatroom ?? "nil")' -> isGroupChat=\(isGroupChat)")
        #endif

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

        // Parse image attachment if present
        let (attachmentType, imageAttachment) = parseFileshareElement(from: xml, messageId: messageId)

        let message = ChatMessage(
            id: messageId,
            conversationId: conversationId,
            senderId: senderId,
            senderCallsign: senderCallsign,
            recipientId: recipientId,
            recipientCallsign: recipientCallsign,
            messageText: messageText,
            timestamp: timestamp,
            status: .delivered,
            type: .geochat,
            isFromSelf: false,
            attachmentType: attachmentType,
            imageAttachment: imageAttachment
        )

        if imageAttachment != nil {
            print("Parsed GeoChat message with image from \(senderCallsign): \(messageText)")
        } else {
            print("Parsed GeoChat message from \(senderCallsign): \(messageText)")
        }
        return message
    }

    // Parse fileshare element for image attachments
    private static func parseFileshareElement(from xml: String, messageId: String) -> (AttachmentType, ImageAttachment?) {
        // Look for fileshare element
        guard let fileshareRange = xml.range(of: "<fileshare[^>]+/>", options: .regularExpression) else {
            return (.none, nil)
        }

        let fileshareTag = String(xml[fileshareRange])

        // Extract filename
        guard let filename = extractAttribute("filename", from: fileshareTag) else {
            return (.none, nil)
        }

        // Check if it's an image file
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic", "webp"]
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        guard imageExtensions.contains(fileExtension) else {
            return (.file, nil) // It's a file but not an image
        }

        // Extract other attributes
        let senderUrl = extractAttribute("senderUrl", from: fileshareTag) ?? ""
        let sizeString = extractAttribute("size", from: fileshareTag) ?? "0"
        let fileSize = Int(sizeString) ?? 0
        let mimeType = extractAttribute("mimeType", from: fileshareTag) ?? "image/jpeg"

        // Parse senderUrl for base64 or remote URL
        var base64Data: String?
        var remoteURL: String?

        if senderUrl.hasPrefix("base64:") {
            base64Data = String(senderUrl.dropFirst(7)) // Remove "base64:" prefix
        } else if senderUrl.hasPrefix("http://") || senderUrl.hasPrefix("https://") {
            remoteURL = senderUrl
        } else if senderUrl.hasPrefix("local:") {
            // Local reference - we don't have access to sender's local files
            // The image will be unavailable unless we have base64 data
        }

        // If we have base64 data, save it locally
        var localPath: String?
        var thumbnailPath: String?

        if let base64 = base64Data,
           let imageData = Data(base64Encoded: base64),
           let image = UIImage(data: imageData) {
            if let paths = PhotoAttachmentService.shared.saveImage(image, for: messageId) {
                localPath = paths.localPath
                thumbnailPath = paths.thumbnailPath
            }
        }

        let attachment = ImageAttachment(
            id: messageId,
            filename: filename,
            mimeType: mimeType,
            fileSize: fileSize,
            localPath: localPath,
            thumbnailPath: thumbnailPath,
            base64Data: base64Data,
            remoteURL: remoteURL
        )

        return (.image, attachment)
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
        // Extract attributes from __chat element (handle both <__chat ...> and <__chat .../> formats)
        // Try opening tag first
        if let chatRange = xml.range(of: "<__chat[^>]+>", options: .regularExpression) {
            let chatTag = String(xml[chatRange])
            if let value = extractAttribute(name, from: chatTag) {
                return value
            }
        }
        // Try self-closing tag
        if let chatRange = xml.range(of: "<__chat[^/]*/?>", options: .regularExpression) {
            let chatTag = String(xml[chatRange])
            return extractAttribute(name, from: chatTag)
        }
        return nil
    }

    private static func extractAltChatAttribute(_ name: String, elementName: String, from xml: String) -> String? {
        // Extract attributes from alternate chat element formats (_chat, chat, etc.)
        guard let chatRange = xml.range(of: "<\(elementName)[^>]+>", options: .regularExpression) else {
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
        guard let startRange = xml.range(of: "<remarks[^>]*>", options: .regularExpression),
              let endRange = xml.range(of: "</remarks>") else {
            #if DEBUG
            print("⚠️ [CHAT DEBUG] Remarks extraction failed - checking format...")
            if let remarksSnippet = xml.range(of: "<remarks") {
                let start = remarksSnippet.lowerBound
                let end = xml.index(start, offsetBy: min(200, xml.distance(from: start, to: xml.endIndex)))
                print("⚠️ [CHAT DEBUG] Remarks element snippet: \(xml[start..<end])")
            }
            #endif
            return nil
        }

        let startIndex = startRange.upperBound
        let endIndex = endRange.lowerBound

        guard startIndex < endIndex else {
            #if DEBUG
            print("⚠️ [CHAT DEBUG] Remarks element is empty (startIndex >= endIndex)")
            #endif
            return nil
        }

        let content = String(xml[startIndex..<endIndex])

        #if DEBUG
        print("✅ [CHAT DEBUG] Extracted remarks content: \(content)")
        #endif

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
            #if DEBUG
            print("⚠️ [PRESENCE DEBUG] No UID found in presence message")
            #endif
            return nil
        }

        // Extract callsign from contact element
        // Try self-closing tag first: <contact ... />
        var contactTag: String?
        if let contactRange = xml.range(of: "<contact[^>]+/>", options: .regularExpression) {
            contactTag = String(xml[contactRange])
        }
        // Try opening tag: <contact ...>
        if contactTag == nil, let contactRange = xml.range(of: "<contact[^>]+>", options: .regularExpression) {
            contactTag = String(xml[contactRange])
        }

        guard let contactTag = contactTag else {
            #if DEBUG
            print("⚠️ [PRESENCE DEBUG] No <contact> element found for UID: \(uid)")
            #endif
            return nil
        }

        guard let callsign = extractAttribute("callsign", from: contactTag) else {
            #if DEBUG
            print("⚠️ [PRESENCE DEBUG] No callsign attribute in contact element for UID: \(uid)")
            #endif
            return nil
        }

        // Extract endpoint if available
        let endpoint = extractAttribute("endpoint", from: contactTag)

        // Extract timestamp
        let lastSeen = extractTimestamp(from: xml) ?? Date()

        #if DEBUG
        print("✅ [PRESENCE DEBUG] Parsed participant: \(callsign) (UID: \(uid))")
        #endif

        return ChatParticipant(
            id: uid,
            callsign: callsign,
            endpoint: endpoint,
            lastSeen: lastSeen,
            isOnline: true
        )
    }
}
