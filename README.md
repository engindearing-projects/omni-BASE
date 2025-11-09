# Omni-BASE

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE.md)
[![Platforms](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey)]()
[![Status](https://img.shields.io/badge/status-alpha-orange)]()
[![Swift](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)](https://swift.org)
[![Rust](https://img.shields.io/badge/Rust-1.70+-orange?logo=rust)](https://www.rust-lang.org/)

**Omni-BASE is a cross-platform TAK (Team Awareness Kit) client built with Rust and native mobile frameworks.** It provides full ATAK-compatible tactical map functionality with multi-server management, real-time CoT (Cursor on Target) messaging, and a modern native UI.

## 🎉 Latest Update: iOS Physical Device Deployment (Nov 9, 2025)

**Successfully deployed YA-TAK iOS app to physical iPhone in development mode!**

- ✅ Built and installed on iPhone 15 Pro (iOS 18.7.1)
- ✅ Full ATAK-style UI with tactical theme
- ✅ Configured with local Taky server (127.0.0.1:8087 via TCP)
- ✅ Drawing tools fully operational (circles, polygons)
- ✅ Multi-server management working
- ✅ Real-time map with satellite imagery
- ✅ Portrait and landscape orientation support
- ✅ User profile system (ALPHA-1 Operator)

See [screenshots below](#screenshots) for live device captures!

## Features

### 🗺️ Tactical Map Interface
- **ATAK-style UI** - Professional tactical map interface mirroring ATAK's design
- **MapKit Integration** - Native iOS mapping with satellite, hybrid, and standard views
- **Real-time CoT Markers** - Live position updates with color-coded unit types (friendly/hostile/unknown)
- **GPS Tracking** - Real-time location with accuracy indicators
- **Interactive Controls** - Zoom, pan, layer switching, and GPS centering

### 📡 Multi-Server Management
- **Server Configuration** - Add, edit, and delete multiple TAK servers
- **Persistent Storage** - Server configurations saved locally with UserDefaults
- **One-Tap Switching** - Quickly switch between configured servers
- **Connection Status** - Real-time indicators showing active connections
- **Protocol Support** - TCP/UDP with optional TLS encryption
- **Active Server Display** - Current server name shown in status bar

### 💬 CoT Messaging
- **XML Parser** - Parse and display CoT messages from TAK servers
- **Broadcast Position** - Send self-position updates with full metadata
- **Event Tracking** - Monitor sent and received message counts
- **Type Filtering** - Filter units by affiliation (friendly, hostile, unknown)

### ✏️ Drawing Tools
- **Circles** - Draw circular areas of interest on the map
- **Polygons** - Create multi-point polygon shapes
- **Drawing Management** - View, edit, and clear all drawings
- **Persistent Storage** - Drawings saved and restored across sessions
- **Color Coding** - Orange and green tactical colors for visibility

### 🎨 User Interface
- **YA-TAK Branding** - Professional tactical theme with yellow accent (#FFFC00)
- **Navigation Drawer** - ATAK-style slide-in menu with user profile
- **Responsive Design** - Works in portrait and landscape orientations
- **Status Bar** - Real-time connection status, message counts, GPS accuracy, time
- **Bottom Toolbar** - Quick access to GPS, broadcast, zoom, layers, measure, and drawing tools
- **Layers Panel** - Toggle map types and unit overlays with visual feedback
- **Haptic Feedback** - Tactile response for all button interactions
- **Dark Mode Ready** - Semi-transparent overlays optimized for tactical use

## Architecture

### Core Components

```
omni-BASE/
├── apps/
│   ├── omnitak_ios_test/        # Native iOS app
│   │   ├── OmniTAKTest/
│   │   │   ├── OmniTAKTestApp.swift      # App entry point
│   │   │   ├── MapViewController.swift   # Main ATAK interface (800+ lines)
│   │   │   ├── TAKService.swift          # TAK server integration
│   │   │   ├── ServerManager.swift       # Multi-server management
│   │   │   └── Info.plist                # Location permissions
│   │   └── OmniTAKMobile.xcframework     # Rust FFI bindings
│   └── omnitak_android/         # Valdi Android app
│       ├── BUILD.bazel                   # Bazel build configuration
│       ├── src/valdi/omnitak_app/        # TypeScript entry point
│       └── app_assets/android/           # Android resources
└── modules/
    └── omnitak_mobile/           # Cross-platform module
        ├── src/                          # TypeScript/TSX application
        ├── ios/                          # iOS native layer
        └── android/                      # Android native layer
            ├── native/                   # Kotlin + JNI + Rust
            └── maplibre/                 # MapLibre integration
```

### Technology Stack

- **iOS Frontend**: SwiftUI + UIKit
- **Android Frontend**: Valdi framework (TypeScript + Kotlin)
- **Core Library**: Rust (cross-platform TAK protocol)
- **FFI**: C bindings (XCFramework for iOS, JNI for Android)
- **Mapping**: MapKit (iOS), MapLibre GL (Android)
- **Location**: CoreLocation (iOS), Android Location API
- **Build System**: Xcode (iOS), Bazel (Android)
- **Protocol**: TCP/UDP/TLS with TAK CoT XML

## Quick Start

### Setting Up Taky Server (Required)

Before running the app, you need a TAK server. We recommend using **Taky** for local development:

```bash
# Install Taky
pip install taky

# Start Taky server in debug mode
taky -l debug
```

The Taky server will start on `127.0.0.1:8087` (default TCP port). The app is pre-configured to connect to this server automatically.

**Note:** Keep the Taky server running while using the app. Press Ctrl+C to stop the server.

### iOS Prerequisites

- Xcode 15.0+
- iOS 15.0+ deployment target
- Rust toolchain (for building core library)
- macOS with Apple Silicon or Intel
- **Taky server** running locally (see above)

### Android Prerequisites

- Bazel 7.2.1+
- Android SDK API 34+
- Android NDK r21+
- Rust toolchain with Android targets
- Node.js 18+
- **Taky server** running locally (see above)

### iOS Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/engindearing-projects/omni-BASE.git
   cd omni-BASE
   ```

2. **Build the Rust core library:**
   ```bash
   cd modules/omnitak_mobile
   ./build_ios.sh
   ```

3. **Open the iOS project:**
   ```bash
   cd ../../apps/omnitak_ios_test
   open OmniTAKTest.xcodeproj
   ```

4. **Configure signing:**
   - Select the OmniTAKTest target
   - Go to "Signing & Capabilities"
   - Select your Team

5. **Build and run:**
   - Select iPhone simulator or device
   - Press Cmd+R to build and run

### Android Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/engindearing-projects/omni-BASE.git
   cd omni-BASE
   ```

2. **Install Rust Android targets:**
   ```bash
   rustup target add aarch64-linux-android
   rustup target add armv7-linux-androideabi
   rustup target add x86_64-linux-android
   rustup target add i686-linux-android
   ```

3. **Build Rust libraries for Android:**
   ```bash
   # Set path to omni-TAK repository
   export OMNI_TAK_DIR=~/omni-TAK

   cd modules/omnitak_mobile
   ./build_android.sh
   ```

4. **Build Android APK:**
   ```bash
   cd ../..
   bazel build //apps/omnitak_android
   ```

5. **Install on device:**
   ```bash
   adb install -r bazel-bin/apps/omnitak_android/omnitak_android.apk
   ```

For detailed Android build instructions, see [apps/omnitak_android/README.md](apps/omnitak_android/README.md).

### Using the App

1. **Start Taky Server** - Run `taky -l debug` to start local TAK server on port 8087
2. **Launch App** - App auto-connects to default Taky Server
3. **View Map** - Satellite imagery with tactical overlays
4. **Manage Servers** - Tap status bar to access server list
5. **Add Server** - Tap "+" to configure new TAK server
6. **Switch Servers** - Tap bolt icon to connect to different server
7. **Broadcast Position** - Tap "Broadcast" to send CoT update
8. **Toggle Layers** - Tap "Layers" to change map type and unit filters

## Configuration

### Default TAK Server (Taky)

The app ships with a default local Taky Server configuration:

```swift
TAKServer(
    name: "Taky Server",
    host: "127.0.0.1",
    port: 8087,
    protocolType: "tcp",
    useTLS: false
)
```

**Starting Taky Server:**
```bash
# Install Taky (if not already installed)
pip install taky

# Start Taky server in debug mode
taky -l debug
```

The server will start on `127.0.0.1:8087` and the app will automatically connect on launch.

### Adding Custom Servers

1. Open server list (tap status bar)
2. Tap "Add Server" (+)
3. Enter server details:
   - Name (e.g., "My TAK Server")
   - Host (IP address or hostname)
   - Port (default: 8087)
   - Protocol (TCP or UDP)
   - TLS (toggle if using SSL/TLS)
4. Tap "Save Server"

## Screenshots

### 📱 Live iPhone Deployment (Nov 9, 2025)

#### Tactical Map with Drawing Tools (Landscape)
<p align="center">
  <img src="./docs/screenshots/ios/IMG_0207.PNG" width="700" alt="YA-TAK tactical map with circles and polygons">
</p>

*Full tactical view showing drawn circle and polygon on satellite imagery with drawings panel*

#### Navigation Drawer & Drawing Tools (Portrait)
<p align="center">
  <img src="./docs/screenshots/ios/IMG_0210.PNG" width="300" alt="YA-TAK navigation drawer">
  <img src="./docs/screenshots/ios/IMG_0208.PNG" width="300" alt="Drawing tools panel">
</p>

*Left: YA-TAK navigation drawer with ALPHA-1 user profile | Right: Drawing tools with active shapes*

#### Server Management (Portrait)
<p align="center">
  <img src="./docs/screenshots/ios/IMG_0209.PNG" width="300" alt="TAK Servers management screen">
</p>

*Multi-server configuration showing active connection to TAK Server via TCP*

## Development

### Project Structure

- **MapViewController.swift** (800+ lines)
  - ATAKMapView: Main map with UIViewRepresentable wrapper
  - ATAKStatusBar: Connection status and metrics
  - ATAKBottomToolbar: Quick action buttons
  - ATAKSidePanel: Layers and overlays
  - ServerConfigView: Multi-server management
  - ServerEditView: Add/edit server dialog

- **TAKService.swift**
  - Rust FFI integration
  - CoT XML parsing
  - Server connection management
  - Event callbacks

- **ServerManager.swift**
  - Server CRUD operations
  - Persistent storage
  - Active server tracking

### Building from Source

```bash
# Build Rust library for iOS
cd modules/omnitak_mobile
./build_ios.sh

# Build iOS app with Xcode CLI
cd ../../apps/omnitak_ios_test
xcodebuild -project OmniTAKTest.xcodeproj \
           -scheme OmniTAKTest \
           -configuration Debug \
           -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
           build
```

### Running Tests

```bash
# Install on simulator
xcrun simctl install "iPhone 16 Pro" \
  "$(find ~/Library/Developer/Xcode/DerivedData/OmniTAKTest-*/Build/Products/Debug-iphonesimulator/OmniTAKTest.app | head -1)"

# Launch app
xcrun simctl launch "iPhone 16 Pro" com.engindearing.omnitak.test
```

## Roadmap

### Completed ✅
- [x] iOS physical device deployment
- [x] Drawing tools (circles, polygons)
- [x] Multi-server management
- [x] Real-time TAK server connectivity
- [x] ATAK-style navigation drawer
- [x] User profile system

### In Progress 🚧
- [ ] Android implementation
- [ ] Advanced CoT filtering and search
- [ ] Offline map caching
- [ ] Team chat integration
- [ ] File sharing and attachments
- [ ] Mission planning tools
- [ ] Integration with external sensors
- [ ] Data replay and simulation

## Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

- Built with Rust for cross-platform core functionality
- Uses MapKit for native iOS mapping
- Compatible with TAK CoT XML protocol
- Inspired by ATAK's tactical UI/UX design

## Support

For questions, issues, or feature requests:
- Open an issue on GitHub
- Contact: [Engineering Projects](https://github.com/engindearing-projects)

---

**Note**: This is an alpha release. Features are under active development and APIs may change.
