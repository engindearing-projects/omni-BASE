//
// OmniTAKPlugin.swift
// OmniTAK Plugin System
//
// Core plugin protocol and lifecycle management
//

import Foundation
import UIKit

/// Main plugin protocol that all OmniTAK plugins must implement
public protocol OmniTAKPlugin: AnyObject {
    /// Plugin manifest
    var manifest: PluginManifest { get }

    /// Initialize plugin with context
    /// Called once when plugin is loaded
    func initialize(context: PluginContext) throws

    /// Activate plugin
    /// Called when plugin is enabled by user
    func activate() throws

    /// Deactivate plugin
    /// Called when plugin is disabled by user
    func deactivate() throws

    /// Cleanup plugin resources
    /// Called before plugin is unloaded
    func cleanup() throws
}

/// Plugin context provides access to OmniTAK APIs
public class PluginContext {
    /// Plugin identifier
    public let pluginId: String

    /// Granted permissions
    public let permissions: PluginPermissionSet

    /// Plugin-specific storage
    public let storage: PluginStorage

    /// Plugin logger
    public let logger: PluginLogger

    /// Permission checker for runtime validation
    private let permissionChecker: PluginPermissionChecker

    // API managers (available based on permissions)
    private var _cotManager: CoTManager?
    private var _mapManager: MapManager?
    private var _networkManager: NetworkManager?
    private var _locationManager: LocationManager?
    private var _uiManager: UIManager?

    public init(
        pluginId: String,
        permissions: PluginPermissionSet,
        storage: PluginStorage,
        logger: PluginLogger,
        permissionChecker: PluginPermissionChecker
    ) {
        self.pluginId = pluginId
        self.permissions = permissions
        self.storage = storage
        self.logger = logger
        self.permissionChecker = permissionChecker
    }

    /// Get CoT manager (requires cot.read or cot.write permission)
    public var cotManager: CoTManager? {
        get throws {
            if _cotManager == nil {
                if permissions.has(.cotRead) || permissions.has(.cotWrite) {
                    _cotManager = CoTManager(context: self)
                } else {
                    throw PluginError.permissionDenied("CoT access requires cot.read or cot.write permission")
                }
            }
            return _cotManager
        }
    }

    /// Get map manager (requires map.read or map.write permission)
    public var mapManager: MapManager? {
        get throws {
            if _mapManager == nil {
                if permissions.has(.mapRead) || permissions.has(.mapWrite) {
                    _mapManager = MapManager(context: self)
                } else {
                    throw PluginError.permissionDenied("Map access requires map.read or map.write permission")
                }
            }
            return _mapManager
        }
    }

    /// Get network manager (requires network.access permission)
    public var networkManager: NetworkManager? {
        get throws {
            if _networkManager == nil {
                if permissions.has(.networkAccess) {
                    _networkManager = NetworkManager(context: self)
                } else {
                    throw PluginError.permissionDenied("Network access requires network.access permission")
                }
            }
            return _networkManager
        }
    }

    /// Get location manager (requires location.read or location.write permission)
    public var locationManager: LocationManager? {
        get throws {
            if _locationManager == nil {
                if permissions.has(.locationRead) || permissions.has(.locationWrite) {
                    _locationManager = LocationManager(context: self)
                } else {
                    throw PluginError.permissionDenied("Location access requires location.read or location.write permission")
                }
            }
            return _locationManager
        }
    }

    /// Get UI manager (requires ui.create permission)
    public var uiManager: UIManager? {
        get throws {
            if _uiManager == nil {
                if permissions.has(.uiCreate) {
                    _uiManager = UIManager(context: self)
                } else {
                    throw PluginError.permissionDenied("UI creation requires ui.create permission")
                }
            }
            return _uiManager
        }
    }
}

/// Plugin storage for persistent data
public protocol PluginStorage {
    func get(_ key: String) -> Data?
    func set(_ key: String, value: Data) throws
    func remove(_ key: String) throws
    func clear() throws
    func keys() -> [String]
}

/// Plugin logger for debugging and monitoring
public protocol PluginLogger {
    func debug(_ message: String)
    func info(_ message: String)
    func warning(_ message: String)
    func error(_ message: String)
    func error(_ message: String, error: Error)
}

/// Default file-based plugin storage implementation
public class FilePluginStorage: PluginStorage {
    private let directory: URL

    public init(pluginId: String) throws {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.directory = documentsDir.appendingPathComponent("plugins/\(pluginId)/storage")

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func fileURL(for key: String) -> URL {
        // Sanitize key to prevent path traversal
        let sanitized = key.replacingOccurrences(of: "/", with: "_")
        return directory.appendingPathComponent(sanitized)
    }

    public func get(_ key: String) -> Data? {
        let url = fileURL(for: key)
        return try? Data(contentsOf: url)
    }

    public func set(_ key: String, value: Data) throws {
        let url = fileURL(for: key)
        try value.write(to: url)
    }

    public func remove(_ key: String) throws {
        let url = fileURL(for: key)
        try FileManager.default.removeItem(at: url)
    }

    public func clear() throws {
        let contents = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for url in contents {
            try FileManager.default.removeItem(at: url)
        }
    }

    public func keys() -> [String] {
        let contents = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return contents.map { $0.lastPathComponent }
    }
}

/// Default console logger implementation
public class ConsolePluginLogger: PluginLogger {
    private let pluginId: String

    public init(pluginId: String) {
        self.pluginId = pluginId
    }

    private func log(_ level: String, _ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] [\(level)] [Plugin:\(pluginId)] \(message)")
    }

    public func debug(_ message: String) {
        log("DEBUG", message)
    }

    public func info(_ message: String) {
        log("INFO", message)
    }

    public func warning(_ message: String) {
        log("WARN", message)
    }

    public func error(_ message: String) {
        log("ERROR", message)
    }

    public func error(_ message: String, error: Error) {
        log("ERROR", "\(message): \(error.localizedDescription)")
    }
}

/// Plugin lifecycle state
public enum PluginState {
    case unloaded
    case loaded
    case initialized
    case active
    case inactive
    case error(Error)
}

/// Plugin instance wrapper
public class PluginInstance {
    public let manifest: PluginManifest
    public let plugin: OmniTAKPlugin
    public let context: PluginContext
    public private(set) var state: PluginState

    public init(manifest: PluginManifest, plugin: OmniTAKPlugin, context: PluginContext) {
        self.manifest = manifest
        self.plugin = plugin
        self.context = context
        self.state = .loaded
    }

    public func initialize() throws {
        guard case .loaded = state else {
            throw PluginError.runtimeError("Plugin must be in loaded state to initialize")
        }

        do {
            try plugin.initialize(context: context)
            state = .initialized
            context.logger.info("Plugin initialized successfully")
        } catch {
            state = .error(error)
            context.logger.error("Plugin initialization failed", error: error)
            throw error
        }
    }

    public func activate() throws {
        guard case .initialized = state else {
            throw PluginError.runtimeError("Plugin must be initialized before activation")
        }

        do {
            try plugin.activate()
            state = .active
            context.logger.info("Plugin activated")
        } catch {
            state = .error(error)
            context.logger.error("Plugin activation failed", error: error)
            throw error
        }
    }

    public func deactivate() throws {
        guard case .active = state else {
            throw PluginError.runtimeError("Plugin must be active to deactivate")
        }

        do {
            try plugin.deactivate()
            state = .inactive
            context.logger.info("Plugin deactivated")
        } catch {
            state = .error(error)
            context.logger.error("Plugin deactivation failed", error: error)
            throw error
        }
    }

    public func cleanup() throws {
        do {
            try plugin.cleanup()
            state = .unloaded
            context.logger.info("Plugin cleaned up")
        } catch {
            state = .error(error)
            context.logger.error("Plugin cleanup failed", error: error)
            throw error
        }
    }
}
