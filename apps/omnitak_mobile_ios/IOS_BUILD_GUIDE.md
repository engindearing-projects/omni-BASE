# iOS Build Guide for OmniTAK Mobile

This guide provides step-by-step instructions for building and running OmniTAK Mobile on iOS devices and simulators.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Building for iOS](#building-for-ios)
- [Running on Simulator](#running-on-simulator)
- [Running on Device](#running-on-device)
- [Running Tests](#running-tests)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Advanced Topics](#advanced-topics)

## Prerequisites

### Required Software

1. **macOS** - iOS development requires macOS with Xcode
2. **Xcode 14.0+** - Install from App Store or [developer.apple.com](https://developer.apple.com)
3. **Xcode Command Line Tools**
   ```bash
   xcode-select --install
   ```
4. **Bazel 6.0+** - Build system
   ```bash
   brew install bazel
   # Or use bazelisk
   brew install bazelisk
   ```
5. **Rust toolchain** (for native library compilation)
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   rustup target add aarch64-apple-ios
   rustup target add aarch64-apple-ios-sim
   rustup target add x86_64-apple-ios
   ```

### Recommended Software

- **Xcode Simulators** - Install additional iOS versions from Xcode > Preferences > Components
- **iOS Device** - For testing on physical hardware
- **Apple Developer Account** - Required for device deployment (free tier works)

### Verify Installation

```bash
# Check Xcode
xcodebuild -version

# Check Bazel
bazel version

# Check Rust
rustc --version
cargo --version

# List available simulators
xcrun simctl list devices available
```

## Quick Start

The fastest way to build and run OmniTAK Mobile on iOS simulator:

```bash
# Clone the repository
cd /Users/iesouskurios/Downloads/omni-BASE

# Run on iOS simulator
./scripts/run_ios_simulator.sh
```

This script will:
1. Build the app for iOS simulator
2. Boot the default simulator (iPhone 15 Pro)
3. Install and launch the app
4. Display console output

## Building for iOS

### Build for Simulator

Build the app for iOS simulator (arm64):

```bash
./scripts/build_ios.sh simulator debug
```

Build options:
- **Target**: `simulator` or `device`
- **Mode**: `debug` or `release`

Examples:
```bash
# Debug build for simulator
./scripts/build_ios.sh simulator debug

# Release build for simulator
./scripts/build_ios.sh simulator release

# Debug build for device
./scripts/build_ios.sh device debug

# Release build for device
./scripts/build_ios.sh device release
```

### Build with Bazel Directly

For more control, use Bazel directly:

```bash
# Simulator (arm64)
bazel build //apps/omnitak_mobile_ios:OmniTAKMobile-Simulator \
    --config=ios_sim_debug

# Simulator (x86_64 - Intel Macs)
bazel build //apps/omnitak_mobile_ios:OmniTAKMobile-Simulator \
    --config=ios_sim_x86_64 \
    --compilation_mode=dbg

# Device (arm64)
bazel build //apps/omnitak_mobile_ios:OmniTAKMobile \
    --config=ios_dev_debug
```

### Build Output

After a successful build, the app bundle will be located at:
```
bazel-bin/apps/omnitak_mobile_ios/OmniTAKMobile-Simulator.app
# or
bazel-bin/apps/omnitak_mobile_ios/OmniTAKMobile.app
```

## Running on Simulator

### Using the Script (Recommended)

```bash
# Use default simulator
./scripts/run_ios_simulator.sh

# Use specific simulator
./scripts/run_ios_simulator.sh "iPhone 15 Pro"
./scripts/run_ios_simulator.sh "iPad Pro (12.9-inch)"
```

### Manual Installation

```bash
# List available simulators
xcrun simctl list devices available

# Boot a simulator
SIMULATOR_UDID="<your-simulator-udid>"
xcrun simctl boot $SIMULATOR_UDID

# Install the app
xcrun simctl install $SIMULATOR_UDID \
    bazel-bin/apps/omnitak_mobile_ios/OmniTAKMobile-Simulator.app

# Launch the app
xcrun simctl launch --console $SIMULATOR_UDID \
    com.engindearing.omnitak.mobile
```

### Viewing Logs

```bash
# Stream all logs from the app
xcrun simctl spawn booted log stream \
    --predicate 'processImagePath contains "OmniTAK"'

# View recent logs
xcrun simctl spawn booted log show \
    --predicate 'processImagePath contains "OmniTAK"' \
    --info --debug \
    --last 5m
```

## Running on Device

### Code Signing Setup

1. **Configure Apple Developer Account** in Xcode
   - Open Xcode > Preferences > Accounts
   - Add your Apple ID
   - Download certificates and provisioning profiles

2. **Update Bundle Identifier** (if needed)
   - Edit `apps/omnitak_mobile_ios/BUILD.bazel`
   - Change `bundle_id` to your unique identifier

3. **Configure Signing** in `.bazelrc.ios`
   ```bash
   build:ios_device --ios_signing_cert_name="Apple Development: Your Name"
   ```

### Deploy to Device

```bash
# Build for device
./scripts/build_ios.sh device debug

# Get device UDID
idevice_id -l
# Or from Xcode > Window > Devices and Simulators

# Install using ios-deploy (if installed)
ios-deploy --bundle bazel-bin/apps/omnitak_mobile_ios/OmniTAKMobile.app

# Or install via Xcode
# Drag .app to Devices window
```

### Alternative: Use Xcode

For easier device deployment, you can open the app in Xcode:

```bash
# Generate Xcode project
bazel run //apps/omnitak_mobile_ios:OmniTAKMobile.xcodeproj

# Open in Xcode
open bazel-bin/apps/omnitak_mobile_ios/OmniTAKMobile.xcodeproj
```

Then build and run from Xcode (⌘R).

## Running Tests

### Run All Tests

```bash
# Run iOS unit tests on simulator
bazel test //apps/omnitak_mobile_ios:OmniTAKMobileTests \
    --config=ios_sim_debug \
    --test_output=all
```

### Run Specific Tests

```bash
# Run only bridge tests
bazel test //apps/omnitak_mobile_ios:OmniTAKMobileTests \
    --config=ios_sim_debug \
    --test_filter=OmniTAKNativeBridgeTests \
    --test_output=all

# Run only MapLibre tests
bazel test //apps/omnitak_mobile_ios:OmniTAKMobileTests \
    --config=ios_sim_debug \
    --test_filter=MapLibreIntegrationTests \
    --test_output=all
```

### Test Coverage

```bash
# Generate coverage report
bazel coverage //apps/omnitak_mobile_ios:OmniTAKMobileTests \
    --config=ios_sim_debug \
    --combined_report=lcov

# View coverage
genhtml bazel-out/_coverage/_coverage_report.dat \
    --output-directory coverage_html
open coverage_html/index.html
```

## Project Structure

```
apps/omnitak_mobile_ios/
├── BUILD.bazel                    # Bazel build configuration
├── IOS_BUILD_GUIDE.md            # This file
├── src/ios/
│   ├── AppDelegate.swift         # App lifecycle management
│   └── ViewController.swift      # Main UI and demo functionality
├── app_assets/ios/
│   └── Info.plist               # App metadata and permissions
└── tests/ios/
    └── OmniTAKTests.swift       # Unit and integration tests

modules/omnitak_mobile/ios/
├── native/
│   ├── BUILD.bazel              # Native module build config
│   ├── OmniTAKMobile.xcframework # Rust FFI binary
│   ├── OmniTAKNativeBridge.swift # Swift wrapper
│   └── omnitak_mobile.h         # C FFI header
└── maplibre/
    ├── BUILD.bazel              # MapLibre build config
    ├── SCMapLibreMapView.h      # Objective-C header
    └── SCMapLibreMapView.m      # MapLibre wrapper implementation

scripts/
├── build_ios.sh                 # Build script
└── run_ios_simulator.sh         # Run on simulator script
```

## Configuration

### Bazel Configuration

iOS-specific Bazel settings are in `.bazelrc.ios`. Key configurations:

```bash
# iOS minimum version
build:ios --ios_minimum_os=14.0

# Simulator configs
build:ios_sim_arm64 --cpu=ios_sim_arm64
build:ios_sim_x86_64 --cpu=ios_x86_64

# Device config
build:ios_arm64 --cpu=ios_arm64

# Debug vs Release
build:ios_debug --compilation_mode=dbg
build:ios_release --compilation_mode=opt
```

### App Configuration

Edit `apps/omnitak_mobile_ios/app_assets/ios/Info.plist` to configure:

- **Bundle Identifier** - `com.engindearing.omnitak.mobile`
- **Display Name** - "OmniTAK Mobile"
- **Permissions** - Location, Camera, Network, Files
- **Background Modes** - Location updates, Network

### TAK Server Configuration

Update `ViewController.swift` to configure your TAK server:

```swift
let config: [String: Any] = [
    "host": "tak-server.example.com",  // Your TAK server
    "port": 8089,
    "protocol": "tcp",
    "useTls": false,
    "reconnect": true,
    "reconnectDelayMs": 5000
]
```

## Troubleshooting

### Common Issues

#### 1. Build Fails: "No such file or directory: OmniTAKMobile.xcframework"

**Problem**: The XCFramework hasn't been built yet.

**Solution**: Build the Rust library first:
```bash
cd /Users/iesouskurios/Downloads/omni-TAK
cargo build --release
./build_xcframework.sh
```

Then copy the XCFramework to the iOS native directory:
```bash
cp -R target/OmniTAKMobile.xcframework \
    /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/ios/native/
```

#### 2. Simulator Not Found

**Problem**: Script can't find the specified simulator.

**Solution**: List available simulators:
```bash
xcrun simctl list devices available | grep iPhone
```

Use an exact name:
```bash
./scripts/run_ios_simulator.sh "iPhone 14"
```

#### 3. Code Signing Failed

**Problem**: Device builds fail with signing errors.

**Solution**:
1. Open Xcode, add Apple ID in Preferences > Accounts
2. Update `.bazelrc.ios` with your signing identity:
   ```bash
   build:ios_device --ios_signing_cert_name="Apple Development"
   ```
3. Or use ad-hoc signing for local testing:
   ```bash
   build:ios_device --ios_signing_cert_name=-
   ```

#### 4. MapLibre Dependency Not Found

**Problem**: Build fails to find MapLibre framework.

**Solution**: Ensure MapLibre is configured in `MODULE.bazel` or `WORKSPACE`:
```python
# Add to MODULE.bazel
bazel_dep(name = "maplibre_native_ios", version = "6.0.0")
```

Or manually download MapLibre.xcframework and add to the project.

#### 5. App Crashes on Launch

**Problem**: App crashes immediately after launch.

**Solution**: Check logs for details:
```bash
# View crash logs
xcrun simctl spawn booted log stream --level debug

# Check for missing frameworks
otool -L bazel-bin/apps/omnitak_mobile_ios/OmniTAKMobile-Simulator.app/OmniTAKMobile
```

Common causes:
- Missing framework in `frameworks` attribute
- Incompatible architecture (arm64 vs x86_64)
- Missing permissions in Info.plist

#### 6. "Could not find or load main class" Error

**Problem**: Bazel fails with Java-related errors.

**Solution**: Check Java version:
```bash
java -version  # Should be Java 11 or 17
```

Update `.bazelrc`:
```bash
build --java_runtime_version=11
build --tool_java_runtime_version=17
```

#### 7. Xcode License Agreement

**Problem**: `xcodebuild` fails with license message.

**Solution**: Accept Xcode license:
```bash
sudo xcodebuild -license accept
```

### Debug Tips

1. **Verbose Build Output**
   ```bash
   bazel build //apps/omnitak_mobile_ios:OmniTAKMobile-Simulator \
       --config=ios_sim_debug \
       -s  # Show all commands
   ```

2. **Clean Build**
   ```bash
   bazel clean --expunge
   bazel build //apps/omnitak_mobile_ios:OmniTAKMobile-Simulator \
       --config=ios_sim_debug
   ```

3. **Check Dependencies**
   ```bash
   bazel query 'deps(//apps/omnitak_mobile_ios:OmniTAKMobile-Simulator)' \
       --output=tree
   ```

4. **Simulator Debugging**
   ```bash
   # Reset simulator to clean state
   xcrun simctl erase $SIMULATOR_UDID

   # Open simulator in debug mode
   open -a Simulator --args -CurrentDeviceUDID $SIMULATOR_UDID
   ```

## Advanced Topics

### Custom Build Configurations

Create custom build configs in `.bazelrc.ios`:

```bash
# Development build with debug symbols
build:ios_dev --config=ios_sim_debug
build:ios_dev --copt=-DDEBUG=1
build:ios_dev --swiftcopt=-DDEBUG

# Production build with optimizations
build:ios_prod --config=ios_dev_release
build:ios_prod --copt=-DRELEASE=1
build:ios_prod --swiftcopt=-whole-module-optimization
```

### Bitcode Support

Bitcode is deprecated in Xcode 14+, but if needed:

```bash
build:ios --copt=-fembed-bitcode
build:ios --swiftcopt=-embed-bitcode
```

### Framework Embedding

To embed additional frameworks, update `BUILD.bazel`:

```python
ios_application(
    name = "OmniTAKMobile",
    # ...
    frameworks = [
        "//modules/omnitak_mobile/ios/native:OmniTAKMobile.xcframework",
        "//third_party/frameworks:CustomFramework",
    ],
)
```

### Universal Builds

Build for both device and simulator:

```bash
# Device build
bazel build //apps/omnitak_mobile_ios:OmniTAKMobile \
    --config=ios_dev_release

# Simulator build
bazel build //apps/omnitak_mobile_ios:OmniTAKMobile-Simulator \
    --config=ios_sim_release

# Create fat framework (if needed)
lipo -create \
    device/OmniTAKMobile.framework/OmniTAKMobile \
    simulator/OmniTAKMobile.framework/OmniTAKMobile \
    -output universal/OmniTAKMobile.framework/OmniTAKMobile
```

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: iOS Build

on: [push, pull_request]

jobs:
  ios-build:
    runs-on: macos-13
    steps:
      - uses: actions/checkout@v3
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '14.3'
      - name: Build for Simulator
        run: ./scripts/build_ios.sh simulator release
      - name: Run Tests
        run: bazel test //apps/omnitak_mobile_ios:OmniTAKMobileTests \
            --config=ios_sim_debug
```

### Performance Profiling

Use Xcode Instruments to profile the app:

```bash
# Build with debug symbols
./scripts/build_ios.sh simulator debug

# Install on simulator
xcrun simctl install booted \
    bazel-bin/apps/omnitak_mobile_ios/OmniTAKMobile-Simulator.app

# Launch Instruments
open -a "Instruments"
# Select app and profiling template (Time Profiler, Allocations, etc.)
```

## Additional Resources

- [OmniTAK Mobile README](../../../modules/omnitak_mobile/README.md)
- [MapLibre Integration Guide](../../../modules/omnitak_mobile/ios/maplibre/INTEGRATION.md)
- [Bazel iOS Rules](https://github.com/bazelbuild/rules_apple)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [MapLibre Native iOS](https://github.com/maplibre/maplibre-native)

## Getting Help

If you encounter issues not covered in this guide:

1. Check the [troubleshooting section](#troubleshooting)
2. Review build logs for specific error messages
3. Consult the OmniTAK Mobile documentation
4. Open an issue on the project repository

## Next Steps

After successfully building and running the app:

1. **Configure TAK Server** - Update connection settings in `ViewController.swift`
2. **Test CoT Messaging** - Send and receive cursor-on-target messages
3. **Explore MapLibre** - Customize map styles and markers
4. **Integrate with Valdi** - Use the TypeScript bridge for UI
5. **Deploy to TestFlight** - Distribute to beta testers

Happy building!
