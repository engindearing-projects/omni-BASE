//
// PluginManifest.swift
// OmniTAK Plugin System
//
// Defines the plugin manifest structure for loading and validating plugins
//

import Foundation

/// Plugin manifest loaded from plugin.json
public struct PluginManifest: Codable {
    /// Unique plugin identifier (reverse DNS format)
    public let id: String

    /// Human-readable plugin name
    public let name: String

    /// Semantic version (e.g., "1.0.0")
    public let version: String

    /// Plugin description
    public let description: String

    /// Plugin author name
    public let author: String

    /// License identifier (e.g., "MIT", "Apache-2.0")
    public let license: String

    /// Minimum OmniTAK version required (e.g., ">=1.0.0")
    public let omnitakVersion: String

    /// Plugin type
    public let type: PluginType

    /// Supported platforms
    public let platforms: [String]

    /// Required permissions
    public let permissions: [String]

    /// Platform-specific entry points
    public let entryPoints: [String: String]

    /// Plugin dependencies (other plugin IDs)
    public let dependencies: [String]

    /// Optional metadata
    public let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case version
        case description
        case author
        case license
        case omnitakVersion = "omnitak_version"
        case type
        case platforms
        case permissions
        case entryPoints = "entry_points"
        case dependencies
        case metadata
    }

    /// Parse manifest from JSON data
    public static func parse(from data: Data) throws -> PluginManifest {
        let decoder = JSONDecoder()
        return try decoder.decode(PluginManifest.self, from: data)
    }

    /// Load manifest from file URL
    public static func load(from url: URL) throws -> PluginManifest {
        let data = try Data(contentsOf: url)
        return try parse(from: data)
    }

    /// Validate manifest structure and values
    public func validate() throws {
        // Validate ID format (reverse DNS)
        let idPattern = "^[a-z][a-z0-9]*(\\.[a-z][a-z0-9]*)+$"
        guard id.range(of: idPattern, options: .regularExpression) != nil else {
            throw PluginError.invalidManifest("Invalid plugin ID format: \(id)")
        }

        // Validate version format (semantic versioning)
        let versionPattern = "^\\d+\\.\\d+\\.\\d+(-[a-zA-Z0-9]+)?$"
        guard version.range(of: versionPattern, options: .regularExpression) != nil else {
            throw PluginError.invalidManifest("Invalid version format: \(version)")
        }

        // Validate iOS is supported
        guard platforms.contains("ios") else {
            throw PluginError.platformNotSupported("iOS not in supported platforms")
        }

        // Validate iOS entry point exists
        guard entryPoints["ios"] != nil else {
            throw PluginError.invalidManifest("Missing iOS entry point")
        }

        // Validate permissions
        for permission in permissions {
            guard PluginPermission.isValid(permission) else {
                throw PluginError.invalidManifest("Invalid permission: \(permission)")
            }
        }
    }
}

/// Plugin type classification
public enum PluginType: String, Codable {
    case ui = "ui"
    case data = "data"
    case `protocol` = "protocol"
    case map = "map"
    case hybrid = "hybrid"
}

/// Plugin validation and runtime errors
public enum PluginError: Error, LocalizedError {
    case invalidManifest(String)
    case platformNotSupported(String)
    case permissionDenied(String)
    case signatureInvalid(String)
    case dependencyMissing(String)
    case initializationFailed(String)
    case runtimeError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidManifest(let msg):
            return "Invalid plugin manifest: \(msg)"
        case .platformNotSupported(let msg):
            return "Platform not supported: \(msg)"
        case .permissionDenied(let msg):
            return "Permission denied: \(msg)"
        case .signatureInvalid(let msg):
            return "Invalid plugin signature: \(msg)"
        case .dependencyMissing(let msg):
            return "Missing dependency: \(msg)"
        case .initializationFailed(let msg):
            return "Plugin initialization failed: \(msg)"
        case .runtimeError(let msg):
            return "Plugin runtime error: \(msg)"
        }
    }
}

/// Version comparison utilities
public struct PluginVersion: Comparable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?

    public init?(_ versionString: String) {
        let components = versionString.split(separator: "-")
        let numbers = String(components[0]).split(separator: ".")

        guard numbers.count == 3,
              let major = Int(numbers[0]),
              let minor = Int(numbers[1]),
              let patch = Int(numbers[2]) else {
            return nil
        }

        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = components.count > 1 ? String(components[1]) : nil
    }

    public static func < (lhs: PluginVersion, rhs: PluginVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        if lhs.patch != rhs.patch { return lhs.patch < rhs.patch }

        // Prerelease versions have lower precedence
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil): return false
        case (nil, .some): return false
        case (.some, nil): return true
        case (.some(let l), .some(let r)): return l < r
        }
    }

    public static func == (lhs: PluginVersion, rhs: PluginVersion) -> Bool {
        return lhs.major == rhs.major &&
               lhs.minor == rhs.minor &&
               lhs.patch == rhs.patch &&
               lhs.prerelease == rhs.prerelease
    }
}
