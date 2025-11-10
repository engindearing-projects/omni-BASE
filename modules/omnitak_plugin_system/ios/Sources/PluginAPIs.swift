//
// PluginAPIs.swift
// OmniTAK Plugin System
//
// API managers that provide controlled access to OmniTAK functionality
//

import Foundation
import CoreLocation
import UIKit

// MARK: - CoT Manager

/// CoT (Cursor-on-Target) message structure
public struct CoTMessage {
    public let uid: String
    public let type: String
    public let time: Date
    public let start: Date
    public let stale: Date
    public let point: CoTPoint
    public let detail: [String: Any]

    public struct CoTPoint {
        public let lat: Double
        public let lon: Double
        public let hae: Double
        public let ce: Double
        public let le: Double
    }
}

/// CoT message handler protocol
public protocol CoTHandler: AnyObject {
    func handleCoTMessage(_ message: CoTMessage) -> CoTHandlerResult
}

/// Result of CoT message handling
public enum CoTHandlerResult {
    case processed
    case passthrough
    case blocked
}

/// Manager for CoT message access
public class CoTManager {
    private weak var context: PluginContext?
    private var handlers: [CoTHandler] = []

    public init(context: PluginContext) {
        self.context = context
    }

    /// Register handler for incoming CoT messages (requires cot.read)
    public func registerHandler(_ handler: CoTHandler) throws {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.cotRead) ? () : { throw PluginError.permissionDenied("cot.read required") }()
        handlers.append(handler)
        context.logger.info("CoT handler registered")
    }

    /// Send CoT message (requires cot.write)
    public func sendMessage(_ message: CoTMessage) throws {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.cotWrite) ? () : { throw PluginError.permissionDenied("cot.write required") }()

        // TODO: Integrate with actual OmniTAK CoT sending mechanism
        context.logger.info("CoT message sent: \(message.uid)")
    }

    /// Query recent CoT messages (requires cot.read)
    public func queryMessages(filter: CoTFilter) throws -> [CoTMessage] {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.cotRead) ? () : { throw PluginError.permissionDenied("cot.read required") }()

        // TODO: Integrate with actual OmniTAK CoT storage
        context.logger.debug("Querying CoT messages with filter")
        return []
    }
}

/// Filter for querying CoT messages
public struct CoTFilter {
    public let types: [String]?
    public let uids: [String]?
    public let timeRange: (start: Date, end: Date)?
    public let boundingBox: (minLat: Double, minLon: Double, maxLat: Double, maxLon: Double)?

    public init(
        types: [String]? = nil,
        uids: [String]? = nil,
        timeRange: (Date, Date)? = nil,
        boundingBox: (Double, Double, Double, Double)? = nil
    ) {
        self.types = types
        self.uids = uids
        self.timeRange = timeRange
        self.boundingBox = boundingBox
    }
}

// MARK: - Map Manager

/// Map layer protocol for custom overlays
public protocol MapLayer: AnyObject {
    var id: String { get }
    var visible: Bool { get set }
    var opacity: Float { get set }

    func render() -> UIView?
}

/// Map marker
public struct MapMarker {
    public let id: String
    public let coordinate: CLLocationCoordinate2D
    public let title: String?
    public let snippet: String?
    public let icon: UIImage?
    public let metadata: [String: Any]?

    public init(
        id: String,
        coordinate: CLLocationCoordinate2D,
        title: String? = nil,
        snippet: String? = nil,
        icon: UIImage? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.id = id
        self.coordinate = coordinate
        self.title = title
        self.snippet = snippet
        self.icon = icon
        self.metadata = metadata
    }
}

/// Manager for map interaction
public class MapManager {
    private weak var context: PluginContext?
    private var layers: [String: MapLayer] = [:]
    private var markers: [String: MapMarker] = [:]

    public init(context: PluginContext) {
        self.context = context
    }

    /// Add custom map layer (requires map.write)
    public func addLayer(_ layer: MapLayer) throws {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.mapWrite) ? () : { throw PluginError.permissionDenied("map.write required") }()

        layers[layer.id] = layer
        context.logger.info("Map layer added: \(layer.id)")

        // TODO: Integrate with actual MapLibre view
    }

    /// Remove map layer (requires map.write)
    public func removeLayer(id: String) throws {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.mapWrite) ? () : { throw PluginError.permissionDenied("map.write required") }()

        layers.removeValue(forKey: id)
        context.logger.info("Map layer removed: \(id)")

        // TODO: Integrate with actual MapLibre view
    }

    /// Add marker to map (requires map.write)
    public func addMarker(_ marker: MapMarker) throws {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.mapWrite) ? () : { throw PluginError.permissionDenied("map.write required") }()

        markers[marker.id] = marker
        context.logger.info("Map marker added: \(marker.id)")

        // TODO: Integrate with actual MapLibre view
    }

    /// Remove marker from map (requires map.write)
    public func removeMarker(id: String) throws {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.mapWrite) ? () : { throw PluginError.permissionDenied("map.write required") }()

        markers.removeValue(forKey: id)
        context.logger.info("Map marker removed: \(id)")

        // TODO: Integrate with actual MapLibre view
    }

    /// Get current map center (requires map.read)
    public func getMapCenter() throws -> CLLocationCoordinate2D {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.mapRead) ? () : { throw PluginError.permissionDenied("map.read required") }()

        // TODO: Integrate with actual MapLibre view
        return CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    /// Get current map zoom level (requires map.read)
    public func getZoomLevel() throws -> Double {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.mapRead) ? () : { throw PluginError.permissionDenied("map.read required") }()

        // TODO: Integrate with actual MapLibre view
        return 1.0
    }
}

// MARK: - Network Manager

/// Manager for network requests
public class NetworkManager {
    private weak var context: PluginContext?

    public init(context: PluginContext) {
        self.context = context
    }

    /// Make HTTP request (requires network.access)
    public func request(url: URL, method: String = "GET", headers: [String: String]? = nil, body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.networkAccess) ? () : { throw PluginError.permissionDenied("network.access required") }()

        context.logger.debug("Making \(method) request to \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = method
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw PluginError.runtimeError("Invalid response type")
        }

        context.logger.debug("Request completed with status \(httpResponse.statusCode)")
        return (data, httpResponse)
    }
}

// MARK: - Location Manager

/// Manager for location access
public class LocationManager {
    private weak var context: PluginContext?

    public init(context: PluginContext) {
        self.context = context
    }

    /// Get current location (requires location.read)
    public func getCurrentLocation() throws -> CLLocation {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.locationRead) ? () : { throw PluginError.permissionDenied("location.read required") }()

        // TODO: Integrate with actual location manager
        context.logger.debug("Getting current location")
        return CLLocation(latitude: 0, longitude: 0)
    }

    /// Update location (requires location.write)
    public func updateLocation(_ location: CLLocation) throws {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.locationWrite) ? () : { throw PluginError.permissionDenied("location.write required") }()

        // TODO: Integrate with actual location manager
        context.logger.info("Location updated: \(location.coordinate)")
    }
}

// MARK: - UI Manager

/// UI provider protocol for plugin UI components
public protocol UIProvider: AnyObject {
    func createToolbarItem() -> UIView?
    func createPanel() -> UIViewController?
    func createSettingsView() -> UIView?
}

/// Manager for UI creation
public class UIManager {
    private weak var context: PluginContext?
    private var toolbarItems: [UIView] = []
    private var panels: [UIViewController] = []

    public init(context: PluginContext) {
        self.context = context
    }

    /// Register UI provider (requires ui.create)
    public func registerProvider(_ provider: UIProvider) throws {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.uiCreate) ? () : { throw PluginError.permissionDenied("ui.create required") }()

        if let toolbar = provider.createToolbarItem() {
            toolbarItems.append(toolbar)
            context.logger.info("Toolbar item registered")
        }

        if let panel = provider.createPanel() {
            panels.append(panel)
            context.logger.info("Panel registered")
        }

        // TODO: Integrate with actual UI system
    }

    /// Show alert dialog (requires ui.create)
    public func showAlert(title: String, message: String, actions: [(String, () -> Void)]) throws {
        guard let context = context else { throw PluginError.runtimeError("Context not available") }
        try context.permissions.has(.uiCreate) ? () : { throw PluginError.permissionDenied("ui.create required") }()

        context.logger.info("Showing alert: \(title)")

        // TODO: Integrate with actual UI system to show alert
    }
}
