# OmniTAK Plugin Template

This is the official template for creating OmniTAK plugins. Use this template to build secure, signed plugins that extend the functionality of the OmniTAK mobile application.

## Quick Start

### 1. Clone this template

```bash
git clone https://gitlab.com/omnitak/plugin-template.git my-plugin
cd my-plugin
```

### 2. Customize your plugin

Edit `plugin.json` with your plugin details:

```json
{
  "id": "com.yourcompany.yourplugin",
  "name": "Your Plugin Name",
  "version": "1.0.0",
  "description": "What your plugin does",
  "author": "Your Name",
  "license": "MIT",
  "omnitak_version": ">=1.0.0",
  "type": "ui",
  "platforms": ["ios"],
  "permissions": [
    "cot.read",
    "ui.create"
  ],
  "entry_points": {
    "ios": "YourPlugin"
  }
}
```

### 3. Implement your plugin

Edit `ios/Sources/PluginMain.swift` and implement your plugin logic:

```swift
public class PluginMain: NSObject, OmniTAKPlugin {
    // Implement initialize, activate, deactivate, cleanup
}
```

### 4. Build and test locally

```bash
# Build plugin
./scripts/build_plugin_ios.sh debug

# Run tests
./scripts/test_plugin_ios.sh
```

### 5. Push to GitLab

The CI/CD pipeline will automatically build, test, sign, and package your plugin:

```bash
git add .
git commit -m "Initial plugin implementation"
git push origin main
```

### 6. Publish a release

Create a git tag to publish your plugin:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The plugin will be automatically published to the OmniTAK Plugin Registry!

## Plugin Structure

```
my-plugin/
├── plugin.json              # Plugin manifest
├── .gitlab-ci.yml           # CI/CD pipeline (do not modify)
├── ios/                     # iOS implementation
│   ├── BUILD.bazel         # Bazel build config
│   ├── Info.plist          # iOS framework info
│   └── Sources/
│       └── PluginMain.swift # Main plugin class
├── scripts/                 # Build scripts
└── README.md
```

## Permissions

Request only the permissions your plugin needs:

- `network.access` - Make network requests
- `location.read` - Access device location
- `location.write` - Update location data
- `cot.read` - Read CoT messages
- `cot.write` - Send CoT messages
- `map.read` - Access map data
- `map.write` - Add map layers/markers
- `storage.read` - Read local storage
- `storage.write` - Write local storage
- `ui.create` - Create UI components

## Plugin API

### Accessing CoT Messages

```swift
func activate() throws {
    let cotManager = try context.cotManager
    try cotManager?.registerHandler(self)
}

func handleCoTMessage(_ message: CoTMessage) -> CoTHandlerResult {
    // Process CoT message
    return .passthrough
}
```

### Adding Map Markers

```swift
func activate() throws {
    let mapManager = try context.mapManager

    let marker = MapMarker(
        id: "my-marker",
        coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        title: "My Marker"
    )

    try mapManager?.addMarker(marker)
}
```

### Creating UI

```swift
func createPanel() -> UIViewController? {
    let viewController = UIViewController()
    viewController.title = "My Plugin"
    // Add your UI here
    return viewController
}
```

### Making Network Requests

```swift
func activate() async throws {
    let networkManager = try context.networkManager

    let url = URL(string: "https://api.example.com/data")!
    let (data, response) = try await networkManager?.request(url: url)

    // Process response
}
```

## Local Development

### Prerequisites

- macOS with Xcode 15+
- Bazel 7.0+
- Swift 5.9+

### Build Commands

```bash
# Debug build
./scripts/build_plugin_ios.sh debug

# Release build
./scripts/build_plugin_ios.sh release

# Run tests
./scripts/test_plugin_ios.sh

# Validate plugin
./scripts/validate_plugin.py
```

## CI/CD Pipeline

The GitLab CI/CD pipeline automatically:

1. **Validates** - Checks manifest and structure
2. **Builds** - Compiles plugin for iOS
3. **Tests** - Runs unit tests
4. **Signs** - Code signs with OmniTAK developer keys
5. **Packages** - Creates .omniplugin bundle
6. **Publishes** - Uploads to plugin registry (on tags)

### Required CI/CD Variables

These are configured at the GitLab group/project level:

- `IOS_SIGNING_CERT` - Base64-encoded Apple Developer certificate
- `IOS_SIGNING_CERT_PASSWORD` - Certificate password
- `IOS_PROVISIONING_PROFILE` - Base64-encoded provisioning profile
- `PLUGIN_REGISTRY_TOKEN` - Token for publishing to registry

### Pipeline Stages

- **validate** - Runs on all branches
- **build** - Runs on all branches
- **test** - Runs on all branches
- **sign** - Runs on main branch and tags only
- **package** - Runs on main branch and tags only
- **publish** - Runs on tags only

## Code Signing

All plugins are signed with the same Apple Developer certificate as the main OmniTAK app. This ensures:

- Trust chain with the main app
- Consistent bundle ID pattern: `com.engindearing.omnitak.plugin.*`
- App Store compatibility (if applicable)

## Publishing

### Development Builds

Merge to `main` branch to create a development build:

```bash
git checkout main
git merge feature-branch
git push origin main
```

### Release Builds

Create a git tag to publish a release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The plugin will be published to the OmniTAK Plugin Registry and available for installation.

## Support

- Documentation: https://docs.omnitak.io/plugins
- Issues: https://gitlab.com/omnitak/plugin-template/issues
- Community: https://discord.gg/omnitak

## License

This template is licensed under MIT. Your plugin can use any license you choose.
