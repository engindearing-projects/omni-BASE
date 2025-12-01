//
//  ChatXMLGenerator.swift
//  OmniTAKTest
//
//  Generate TAK GeoChat XML (b-t-f format) for group and direct messages
//

import Foundation
import CoreLocation

class ChatXMLGenerator {

    // Generate GeoChat XML for a chat message
    static func generateGeoChatXML(
        message: ChatMessage,
        senderUid: String,
        senderCallsign: String,
        location: CLLocation?,
        isGroupChat: Bool = false,
        groupName: String? = nil
    ) -> String {
        let messageId = message.id
        let now = ISO8601DateFormatter().string(from: Date())
        let stale = ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)) // 1 hour

        // Use current location or default
        let lat = location?.coordinate.latitude ?? 0.0
        let lon = location?.coordinate.longitude ?? 0.0
        let hae = location?.altitude ?? 0.0
        let ce = location?.horizontalAccuracy ?? 999999.0
        let le = location?.verticalAccuracy ?? 999999.0

        // Determine chatroom and recipients
        let chatroom: String
        let martiElement: String

        if isGroupChat {
            // Group chat - use ATAK's expected chatroom name for interoperability
            // No marti destination for broadcast - server routes to all
            chatroom = ChatRoom.atakChatroomName
            martiElement = ""
        } else if let recipientCallsign = message.recipientCallsign {
            // Direct message - need marti destination for routing
            chatroom = recipientCallsign
            martiElement = """

                    <marti>
                        <dest callsign="\(recipientCallsign)"/>
                    </marti>
            """
        } else {
            // Default to group chat
            chatroom = ChatRoom.atakChatroomName
            martiElement = ""
        }

        // Build fileshare element if image attachment present
        let fileshareElement = generateFileshareElement(for: message)

        // For group chat, uid1 should be "All Chat Rooms" (the chatroom)
        // For direct message, uid1 should be the recipient's UID
        let chatgrpUid1 = isGroupChat ? chatroom : (message.recipientId ?? chatroom)

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <event version="2.0" uid="GeoChat.\(senderUid).\(chatroom).\(messageId)" type="b-t-f" time="\(now)" start="\(now)" stale="\(stale)" how="h-g-i-g-o">
            <point lat="\(lat)" lon="\(lon)" hae="\(hae)" ce="\(ce)" le="\(le)"/>
            <detail>
                <__chat id="\(chatroom)" chatroom="\(chatroom)" senderCallsign="\(senderCallsign)" groupOwner="false">
                    <chatgrp uid0="\(senderUid)" uid1="\(chatgrpUid1)" id="\(chatroom)"/>
                </__chat>
                <link uid="\(senderUid)" production_time="\(now)" type="a-f-G-U-C" parent_callsign="\(senderCallsign)" relation="p-p"/>
                <remarks source="BAO.F.ATAK.\(senderUid)" to="\(chatroom)" time="\(now)">\(escapeXML(message.messageText))</remarks>\(fileshareElement)\(martiElement)
            </detail>
        </event>
        """

        return xml
    }

    // Generate fileshare element for image attachments
    static func generateFileshareElement(for message: ChatMessage) -> String {
        guard message.hasImage,
              let attachment = message.imageAttachment else {
            return ""
        }

        // Build senderUrl - prefer base64 for inline, otherwise use remote URL
        let senderUrl: String
        if let base64Data = attachment.base64Data {
            senderUrl = "base64:\(base64Data)"
        } else if let remoteURL = attachment.remoteURL {
            senderUrl = remoteURL
        } else {
            // Fallback to local path reference
            senderUrl = "local:\(attachment.localPath ?? attachment.filename)"
        }

        let fileshareXML = """

                <fileshare filename="\(escapeXML(attachment.filename))" senderUrl="\(senderUrl)" size="\(attachment.fileSize)" sha256="" senderUid="\(message.senderId)" senderCallsign="\(escapeXML(message.senderCallsign))" name="\(escapeXML(attachment.filename))" mimeType="\(attachment.mimeType)"/>
        """

        return fileshareXML
    }

    // Generate GeoChat XML specifically for image messages
    static func generateImageGeoChatXML(
        message: ChatMessage,
        senderUid: String,
        senderCallsign: String,
        location: CLLocation?,
        isGroupChat: Bool = false,
        groupName: String? = nil
    ) -> String {
        // Use the standard generator which now supports attachments
        return generateGeoChatXML(
            message: message,
            senderUid: senderUid,
            senderCallsign: senderCallsign,
            location: location,
            isGroupChat: isGroupChat,
            groupName: groupName
        )
    }

    // Escape special XML characters
    static func escapeXML(_ string: String) -> String {
        var escaped = string
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        escaped = escaped.replacingOccurrences(of: "'", with: "&apos;")
        return escaped
    }

    // Generate presence CoT with chat endpoint information
    static func generatePresenceWithChatEndpoint(
        uid: String,
        callsign: String,
        location: CLLocation,
        endpoint: String = "*:-1:stcp"
    ) -> String {
        let now = ISO8601DateFormatter().string(from: Date())
        let stale = ISO8601DateFormatter().string(from: Date().addingTimeInterval(300)) // 5 minutes

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <event version="2.0" uid="\(uid)" type="a-f-G-E-S" how="m-g" time="\(now)" start="\(now)" stale="\(stale)">
            <point lat="\(location.coordinate.latitude)" lon="\(location.coordinate.longitude)" hae="\(location.altitude)" ce="\(location.horizontalAccuracy)" le="\(location.verticalAccuracy)"/>
            <detail>
                <contact callsign="\(callsign)" endpoint="\(endpoint)"/>
                <__group name="Cyan" role="Team Member"/>
                <status battery="100"/>
                <takv device="iPhone" platform="OmniTAK" os="iOS" version="\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0.0")"/>
                <track speed="\(location.speed)" course="\(location.course)"/>
            </detail>
        </event>
        """

        return xml
    }
}
