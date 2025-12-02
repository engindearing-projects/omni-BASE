//
//  MeshtasticTCPClient.swift
//  OmniTAK Mobile
//
//  Pure Swift TCP client for Meshtastic device communication
//  Implements the Meshtastic streaming protocol over TCP
//

import Foundation
import Network

// MARK: - Protocol Constants

private enum MeshtasticProtocol {
    static let startByte1: UInt8 = 0x94
    static let startByte2: UInt8 = 0xC3
    static let headerSize = 4
    static let maxPacketSize = 512
    static let defaultPort: UInt16 = 4403
}

// MARK: - TCP Client Delegate

protocol MeshtasticTCPClientDelegate: AnyObject {
    func tcpClient(_ client: MeshtasticTCPClient, didConnect host: String, port: UInt16)
    func tcpClient(_ client: MeshtasticTCPClient, didDisconnect error: Error?)
    func tcpClient(_ client: MeshtasticTCPClient, didReceiveNodeInfo node: MeshNode)
    func tcpClient(_ client: MeshtasticTCPClient, didReceivePosition nodeId: UInt32, position: MeshPosition)
    func tcpClient(_ client: MeshtasticTCPClient, didReceiveMessage from: UInt32, text: String)
    func tcpClient(_ client: MeshtasticTCPClient, didUpdateMyInfo nodeNum: UInt32, firmwareVersion: String)
    func tcpClient(_ client: MeshtasticTCPClient, didReceiveError message: String)
}

// MARK: - MeshtasticTCPClient

@available(iOS 13.0, *)
class MeshtasticTCPClient: ObservableObject {

    // MARK: - Published State

    @Published var isConnected: Bool = false
    @Published var connectionState: ConnectionState = .disconnected
    @Published var myNodeNum: UInt32 = 0
    @Published var firmwareVersion: String = ""
    @Published var nodes: [UInt32: MeshNode] = [:]
    @Published var lastError: String?

    enum ConnectionState: String {
        case disconnected = "Disconnected"
        case connecting = "Connecting..."
        case connected = "Connected"
        case failed = "Connection Failed"
    }

    // MARK: - Properties

    weak var delegate: MeshtasticTCPClientDelegate?

    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "com.omnitak.meshtastic.tcp", qos: .userInitiated)
    private var receiveBuffer = Data()
    private var host: String = ""
    private var port: UInt16 = MeshtasticProtocol.defaultPort

    // MARK: - Connection Management

    func connect(host: String, port: UInt16 = MeshtasticProtocol.defaultPort) {
        self.host = host
        self.port = port

        DispatchQueue.main.async {
            self.connectionState = .connecting
            self.lastError = nil
        }

        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = 10
        tcpOptions.enableKeepalive = true
        tcpOptions.keepaliveIdle = 30

        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.prohibitedInterfaceTypes = [.cellular]

        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )

        connection = NWConnection(to: endpoint, using: parameters)

        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }

        connection?.start(queue: queue)
    }

    func disconnect() {
        connection?.cancel()
        connection = nil

        DispatchQueue.main.async {
            self.isConnected = false
            self.connectionState = .disconnected
            self.nodes.removeAll()
        }

        delegate?.tcpClient(self, didDisconnect: nil)
    }

    // MARK: - State Handling

    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            DispatchQueue.main.async {
                self.isConnected = true
                self.connectionState = .connected
            }
            delegate?.tcpClient(self, didConnect: host, port: port)
            startReceiving()
            // Delay config request slightly to ensure connection is fully ready
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.requestConfig()
            }

        case .failed(let error):
            DispatchQueue.main.async {
                self.isConnected = false
                self.connectionState = .failed
                self.lastError = error.localizedDescription
            }
            delegate?.tcpClient(self, didDisconnect: error)

        case .cancelled:
            DispatchQueue.main.async {
                self.isConnected = false
                self.connectionState = .disconnected
            }

        case .waiting(let error):
            DispatchQueue.main.async {
                self.lastError = "Waiting: \(error.localizedDescription)"
            }

        default:
            break
        }
    }

    // MARK: - Receiving Data

    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self = self else { return }

            if let data = content {
                self.receiveBuffer.append(data)
                self.processBuffer()
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.lastError = error.localizedDescription
                }
                return
            }

            if isComplete {
                self.disconnect()
            } else {
                self.startReceiving()
            }
        }
    }

    private func processBuffer() {
        // Process all complete packets in the buffer
        while true {
            // Need at least 4 bytes for header
            guard receiveBuffer.count >= MeshtasticProtocol.headerSize else { break }

            // Safe access using first/dropFirst pattern
            let bytes = Array(receiveBuffer.prefix(4))
            guard bytes.count == 4 else { break }

            // Check for magic bytes
            guard bytes[0] == MeshtasticProtocol.startByte1,
                  bytes[1] == MeshtasticProtocol.startByte2 else {
                // Invalid header, skip a byte
                if !receiveBuffer.isEmpty {
                    receiveBuffer.removeFirst()
                }
                continue
            }

            // Read length (big endian)
            let payloadLength = Int(UInt16(bytes[2]) << 8 | UInt16(bytes[3]))

            // Sanity check
            guard payloadLength > 0, payloadLength <= MeshtasticProtocol.maxPacketSize else {
                if !receiveBuffer.isEmpty {
                    receiveBuffer.removeFirst()
                }
                continue
            }

            // Wait for full packet
            let totalLength = MeshtasticProtocol.headerSize + payloadLength
            guard receiveBuffer.count >= totalLength else { break }

            // Extract payload safely
            let payload = receiveBuffer.prefix(totalLength).dropFirst(MeshtasticProtocol.headerSize)
            let payloadData = Data(payload)

            // Remove processed bytes
            receiveBuffer.removeFirst(totalLength)

            // Parse protobuf
            parseFromRadio(payloadData)
        }
    }

    // MARK: - Protobuf Parsing (Simplified)

    private func parseFromRadio(_ data: Data) {
        // Parse FromRadio protobuf message
        // Field numbers based on meshtastic.proto:
        // 1: packet_id (uint32)
        // 2: MeshPacket
        // 5: MyNodeInfo
        // 6: NodeInfo
        // 7: Config
        // 11: Metadata

        guard !data.isEmpty else { return }

        var index = 0
        while index < data.count {
            guard index < data.count else { break }

            let tag = data[index]
            let fieldNumber = (tag >> 3)
            let wireType = (tag & 0x07)
            index += 1

            switch fieldNumber {
            case 5: // my_info
                if let (info, newIndex) = parseMyNodeInfo(data, from: index, wireType: wireType) {
                    index = newIndex
                    DispatchQueue.main.async {
                        self.myNodeNum = info.nodeNum
                        self.firmwareVersion = info.firmwareVersion
                    }
                    delegate?.tcpClient(self, didUpdateMyInfo: info.nodeNum, firmwareVersion: info.firmwareVersion)
                } else {
                    index = skipField(data, from: index, wireType: wireType)
                }

            case 6: // node_info
                if let (node, newIndex) = parseNodeInfo(data, from: index, wireType: wireType) {
                    index = newIndex
                    DispatchQueue.main.async {
                        self.nodes[node.id] = node
                    }
                    delegate?.tcpClient(self, didReceiveNodeInfo: node)
                } else {
                    index = skipField(data, from: index, wireType: wireType)
                }

            case 2: // packet (MeshPacket)
                if let (packet, newIndex) = parseMeshPacket(data, from: index, wireType: wireType) {
                    index = newIndex
                    handleMeshPacket(packet)
                } else {
                    index = skipField(data, from: index, wireType: wireType)
                }

            default:
                index = skipField(data, from: index, wireType: wireType)
            }
        }
    }

    private func parseMyNodeInfo(_ data: Data, from index: Int, wireType: UInt8) -> ((nodeNum: UInt32, firmwareVersion: String), Int)? {
        guard wireType == 2 else { return nil } // Length-delimited

        guard let (length, lengthEnd) = readVarint(data, from: index) else { return nil }
        let messageEnd = min(lengthEnd + Int(length), data.count)

        var nodeNum: UInt32 = 0
        let firmware = "Unknown"
        var idx = lengthEnd

        while idx < messageEnd {
            guard idx < data.count else { break }
            let tag = data[idx]
            let field = (tag >> 3)
            let wire = (tag & 0x07)
            idx += 1

            switch field {
            case 1: // my_node_num
                if wire == 0, let (val, newIdx) = readVarint(data, from: idx) {
                    nodeNum = UInt32(val)
                    idx = min(newIdx, messageEnd)
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            default:
                idx = skipField(data, from: idx, wireType: wire)
            }
        }

        return ((nodeNum, firmware), messageEnd)
    }

    private func parseNodeInfo(_ data: Data, from index: Int, wireType: UInt8) -> (MeshNode, Int)? {
        guard wireType == 2 else { return nil }

        guard let (length, lengthEnd) = readVarint(data, from: index) else { return nil }
        let messageEnd = min(lengthEnd + Int(length), data.count)

        var nodeNum: UInt32 = 0
        var shortName = ""
        var longName = ""
        var snr: Double? = nil
        var lastHeard: Date? = nil
        let position: MeshPosition? = nil
        var hopDistance: Int? = nil

        var idx = lengthEnd

        while idx < messageEnd {
            guard idx < data.count else { break }
            let tag = data[idx]
            let field = (tag >> 3)
            let wire = (tag & 0x07)
            idx += 1

            switch field {
            case 1: // num
                if wire == 0, let (val, newIdx) = readVarint(data, from: idx) {
                    nodeNum = UInt32(val)
                    idx = min(newIdx, messageEnd)
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            case 2: // user (sub-message)
                if wire == 2, let (len, lenEnd) = readVarint(data, from: idx) {
                    let userEnd = min(lenEnd + Int(len), data.count)
                    // Parse user sub-message for names
                    var uIdx = lenEnd
                    while uIdx < userEnd {
                        guard uIdx < data.count else { break }
                        let uTag = data[uIdx]
                        let uField = (uTag >> 3)
                        let uWire = (uTag & 0x07)
                        uIdx += 1

                        if uField == 2 && uWire == 2 { // long_name
                            if let (str, newIdx) = readString(data, from: uIdx) {
                                longName = str
                                uIdx = min(newIdx, userEnd)
                            } else {
                                uIdx = skipField(data, from: uIdx, wireType: uWire)
                            }
                        } else if uField == 3 && uWire == 2 { // short_name
                            if let (str, newIdx) = readString(data, from: uIdx) {
                                shortName = str
                                uIdx = min(newIdx, userEnd)
                            } else {
                                uIdx = skipField(data, from: uIdx, wireType: uWire)
                            }
                        } else {
                            uIdx = skipField(data, from: uIdx, wireType: uWire)
                        }
                    }
                    idx = userEnd
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            case 5: // snr
                if wire == 5 && idx + 4 <= data.count {
                    let floatBits = UInt32(data[idx]) | (UInt32(data[idx+1]) << 8) | (UInt32(data[idx+2]) << 16) | (UInt32(data[idx+3]) << 24)
                    snr = Double(Float(bitPattern: floatBits))
                    idx += 4
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            case 6: // last_heard
                if wire == 0, let (val, newIdx) = readVarint(data, from: idx) {
                    lastHeard = Date(timeIntervalSince1970: Double(val))
                    idx = newIdx
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            case 7: // hops_away
                if wire == 0, let (val, newIdx) = readVarint(data, from: idx) {
                    hopDistance = Int(val)
                    idx = newIdx
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            default:
                idx = skipField(data, from: idx, wireType: wire)
            }
        }

        let node = MeshNode(
            id: nodeNum,
            shortName: shortName.isEmpty ? String(format: "%04X", nodeNum & 0xFFFF) : shortName,
            longName: longName.isEmpty ? "Node \(String(format: "%08X", nodeNum))" : longName,
            position: position,
            lastHeard: lastHeard ?? Date(),
            snr: snr,
            hopDistance: hopDistance,
            batteryLevel: nil
        )

        return (node, messageEnd)
    }

    private func parseMeshPacket(_ data: Data, from index: Int, wireType: UInt8) -> ((from: UInt32, to: UInt32, portNum: Int, payload: Data), Int)? {
        guard wireType == 2 else { return nil }

        guard let (length, lengthEnd) = readVarint(data, from: index) else { return nil }
        let messageEnd = min(lengthEnd + Int(length), data.count)
        guard messageEnd <= data.count else { return nil }

        var fromNode: UInt32 = 0
        var toNode: UInt32 = 0
        var portNum = 0
        var payload = Data()

        var idx = lengthEnd

        while idx < messageEnd {
            guard idx < data.count else { break }
            let tag = data[idx]
            let field = (tag >> 3)
            let wire = (tag & 0x07)
            idx += 1

            switch field {
            case 1: // from
                if wire == 5 && idx + 4 <= data.count {
                    fromNode = UInt32(data[idx]) | (UInt32(data[idx+1]) << 8) | (UInt32(data[idx+2]) << 16) | (UInt32(data[idx+3]) << 24)
                    idx += 4
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            case 2: // to
                if wire == 5 && idx + 4 <= data.count {
                    toNode = UInt32(data[idx]) | (UInt32(data[idx+1]) << 8) | (UInt32(data[idx+2]) << 16) | (UInt32(data[idx+3]) << 24)
                    idx += 4
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            case 4: // decoded (Data message)
                if wire == 2, let (len, lenEnd) = readVarint(data, from: idx) {
                    let dataEnd = min(lenEnd + Int(len), data.count)
                    // Parse Data sub-message
                    var dIdx = lenEnd
                    while dIdx < dataEnd {
                        guard dIdx < data.count else { break }
                        let dTag = data[dIdx]
                        let dField = (dTag >> 3)
                        let dWire = (dTag & 0x07)
                        dIdx += 1

                        if dField == 1 && dWire == 0 { // portnum
                            if let (val, newIdx) = readVarint(data, from: dIdx) {
                                portNum = Int(val)
                                dIdx = min(newIdx, dataEnd)
                            } else {
                                dIdx = skipField(data, from: dIdx, wireType: dWire)
                            }
                        } else if dField == 2 && dWire == 2 { // payload
                            if let (len2, len2End) = readVarint(data, from: dIdx) {
                                let payloadEnd = min(len2End + Int(len2), data.count)
                                payload = data.subdata(in: len2End..<payloadEnd)
                                dIdx = payloadEnd
                            } else {
                                dIdx = skipField(data, from: dIdx, wireType: dWire)
                            }
                        } else {
                            dIdx = skipField(data, from: dIdx, wireType: dWire)
                        }
                    }
                    idx = dataEnd
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            default:
                idx = skipField(data, from: idx, wireType: wire)
            }
        }

        return ((fromNode, toNode, portNum, payload), messageEnd)
    }

    private func handleMeshPacket(_ packet: (from: UInt32, to: UInt32, portNum: Int, payload: Data)) {
        // Port numbers from Meshtastic:
        // 1 = TEXT_MESSAGE_APP
        // 3 = POSITION_APP
        // 4 = NODEINFO_APP
        // 72 = ATAK_PLUGIN
        // 257 = ATAK_FORWARDER

        switch packet.portNum {
        case 1: // Text message
            if let text = String(data: packet.payload, encoding: .utf8) {
                delegate?.tcpClient(self, didReceiveMessage: packet.from, text: text)
            }

        case 3: // Position
            if let position = parsePositionPayload(packet.payload) {
                DispatchQueue.main.async {
                    if var node = self.nodes[packet.from] {
                        node.position = position
                        self.nodes[packet.from] = node
                    }
                }
                delegate?.tcpClient(self, didReceivePosition: packet.from, position: position)
            }

        default:
            break
        }
    }

    private func parsePositionPayload(_ data: Data) -> MeshPosition? {
        guard !data.isEmpty else { return nil }

        var lat: Double = 0
        var lon: Double = 0
        var alt: Int? = nil

        var idx = 0
        while idx < data.count {
            guard idx < data.count else { break }
            let tag = data[idx]
            let field = (tag >> 3)
            let wire = (tag & 0x07)
            idx += 1

            switch field {
            case 1: // latitude_i (sfixed32)
                if wire == 5 && idx + 4 <= data.count {
                    let bits = UInt32(data[idx]) | (UInt32(data[idx+1]) << 8) | (UInt32(data[idx+2]) << 16) | (UInt32(data[idx+3]) << 24)
                    lat = Double(Int32(bitPattern: bits)) / 1e7
                    idx += 4
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            case 2: // longitude_i (sfixed32)
                if wire == 5 && idx + 4 <= data.count {
                    let bits = UInt32(data[idx]) | (UInt32(data[idx+1]) << 8) | (UInt32(data[idx+2]) << 16) | (UInt32(data[idx+3]) << 24)
                    lon = Double(Int32(bitPattern: bits)) / 1e7
                    idx += 4
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            case 3: // altitude
                if wire == 0, let (val, newIdx) = readVarint(data, from: idx) {
                    alt = Int(Int32(bitPattern: UInt32(val)))
                    idx = newIdx
                } else {
                    idx = skipField(data, from: idx, wireType: wire)
                }
            default:
                idx = skipField(data, from: idx, wireType: wire)
            }
        }

        guard lat != 0 || lon != 0 else { return nil }
        return MeshPosition(latitude: lat, longitude: lon, altitude: alt)
    }

    // MARK: - Sending Data

    func requestConfig() {
        // Send ToRadio with want_config_id to request device configuration
        // Field 3: want_config_id (uint32)
        sendToRadio(buildWantConfig())
    }

    func sendTextMessage(_ text: String, to destination: UInt32 = 0xFFFFFFFF) {
        // Build a text message packet
        let packet = buildTextMessage(text, to: destination)
        sendToRadio(packet)
    }

    private func buildWantConfig() -> Data {
        // ToRadio message with want_config_id = random
        var data = Data()

        // Field 3: want_config_id (uint32)
        let configId = UInt32.random(in: 1...UInt32.max)
        data.append(0x18) // Tag: field 3, wire type 0 (varint)
        appendVarint(&data, UInt64(configId))

        return data
    }

    private func buildTextMessage(_ text: String, to destination: UInt32) -> Data {
        var data = Data()

        // ToRadio.packet (field 1, wire type 2)
        // MeshPacket structure

        var meshPacket = Data()

        // to (field 2, fixed32)
        meshPacket.append(0x15) // Tag: field 2, wire type 5
        meshPacket.append(contentsOf: withUnsafeBytes(of: destination.littleEndian) { Array($0) })

        // decoded (field 4, sub-message)
        var decoded = Data()

        // portnum = 1 (TEXT_MESSAGE_APP)
        decoded.append(0x08) // Tag: field 1, wire type 0
        appendVarint(&decoded, 1)

        // payload = text
        if let textData = text.data(using: .utf8) {
            decoded.append(0x12) // Tag: field 2, wire type 2
            appendVarint(&decoded, UInt64(textData.count))
            decoded.append(textData)
        }

        meshPacket.append(0x22) // Tag: field 4, wire type 2
        appendVarint(&meshPacket, UInt64(decoded.count))
        meshPacket.append(decoded)

        // want_ack = true (field 10)
        meshPacket.append(0x50) // Tag: field 10, wire type 0
        meshPacket.append(0x01)

        // Wrap in ToRadio
        data.append(0x0A) // Tag: field 1, wire type 2
        appendVarint(&data, UInt64(meshPacket.count))
        data.append(meshPacket)

        return data
    }

    private func sendToRadio(_ payload: Data) {
        guard let connection = connection else { return }

        // Build frame with header
        var frame = Data()
        frame.append(MeshtasticProtocol.startByte1)
        frame.append(MeshtasticProtocol.startByte2)
        frame.append(UInt8((payload.count >> 8) & 0xFF))
        frame.append(UInt8(payload.count & 0xFF))
        frame.append(payload)

        connection.send(content: frame, completion: .contentProcessed { [weak self] error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.lastError = "Send error: \(error.localizedDescription)"
                }
            }
        })
    }

    // MARK: - Protobuf Helpers

    private func readVarint(_ data: Data, from index: Int) -> (UInt64, Int)? {
        var result: UInt64 = 0
        var shift = 0
        var idx = index

        while idx < data.count {
            let byte = data[idx]
            idx += 1
            result |= UInt64(byte & 0x7F) << shift

            if byte & 0x80 == 0 {
                return (result, idx)
            }

            shift += 7
            if shift >= 64 { return nil }
        }

        return nil
    }

    private func readString(_ data: Data, from index: Int) -> (String, Int)? {
        guard let (length, lengthEnd) = readVarint(data, from: index) else { return nil }
        let stringEnd = lengthEnd + Int(length)
        guard stringEnd <= data.count else { return nil }

        let stringData = data.subdata(in: lengthEnd..<stringEnd)
        guard let str = String(data: stringData, encoding: .utf8) else { return nil }

        return (str, stringEnd)
    }

    private func appendVarint(_ data: inout Data, _ value: UInt64) {
        var v = value
        while v > 0x7F {
            data.append(UInt8((v & 0x7F) | 0x80))
            v >>= 7
        }
        data.append(UInt8(v))
    }

    private func skipField(_ data: Data, from index: Int, wireType: UInt8) -> Int {
        guard index < data.count else { return data.count }

        switch wireType {
        case 0: // Varint
            if let (_, newIdx) = readVarint(data, from: index) {
                return min(newIdx, data.count)
            }
            return min(index + 1, data.count)

        case 1: // 64-bit
            return min(index + 8, data.count)

        case 2: // Length-delimited
            if let (length, lengthEnd) = readVarint(data, from: index) {
                return min(lengthEnd + Int(length), data.count)
            }
            return min(index + 1, data.count)

        case 5: // 32-bit
            return min(index + 4, data.count)

        default:
            return min(index + 1, data.count)
        }
    }
}
