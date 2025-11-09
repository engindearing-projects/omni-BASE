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
        let destinations: String

        if isGroupChat {
            // Group chat - send to "All Chat Users"
            chatroom = groupName ?? ChatRoom.allUsersTitle
            destinations = """
                <dest callsign="\(chatroom)"/>
            """
        } else if let recipientCallsign = message.recipientCallsign {
            // Direct message
            chatroom = recipientCallsign
            destinations = """
                <dest callsign="\(recipientCallsign)"/>
            """
        } else {
            // Default to All Chat Users
            chatroom = ChatRoom.allUsersTitle
            destinations = """
                <dest callsign="\(chatroom)"/>
            """
        }

        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <event version="2.0" uid="GeoChat.\(senderUid).\(messageId)" type="b-t-f" time="\(now)" start="\(now)" stale="\(stale)" how="h-g-i-g-o">
            <point lat="\(lat)" lon="\(lon)" hae="\(hae)" ce="\(ce)" le="\(le)"/>
            <detail>
                <__chat id="\(messageId)" chatroom="\(chatroom)" senderCallsign="\(senderCallsign)" parent="RootContactGroup">
                    <chatgrp uid0="\(senderUid)" uid1="\(chatroom)" id="\(chatroom)"/>
                </__chat>
                <link uid="\(senderUid)" production_time="\(now)" type="a-f-G-E-S" parent_callsign="\(senderCallsign)" relation="p-p"/>
                <remarks source="BAO.F.ATAK.\(senderUid)" to="\(chatroom)" time="\(now)">\(message.messageText)</remarks>
                <__serverdestination destinations="\(destinations)"/>
                <marti>
                    <dest callsign="\(chatroom)"/>
                </marti>
            </detail>
        </event>
        """

        return xml
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
                <takv device="iPhone" platform="OmniTAK" os="iOS" version="1.0.0"/>
                <track speed="\(location.speed)" course="\(location.course)"/>
            </detail>
        </event>
        """

        return xml
    }
}
