//
// PluginPermissions.swift
// OmniTAK Plugin System
//
// Defines plugin permissions and permission checking
//

import Foundation

/// Plugin permission definitions
public enum PluginPermission: String, CaseIterable {
    case networkAccess = "network.access"
    case locationRead = "location.read"
    case locationWrite = "location.write"
    case cotRead = "cot.read"
    case cotWrite = "cot.write"
    case mapRead = "map.read"
    case mapWrite = "map.write"
    case storageRead = "storage.read"
    case storageWrite = "storage.write"
    case uiCreate = "ui.create"
    case notificationsSend = "notifications.send"
    case bluetoothAccess = "bluetooth.access"
    case fileSystemRead = "filesystem.read"
    case fileSystemWrite = "filesystem.write"

    /// Check if permission string is valid
    public static func isValid(_ permissionString: String) -> Bool {
        return PluginPermission(rawValue: permissionString) != nil
    }

    /// Parse permission from string
    public static func parse(_ permissionString: String) -> PluginPermission? {
        return PluginPermission(rawValue: permissionString)
    }

    /// Get human-readable description
    public var description: String {
        switch self {
        case .networkAccess:
            return "Make network requests"
        case .locationRead:
            return "Access device location"
        case .locationWrite:
            return "Update location data"
        case .cotRead:
            return "Read Cursor-on-Target messages"
        case .cotWrite:
            return "Send Cursor-on-Target messages"
        case .mapRead:
            return "Access map data and layers"
        case .mapWrite:
            return "Add custom map layers and markers"
        case .storageRead:
            return "Read from local storage"
        case .storageWrite:
            return "Write to local storage"
        case .uiCreate:
            return "Create user interface components"
        case .notificationsSend:
            return "Send push notifications"
        case .bluetoothAccess:
            return "Access Bluetooth devices"
        case .fileSystemRead:
            return "Read files from disk"
        case .fileSystemWrite:
            return "Write files to disk"
        }
    }

    /// Permission risk level
    public var riskLevel: PermissionRiskLevel {
        switch self {
        case .networkAccess, .locationRead, .cotRead, .mapRead, .storageRead, .fileSystemRead:
            return .low
        case .uiCreate, .notificationsSend:
            return .medium
        case .locationWrite, .cotWrite, .mapWrite, .storageWrite, .bluetoothAccess, .fileSystemWrite:
            return .high
        }
    }
}

/// Permission risk level for user consent
public enum PermissionRiskLevel {
    case low
    case medium
    case high

    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}

/// Permission set for a plugin
public struct PluginPermissionSet {
    private var permissions: Set<PluginPermission>

    public init(_ permissions: [PluginPermission]) {
        self.permissions = Set(permissions)
    }

    public init(from strings: [String]) throws {
        var perms: Set<PluginPermission> = []
        for str in strings {
            guard let perm = PluginPermission.parse(str) else {
                throw PluginError.invalidManifest("Invalid permission: \(str)")
            }
            perms.insert(perm)
        }
        self.permissions = perms
    }

    /// Check if permission is granted
    public func has(_ permission: PluginPermission) -> Bool {
        return permissions.contains(permission)
    }

    /// Check if all permissions are granted
    public func hasAll(_ requiredPermissions: [PluginPermission]) -> Bool {
        return requiredPermissions.allSatisfy { permissions.contains($0) }
    }

    /// Get all permissions
    public func all() -> Set<PluginPermission> {
        return permissions
    }

    /// Get permissions by risk level
    public func byRiskLevel(_ level: PermissionRiskLevel) -> [PluginPermission] {
        return permissions.filter { $0.riskLevel == level }
    }
}

/// Permission checker for runtime validation
public protocol PluginPermissionChecker {
    func checkPermission(_ permission: PluginPermission, forPlugin pluginId: String) throws
}

/// Default permission checker implementation
public class DefaultPermissionChecker: PluginPermissionChecker {
    private var grantedPermissions: [String: PluginPermissionSet] = [:]

    public init() {}

    /// Grant permissions to a plugin
    public func grantPermissions(_ permissions: PluginPermissionSet, forPlugin pluginId: String) {
        grantedPermissions[pluginId] = permissions
    }

    /// Check if plugin has permission
    public func checkPermission(_ permission: PluginPermission, forPlugin pluginId: String) throws {
        guard let permSet = grantedPermissions[pluginId],
              permSet.has(permission) else {
            throw PluginError.permissionDenied("Plugin \(pluginId) does not have permission: \(permission.rawValue)")
        }
    }

    /// Revoke all permissions for a plugin
    public func revokePermissions(forPlugin pluginId: String) {
        grantedPermissions.removeValue(forKey: pluginId)
    }
}
