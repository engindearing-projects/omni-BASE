//
// PluginLoader.swift
// OmniTAK Plugin System
//
// Plugin loading, validation, and management
//

import Foundation

/// Plugin bundle structure (.omniplugin)
public struct PluginBundle {
    public let url: URL
    public let manifest: PluginManifest
    public let frameworkPath: URL
    public let signature: PluginSignature

    /// Load plugin bundle from URL
    public static func load(from url: URL) throws -> PluginBundle {
        // Verify bundle structure
        guard url.pathExtension == "omniplugin" else {
            throw PluginError.invalidManifest("Invalid bundle extension: expected .omniplugin")
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw PluginError.invalidManifest("Plugin bundle not found at \(url.path)")
        }

        // Load manifest
        let manifestURL = url.appendingPathComponent("manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw PluginError.invalidManifest("manifest.json not found in bundle")
        }

        let manifest = try PluginManifest.load(from: manifestURL)
        try manifest.validate()

        // Locate iOS framework
        let frameworkName = manifest.entryPoints["ios"] ?? manifest.id
        let frameworkPath = url.appendingPathComponent("ios/\(frameworkName).framework")

        guard FileManager.default.fileExists(atPath: frameworkPath.path) else {
            throw PluginError.invalidManifest("iOS framework not found: \(frameworkPath.path)")
        }

        // Load signature
        let signatureURL = url.appendingPathComponent("signature.json")
        guard FileManager.default.fileExists(atPath: signatureURL.path) else {
            throw PluginError.signatureInvalid("signature.json not found in bundle")
        }

        let signature = try PluginSignature.load(from: signatureURL)

        return PluginBundle(
            url: url,
            manifest: manifest,
            frameworkPath: frameworkPath,
            signature: signature
        )
    }
}

/// Plugin signature for verification
public struct PluginSignature: Codable {
    public let algorithm: String
    public let signature: String
    public let certificate: String
    public let timestamp: String

    /// Load signature from file
    public static func load(from url: URL) throws -> PluginSignature {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(PluginSignature.self, from: data)
    }

    /// Verify signature matches expected certificate
    public func verify(expectedCertificate: String) -> Bool {
        // TODO: Implement proper signature verification
        // For now, just check certificate matches
        return certificate == expectedCertificate
    }
}

/// Plugin validator
public class PluginValidator {
    /// Expected code signing certificate
    private let expectedCertificate: String

    /// OmniTAK version for compatibility checking
    private let omnitakVersion: PluginVersion

    public init(expectedCertificate: String, omnitakVersion: String) {
        self.expectedCertificate = expectedCertificate
        self.omnitakVersion = PluginVersion(omnitakVersion) ?? PluginVersion("1.0.0")!
    }

    /// Validate plugin bundle
    public func validate(_ bundle: PluginBundle) throws {
        // Validate manifest
        try bundle.manifest.validate()

        // Verify signature
        guard bundle.signature.verify(expectedCertificate: expectedCertificate) else {
            throw PluginError.signatureInvalid("Plugin signature does not match expected certificate")
        }

        // Check version compatibility
        try checkVersionCompatibility(bundle.manifest)

        // Verify framework exists and is loadable
        try verifyFramework(bundle.frameworkPath)
    }

    private func checkVersionCompatibility(_ manifest: PluginManifest) throws {
        // Parse version requirement (e.g., ">=1.0.0", "^1.2.0", "~1.0.0")
        let requirement = manifest.omnitakVersion

        if requirement.hasPrefix(">=") {
            let versionString = String(requirement.dropFirst(2))
            guard let minVersion = PluginVersion(versionString) else {
                throw PluginError.invalidManifest("Invalid version requirement: \(requirement)")
            }
            guard omnitakVersion >= minVersion else {
                throw PluginError.invalidManifest("Plugin requires OmniTAK \(requirement), but current version is \(omnitakVersion)")
            }
        } else if requirement.hasPrefix("^") {
            // Caret: compatible with version (same major version)
            let versionString = String(requirement.dropFirst(1))
            guard let targetVersion = PluginVersion(versionString) else {
                throw PluginError.invalidManifest("Invalid version requirement: \(requirement)")
            }
            guard omnitakVersion.major == targetVersion.major && omnitakVersion >= targetVersion else {
                throw PluginError.invalidManifest("Plugin requires compatible OmniTAK version \(requirement)")
            }
        } else if requirement.hasPrefix("~") {
            // Tilde: compatible with minor version
            let versionString = String(requirement.dropFirst(1))
            guard let targetVersion = PluginVersion(versionString) else {
                throw PluginError.invalidManifest("Invalid version requirement: \(requirement)")
            }
            guard omnitakVersion.major == targetVersion.major &&
                  omnitakVersion.minor == targetVersion.minor &&
                  omnitakVersion >= targetVersion else {
                throw PluginError.invalidManifest("Plugin requires compatible OmniTAK version \(requirement)")
            }
        } else {
            // Exact version
            guard let targetVersion = PluginVersion(requirement) else {
                throw PluginError.invalidManifest("Invalid version requirement: \(requirement)")
            }
            guard omnitakVersion == targetVersion else {
                throw PluginError.invalidManifest("Plugin requires exact OmniTAK version \(requirement)")
            }
        }
    }

    private func verifyFramework(_ frameworkPath: URL) throws {
        // Check framework structure
        let executableName = frameworkPath.deletingPathExtension().lastPathComponent
        let executablePath = frameworkPath.appendingPathComponent(executableName)

        guard FileManager.default.fileExists(atPath: executablePath.path) else {
            throw PluginError.invalidManifest("Framework executable not found: \(executablePath.path)")
        }

        // TODO: Verify framework code signature
        // TODO: Check framework architecture compatibility
    }
}

/// Plugin loader - dynamically loads plugin frameworks
public class PluginLoader {
    private let validator: PluginValidator
    private let permissionChecker: DefaultPermissionChecker
    private var loadedPlugins: [String: PluginInstance] = [:]

    public init(validator: PluginValidator, permissionChecker: DefaultPermissionChecker) {
        self.validator = validator
        self.permissionChecker = permissionChecker
    }

    /// Load plugin from bundle URL
    public func loadPlugin(from url: URL) throws -> PluginInstance {
        // Load and validate bundle
        let bundle = try PluginBundle.load(from: url)
        try validator.validate(bundle)

        // Check if already loaded
        if let existing = loadedPlugins[bundle.manifest.id] {
            return existing
        }

        // Load framework dynamically
        guard let frameworkBundle = Bundle(url: bundle.frameworkPath) else {
            throw PluginError.initializationFailed("Failed to load framework bundle")
        }

        // Load and instantiate plugin class
        let className = bundle.manifest.entryPoints["ios"] ?? bundle.manifest.id
        guard let pluginClass = frameworkBundle.principalClass as? OmniTAKPlugin.Type else {
            throw PluginError.initializationFailed("Failed to load plugin class: \(className)")
        }

        let plugin = pluginClass.init()

        // Create plugin context
        let permissions = try PluginPermissionSet(from: bundle.manifest.permissions)
        let storage = try FilePluginStorage(pluginId: bundle.manifest.id)
        let logger = ConsolePluginLogger(pluginId: bundle.manifest.id)

        let context = PluginContext(
            pluginId: bundle.manifest.id,
            permissions: permissions,
            storage: storage,
            logger: logger,
            permissionChecker: permissionChecker
        )

        // Grant permissions
        permissionChecker.grantPermissions(permissions, forPlugin: bundle.manifest.id)

        // Create plugin instance
        let instance = PluginInstance(
            manifest: bundle.manifest,
            plugin: plugin,
            context: context
        )

        loadedPlugins[bundle.manifest.id] = instance
        return instance
    }

    /// Unload plugin
    public func unloadPlugin(id: String) throws {
        guard let instance = loadedPlugins[id] else {
            throw PluginError.runtimeError("Plugin not loaded: \(id)")
        }

        try instance.cleanup()
        permissionChecker.revokePermissions(forPlugin: id)
        loadedPlugins.removeValue(forKey: id)
    }

    /// Get loaded plugin
    public func getPlugin(id: String) -> PluginInstance? {
        return loadedPlugins[id]
    }

    /// Get all loaded plugins
    public func getAllPlugins() -> [PluginInstance] {
        return Array(loadedPlugins.values)
    }
}

/// Plugin manager - high-level plugin management
public class PluginManager {
    private let loader: PluginLoader
    private let pluginsDirectory: URL
    private var enabledPlugins: Set<String> = []

    public init(loader: PluginLoader, pluginsDirectory: URL) throws {
        self.loader = loader
        self.pluginsDirectory = pluginsDirectory

        // Create plugins directory if needed
        try FileManager.default.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true)

        // Load enabled plugins list
        loadEnabledPlugins()
    }

    /// Install plugin from bundle
    public func installPlugin(from sourceURL: URL) throws -> PluginInstance {
        // Load and validate
        let bundle = try PluginBundle.load(from: sourceURL)

        // Copy to plugins directory
        let destURL = pluginsDirectory.appendingPathComponent(bundle.manifest.id + ".omniplugin")

        // Remove existing if present
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destURL)

        // Load plugin
        return try loader.loadPlugin(from: destURL)
    }

    /// Uninstall plugin
    public func uninstallPlugin(id: String) throws {
        // Unload if loaded
        try? loader.unloadPlugin(id: id)

        // Remove from enabled list
        enabledPlugins.remove(id)
        saveEnabledPlugins()

        // Remove plugin bundle
        let pluginURL = pluginsDirectory.appendingPathComponent(id + ".omniplugin")
        if FileManager.default.fileExists(atPath: pluginURL.path) {
            try FileManager.default.removeItem(at: pluginURL)
        }
    }

    /// Enable plugin
    public func enablePlugin(id: String) throws {
        guard let instance = loader.getPlugin(id: id) else {
            throw PluginError.runtimeError("Plugin not loaded: \(id)")
        }

        if case .loaded = instance.state {
            try instance.initialize()
        }

        try instance.activate()
        enabledPlugins.insert(id)
        saveEnabledPlugins()
    }

    /// Disable plugin
    public func disablePlugin(id: String) throws {
        guard let instance = loader.getPlugin(id: id) else {
            throw PluginError.runtimeError("Plugin not loaded: \(id)")
        }

        try instance.deactivate()
        enabledPlugins.remove(id)
        saveEnabledPlugins()
    }

    /// Check if plugin is enabled
    public func isEnabled(id: String) -> Bool {
        return enabledPlugins.contains(id)
    }

    /// Discover and load all installed plugins
    public func discoverPlugins() throws {
        let contents = try FileManager.default.contentsOfDirectory(
            at: pluginsDirectory,
            includingPropertiesForKeys: nil
        )

        for url in contents where url.pathExtension == "omniplugin" {
            do {
                let instance = try loader.loadPlugin(from: url)

                // Auto-enable if in enabled list
                if enabledPlugins.contains(instance.manifest.id) {
                    try? enablePlugin(id: instance.manifest.id)
                }
            } catch {
                print("Failed to load plugin at \(url): \(error)")
            }
        }
    }

    private func loadEnabledPlugins() {
        let prefsURL = pluginsDirectory.appendingPathComponent("enabled.json")
        guard let data = try? Data(contentsOf: prefsURL),
              let list = try? JSONDecoder().decode([String].self, from: data) else {
            return
        }
        enabledPlugins = Set(list)
    }

    private func saveEnabledPlugins() {
        let prefsURL = pluginsDirectory.appendingPathComponent("enabled.json")
        let list = Array(enabledPlugins)
        if let data = try? JSONEncoder().encode(list) {
            try? data.write(to: prefsURL)
        }
    }
}
