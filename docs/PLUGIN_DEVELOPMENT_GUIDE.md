# OmniTAK Plugin Development Guide

Complete guide for developing, building, and publishing OmniTAK plugins.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Plugin Architecture](#plugin-architecture)
3. [Development Workflow](#development-workflow)
4. [API Reference](#api-reference)
5. [Testing](#testing)
6. [Code Signing](#code-signing)
7. [Publishing](#publishing)
8. [Best Practices](#best-practices)

## Getting Started

### Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Bazel 7.0 or later
- Git
- GitLab account with access to OmniTAK plugin repository

### Setting Up Your Development Environment

1. **Install Bazel**

```bash
brew install bazel
```

2. **Clone the plugin template**

```bash
git clone https://gitlab.com/omnitak/plugin-template.git my-plugin
cd my-plugin
```

3. **Customize your plugin**

Edit `plugin.json`:

```json
{
  "id": "com.yourcompany.yourplugin",
  "name": "Your Plugin Name",
  "version": "1.0.0",
  "description": "Description of your plugin",
  "author": "Your Name",
  "license": "MIT",
  "omnitak_version": ">=1.0.0",
  "type": "ui",
  "platforms": ["ios"],
  "permissions": ["cot.read", "ui.create"],
  "entry_points": {
    "ios": "YourPlugin"
  }
}
```

4. **Update BUILD file**

Edit `ios/BUILD.bazel` and replace "MyPlugin" with your plugin name:

```python
swift_library(
    name = "YourPluginLib",
    srcs = glob(["Sources/**/*.swift"]),
    module_name = "YourPlugin",
    deps = [
        "//modules/omnitak_plugin_system/ios:OmniTAKPluginSystem",
    ],
)

ios_framework(
    name = "YourPlugin",
    bundle_id = "com.engindearing.omnitak.plugin.yourplugin",
    # ...
)
```

5. **Build your plugin**

```bash
./scripts/build_plugin_ios.sh debug
```

## Plugin Architecture

### Plugin Types

OmniTAK supports four types of plugins:

#### 1. UI Plugins

Add new user interface elements, panels, or tools.

```swift
class MyUIProvider: UIProvider {
    func createPanel() -> UIViewController? {
        let vc = MyPanelViewController()
        return vc
    }

    func createToolbarItem() -> UIView? {
        let button = UIButton(type: .system)
        button.setTitle("My Tool", for: .normal)
        return button
    }
}
```

#### 2. Data Plugins

Process and transform CoT messages or other data.

```swift
class MyCoTHandler: CoTHandler {
    func handleCoTMessage(_ message: CoTMessage) -> CoTHandlerResult {
        // Filter, transform, or enrich CoT messages
        if message.type == "a-f-G" {
            // Process friendly ground unit
            return .processed
        }
        return .passthrough
    }
}
```

#### 3. Map Plugins

Add custom map layers, overlays, or rendering.

```swift
func activate() throws {
    let mapManager = try context.mapManager

    // Add custom layer
    let layer = MyCustomMapLayer()
    try mapManager?.addLayer(layer)

    // Add markers
    let marker = MapMarker(
        id: "custom-marker",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        title: "Custom Location"
    )
    try mapManager?.addMarker(marker)
}
```

#### 4. Protocol Plugins

Add support for new network protocols or data formats.

```swift
func activate() async throws {
    let networkManager = try context.networkManager

    // Connect to custom protocol
    let url = URL(string: "https://custom-api.example.com")!
    let (data, response) = try await networkManager?.request(url: url)

    // Parse and forward to OmniTAK
}
```

### Plugin Lifecycle

Every plugin goes through these states:

```
Unloaded → Loaded → Initialized → Active → Inactive → Unloaded
```

Implement lifecycle methods:

```swift
public func initialize(context: PluginContext) throws {
    // One-time setup
    self.context = context
    context.logger.info("Plugin initialized")
}

public func activate() throws {
    // Called when plugin is enabled
    // Register handlers, create UI, etc.
    context.logger.info("Plugin activated")
}

public func deactivate() throws {
    // Called when plugin is disabled
    // Cleanup handlers, remove UI, etc.
    context.logger.info("Plugin deactivated")
}

public func cleanup() throws {
    // Final cleanup before unload
    context.logger.info("Plugin cleaned up")
}
```

### Permission System

Request only the permissions you need:

```json
{
  "permissions": [
    "cot.read",      // Read CoT messages
    "cot.write",     // Send CoT messages
    "map.read",      // Access map state
    "map.write",     // Modify map (layers, markers)
    "ui.create",     // Create UI components
    "network.access" // Make network requests
  ]
}
```

Check permissions at runtime:

```swift
if context.permissions.has(.cotRead) {
    // Safe to read CoT messages
}
```

## Development Workflow

### 1. Local Development

#### Build Plugin

```bash
# Debug build
./scripts/build_plugin_ios.sh debug

# Release build
./scripts/build_plugin_ios.sh release
```

#### Run Tests

```bash
./scripts/test_plugin_ios.sh
```

#### Validate Plugin

```bash
./scripts/validate_plugin.py
```

### 2. Testing in OmniTAK

To test your plugin in the OmniTAK app:

```bash
# Package plugin
./scripts/package_plugin.sh

# Install to OmniTAK
# Copy dist/*.omniplugin to OmniTAK's plugins directory
```

### 3. Push to GitLab

```bash
git add .
git commit -m "Implement feature X"
git push origin main
```

GitLab CI/CD will automatically build, test, and sign your plugin.

### 4. Publish Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

The plugin will be published to the plugin registry.

## API Reference

### PluginContext

Access to OmniTAK APIs and services.

```swift
public class PluginContext {
    // Basic services
    public let pluginId: String
    public let permissions: PluginPermissionSet
    public let storage: PluginStorage
    public let logger: PluginLogger

    // API managers (available based on permissions)
    public var cotManager: CoTManager? { get throws }
    public var mapManager: MapManager? { get throws }
    public var networkManager: NetworkManager? { get throws }
    public var locationManager: LocationManager? { get throws }
    public var uiManager: UIManager? { get throws }
}
```

### CoTManager

Manage Cursor-on-Target messages.

```swift
// Register handler for incoming CoT
func registerHandler(_ handler: CoTHandler) throws

// Send CoT message
func sendMessage(_ message: CoTMessage) throws

// Query stored CoT messages
func queryMessages(filter: CoTFilter) throws -> [CoTMessage]
```

### MapManager

Interact with the map.

```swift
// Add/remove layers
func addLayer(_ layer: MapLayer) throws
func removeLayer(id: String) throws

// Add/remove markers
func addMarker(_ marker: MapMarker) throws
func removeMarker(id: String) throws

// Get map state
func getMapCenter() throws -> CLLocationCoordinate2D
func getZoomLevel() throws -> Double
```

### NetworkManager

Make network requests.

```swift
func request(
    url: URL,
    method: String = "GET",
    headers: [String: String]? = nil,
    body: Data? = nil
) async throws -> (Data, HTTPURLResponse)
```

### LocationManager

Access device location.

```swift
// Get current location
func getCurrentLocation() throws -> CLLocation

// Update location (for simulation/testing)
func updateLocation(_ location: CLLocation) throws
```

### PluginStorage

Persistent key-value storage.

```swift
func get(_ key: String) -> Data?
func set(_ key: String, value: Data) throws
func remove(_ key: String) throws
func clear() throws
func keys() -> [String]
```

### PluginLogger

Logging for debugging.

```swift
func debug(_ message: String)
func info(_ message: String)
func warning(_ message: String)
func error(_ message: String)
func error(_ message: String, error: Error)
```

## Testing

### Unit Tests

Create test target in `ios/BUILD.bazel`:

```python
swift_test(
    name = "MyPluginTests",
    srcs = glob(["Tests/**/*.swift"]),
    deps = [":MyPluginLib"],
)
```

Example test:

```swift
import XCTest
@testable import MyPlugin

class MyPluginTests: XCTestCase {
    func testCoTProcessing() {
        let handler = MyCoTHandler()
        let message = createTestCoTMessage()
        let result = handler.handleCoTMessage(message)
        XCTAssertEqual(result, .processed)
    }
}
```

### Integration Tests

Test your plugin with mock OmniTAK APIs:

```swift
func testPluginActivation() throws {
    let mockContext = MockPluginContext()
    let plugin = PluginMain()

    try plugin.initialize(context: mockContext)
    try plugin.activate()

    XCTAssertTrue(mockContext.handlerRegistered)
}
```

## Code Signing

All plugins are automatically signed by the GitLab CI/CD pipeline using the same Apple Developer certificate as the main OmniTAK app.

### Bundle ID Pattern

Plugins use this bundle ID pattern:

```
com.engindearing.omnitak.plugin.<your-plugin-id>
```

For example:
- Plugin ID: `com.example.myplugin`
- Bundle ID: `com.engindearing.omnitak.plugin.myplugin`

### Signing Certificate

The CI/CD pipeline uses these environment variables (configured at GitLab group level):

- `IOS_SIGNING_CERT` - Base64-encoded P12 certificate
- `IOS_SIGNING_CERT_PASSWORD` - Certificate password
- `IOS_PROVISIONING_PROFILE` - Base64-encoded provisioning profile

You don't need to configure these yourself - they're shared across all plugins.

### Local Signing (Development)

For local testing, use ad-hoc signing:

```bash
export CODE_SIGNING_IDENTITY="-"
./scripts/build_plugin_ios.sh debug
```

## Publishing

### Version Numbers

Use semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

### Release Process

1. **Update version** in `plugin.json`

2. **Commit changes**
```bash
git add plugin.json
git commit -m "Bump version to 1.1.0"
```

3. **Create tag**
```bash
git tag v1.1.0
```

4. **Push**
```bash
git push origin main --tags
```

5. **Monitor CI/CD** - Check GitLab pipeline

6. **Verify publication** - Check plugin registry

### GitLab Package Registry

Plugins are published to:
```
${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/${PLUGIN_ID}/${VERSION}/
```

Users can browse and install from the OmniTAK app.

## Best Practices

### Security

1. **Request minimum permissions** - Only request what you need
2. **Validate input** - Always validate user input and external data
3. **Handle errors gracefully** - Don't crash the main app
4. **Use HTTPS** - For all network requests
5. **Sanitize logs** - Don't log sensitive data

### Performance

1. **Use async/await** - For long-running operations
2. **Optimize CoT handlers** - Return quickly to avoid blocking
3. **Lazy load resources** - Load heavy resources only when needed
4. **Cache data** - Use plugin storage for caching
5. **Profile regularly** - Use Instruments to find bottlenecks

### User Experience

1. **Provide feedback** - Show progress indicators
2. **Handle errors** - Display user-friendly error messages
3. **Document settings** - Explain what each setting does
4. **Use native UI** - Follow iOS Human Interface Guidelines
5. **Test on devices** - Test on real devices, not just simulator

### Code Quality

1. **Follow Swift style guide** - Use consistent formatting
2. **Write tests** - Aim for >80% code coverage
3. **Document public APIs** - Use Swift documentation comments
4. **Handle edge cases** - Test error conditions
5. **Use linters** - Run SwiftLint or similar

### Example: Complete Plugin

Here's a complete example of a simple plugin that filters CoT messages:

```swift
import Foundation
import OmniTAKPluginSystem

@objc public class PluginMain: NSObject, OmniTAKPlugin {
    public var manifest: PluginManifest {
        // Load from bundle
        let bundle = Bundle(for: type(of: self))
        let url = bundle.url(forResource: "plugin", withExtension: "json")!
        return try! PluginManifest.load(from: url)
    }

    private weak var context: PluginContext?
    private var cotFilter: CoTFilterHandler?

    public func initialize(context: PluginContext) throws {
        self.context = context
        self.cotFilter = CoTFilterHandler(context: context)
        context.logger.info("CoT Filter plugin initialized")
    }

    public func activate() throws {
        guard let context = context,
              let filter = cotFilter else {
            throw PluginError.runtimeError("Plugin not initialized")
        }

        let cotManager = try context.cotManager
        try cotManager?.registerHandler(filter)
        context.logger.info("CoT Filter activated")
    }

    public func deactivate() throws {
        context?.logger.info("CoT Filter deactivated")
    }

    public func cleanup() throws {
        cotFilter = nil
        context = nil
    }
}

class CoTFilterHandler: CoTHandler {
    private weak var context: PluginContext?
    private var allowedTypes: Set<String>

    init(context: PluginContext) {
        self.context = context
        // Load filter settings from storage
        self.allowedTypes = ["a-f-G", "a-h-G"]  // Friendly units
    }

    func handleCoTMessage(_ message: CoTMessage) -> CoTHandlerResult {
        guard let context = context else { return .passthrough }

        // Filter based on type
        if allowedTypes.contains(message.type) {
            context.logger.debug("Allowed CoT: \(message.type)")
            return .passthrough
        } else {
            context.logger.debug("Filtered CoT: \(message.type)")
            return .blocked
        }
    }
}
```

## Support

- **Documentation**: https://docs.omnitak.io
- **Issues**: https://gitlab.com/omnitak/plugin-template/issues
- **Discord**: https://discord.gg/VSUjDddRt3
- **Email**: plugins@omnitak.io
