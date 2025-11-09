# OmniTAK Mobile - iOS Native Bridge

This directory contains the iOS native bridge components for OmniTAK Mobile.

## Structure

```
ios/native/
├── README.md                        # This file
├── OmniTAKNativeBridge.swift       # Swift wrapper around C FFI
├── omnitak_mobile.h                # C FFI header from Rust
└── OmniTAKMobile.xcframework/      # Rust library for all iOS architectures
    ├── ios-arm64/                  # iPhone/iPad (device)
    │   └── libomnitak_mobile.a
    ├── ios-arm64_x86_64-simulator/ # Simulator (M1 + Intel)
    │   └── libomnitak_mobile.a
    └── Info.plist
```

## Components

### OmniTAKNativeBridge.swift

Swift bridge that:
- Declares C FFI imports from Rust library
- Converts between Swift and C types
- Manages callbacks from C to Swift
- Provides async completion handler API
- Handles certificate storage
- Implements singleton pattern for callback management

Key features:
- Thread-safe callback storage
- Main queue dispatch for callbacks
- Proper C string memory management
- Comprehensive error logging
- Singleton instance for global callback access

### omnitak_mobile.h

C header file that declares:
- FFI function signatures
- Data structures (ConnectionStatus)
- Protocol constants
- Callback function types

This header is generated from the Rust library and must match the compiled code.

### OmniTAKMobile.xcframework

XCFramework bundle containing:
- Static library for physical devices (arm64)
- Static library for simulator (arm64 + x86_64)
- Architecture-specific slices selected automatically by Xcode

## Building

### Prerequisites

1. **Xcode 14.0+**
   - Install from Mac App Store
   - Install Command Line Tools: `xcode-select --install`

2. **Rust Toolchain**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source $HOME/.cargo/env
   ```

3. **iOS Targets**
   ```bash
   rustup target add aarch64-apple-ios
   rustup target add aarch64-apple-ios-sim
   rustup target add x86_64-apple-ios
   ```

### Build XCFramework

From the omni-TAK directory:

```bash
cd crates/omnitak-mobile

# Build for all iOS targets
cargo build --release --target aarch64-apple-ios
cargo build --release --target aarch64-apple-ios-sim
cargo build --release --target x86_64-apple-ios

# Create XCFramework
cd ../..
xcodebuild -create-xcframework \
  -library target/aarch64-apple-ios/release/libomnitak_mobile.a \
  -library target/aarch64-apple-ios-sim/release/libomnitak_mobile.a \
  -library target/x86_64-apple-ios/release/libomnitak_mobile.a \
  -output target/OmniTAKMobile.xcframework

# Copy to module
cp -R target/OmniTAKMobile.xcframework \
  ../omni-BASE/modules/omnitak_mobile/ios/native/
```

See [BUILD_GUIDE.md](../../BUILD_GUIDE.md) for detailed instructions.

## Xcode Integration

### Add to Project

1. **Add Framework:**
   - In Xcode Project Navigator, right-click your project
   - Select "Add Files to [Project]..."
   - Navigate to `modules/omnitak_mobile/ios/native/`
   - Select `OmniTAKMobile.xcframework`
   - **Important:** Uncheck "Copy items if needed"
   - Click "Add"

2. **Add Swift Bridge:**
   - Right-click your project
   - Select "Add Files to [Project]..."
   - Select `OmniTAKNativeBridge.swift`
   - Ensure it's added to your app target
   - Click "Add"

### Link Framework

1. Select your project in Navigator
2. Select your app target
3. Go to "General" tab
4. Under "Frameworks, Libraries, and Embedded Content":
   - Verify `OmniTAKMobile.xcframework` is listed
   - Set to "Do Not Embed" (static library, embedded in binary)

### Build Settings

Recommended settings:

- **iOS Deployment Target**: 13.0 or higher
- **Swift Language Version**: Swift 5
- **Always Embed Swift Standard Libraries**: YES
- **Enable Bitcode**: NO (Rust doesn't support bitcode)

## Usage from Swift

### Initialize

```swift
let bridge = OmniTAKNativeBridge()
```

### Get Version

```swift
let version = bridge.getVersion()
print("OmniTAK version: \(version)")
```

### Connect to Server

```swift
let config: [String: Any] = [
    "host": "192.168.1.100",
    "port": 8087,
    "protocol": "tcp",
    "useTls": false,
    "reconnect": true,
    "reconnectDelayMs": 5000
]

bridge.connect(config: config) { connectionId in
    if let id = connectionId {
        print("Connected: \(id)")
    } else {
        print("Connection failed")
    }
}
```

### Register Callback

```swift
bridge.registerCotCallback(connectionId: connectionId) { cotXml in
    // Called on main queue when CoT received
    print("Received CoT: \(cotXml)")
}
```

### Send CoT

```swift
bridge.sendCot(connectionId: connectionId, cotXml: cotXml) { success in
    if success {
        print("CoT sent successfully")
    }
}
```

### Get Status

```swift
bridge.getConnectionStatus(connectionId: connectionId) { status in
    if let status = status {
        print("Status: \(status["status"] ?? "unknown")")
        print("Messages sent: \(status["messagesSent"] ?? 0)")
        print("Messages received: \(status["messagesReceived"] ?? 0)")
    }
}
```

### Import Certificate

```swift
bridge.importCertificate(
    certPem: certPemString,
    keyPem: keyPemString,
    caPem: caPemString
) { certId in
    if let id = certId {
        print("Certificate imported: \(id)")
        // Use certId in connection config
    }
}
```

### Disconnect

```swift
bridge.disconnect(connectionId: connectionId) {
    print("Disconnected")
}
```

## Thread Safety

### Callback Threading

The callback flow ensures thread safety:

1. **Rust Layer**: Callbacks originate from Rust background threads
2. **C Callback**: C function pointer invoked on background thread
3. **Swift Bridge**: Detects thread context
4. **Main Queue**: Dispatches callback to `DispatchQueue.main`
5. **Application**: Callback executed on main thread (safe for UI)

```swift
let cCallback: @convention(c) (...) -> Void = { ... in
    DispatchQueue.main.async {
        // Safe to update UI here
        swiftCallback(xml)
    }
}
```

### Synchronization

- **Initialization**: Protected by `NSLock`
- **Callback storage**: Synchronized via `DispatchQueue` (serial)
- **Certificate storage**: Thread-safe dictionary

## Memory Management

### C String Conversion

**Swift → C:**
```swift
let connectionId = host.withCString { hostPtr in
    omnitak_connect(hostPtr, ...)
}
// hostPtr automatically deallocated after block
```

**C → Swift:**
```swift
let version = String(cString: omnitak_version())
// No manual deallocation needed for static strings from Rust
```

### Callback Lifetime

```swift
// Store callback with connection ID
callbacks[connectionId] = callback

// Remove on disconnect
callbacks.removeValue(forKey: connectionId)
```

### Certificate Storage

```swift
// Certificates stored as Swift strings (copied)
certificates[certId] = CertificateBundle(
    certPem: certPem,
    keyPem: keyPem,
    caPem: caPem
)
```

## Swift/Objective-C Interoperability

### Using from Objective-C

The bridge is exposed to Objective-C via `@objc` attributes:

```objc
// Import Swift header
#import "YourProject-Swift.h"

// Use bridge
OmniTAKNativeBridge *bridge = [[OmniTAKNativeBridge alloc] init];

NSDictionary *config = @{
    @"host": @"192.168.1.100",
    @"port": @8087,
    @"protocol": @"tcp",
    @"useTls": @NO
};

[bridge connectWithConfig:config completion:^(NSNumber *connectionId) {
    if (connectionId) {
        NSLog(@"Connected: %@", connectionId);
    }
}];
```

### Bridging Header

If mixing C code, create a bridging header:

**YourProject-Bridging-Header.h:**
```objc
#import "omnitak_mobile.h"
```

Add to Build Settings:
- Objective-C Bridging Header: `YourProject-Bridging-Header.h`

## Debugging

### Enable Logging

The bridge includes comprehensive logging:

```swift
print("[OmniTAK] Connected successfully: \(connectionId)")
print("[OmniTAK] Callback registered for connection \(connectionId)")
print("[OmniTAK] CoT sent on connection \(connectionId)")
```

### Xcode Console

View logs in Xcode Console (⌘+⇧+C):
```
[OmniTAK] Native library initialized successfully
[OmniTAK] Connected successfully: 1
[OmniTAK] Callback registered for connection 1
[OmniTAK] CoT sent on connection 1
```

### Common Issues

**Issue: Framework not found**
```
ld: framework not found OmniTAKMobile
```
**Solution:**
- Verify framework is in correct location
- Check framework is added to target
- Clean build folder: Product → Clean Build Folder (⌘+⇧+K)

**Issue: Undefined symbols**
```
Undefined symbol: _omnitak_init
```
**Solution:**
- Ensure XCFramework contains static library
- Verify correct architecture is being built
- Check framework is linked in Build Phases

**Issue: Module not found**
```
No such module 'valdi_core'
```
**Solution:**
- Ensure Valdi core is built and linked
- Check import paths in Build Settings
- Verify module is in Framework Search Paths

## Performance

### Library Size

XCFramework size:
- Device (arm64): ~2-3 MB
- Simulator (arm64 + x86_64): ~4-6 MB
- Total: ~6-9 MB

### Optimization

For release builds, ensure:

1. **Rust Optimization:**
   ```toml
   # In Cargo.toml
   [profile.release]
   opt-level = "z"      # Optimize for size
   lto = true           # Link-time optimization
   codegen-units = 1    # Better optimization
   strip = true         # Strip symbols
   ```

2. **Xcode Optimization:**
   - Build Configuration: Release
   - Optimization Level: Fastest, Smallest [-Os]
   - Strip Debug Symbols: YES
   - Strip Swift Symbols: YES

### App Thinning

Xcode automatically:
- Selects correct architecture slice
- Removes unused architectures from final app
- Results in ~2-3 MB in shipped app

## Testing

### Unit Tests

Test the Swift bridge:

```swift
import XCTest
@testable import YourModule

class OmniTAKBridgeTests: XCTestCase {

    func testInitialization() {
        let bridge = OmniTAKNativeBridge()
        XCTAssertNotNil(bridge)
    }

    func testVersion() {
        let bridge = OmniTAKNativeBridge()
        let version = bridge.getVersion()
        XCTAssertFalse(version.isEmpty)
        print("Version: \(version)")
    }

    func testConnect() {
        let bridge = OmniTAKNativeBridge()
        let expectation = self.expectation(description: "Connect")

        let config: [String: Any] = [
            "host": "localhost",
            "port": 8087,
            "protocol": "tcp",
            "useTls": false
        ]

        bridge.connect(config: config) { connectionId in
            // May be nil if server not running
            // Just verify no crash
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }
}
```

### Integration Tests

Test with real TAK server:

```swift
func testRealConnection() {
    let bridge = OmniTAKNativeBridge()
    let expectation = self.expectation(description: "Real connection")

    let config: [String: Any] = [
        "host": "192.168.1.100",
        "port": 8087,
        "protocol": "tcp",
        "useTls": false
    ]

    bridge.connect(config: config) { connectionId in
        XCTAssertNotNil(connectionId, "Should connect to real server")

        if let id = connectionId {
            // Test status
            bridge.getConnectionStatus(connectionId: Int(id)) { status in
                XCTAssertNotNil(status)
                XCTAssertEqual(status?["status"] as? String, "connected")

                // Disconnect
                bridge.disconnect(connectionId: Int(id)) {
                    expectation.fulfill()
                }
            }
        } else {
            expectation.fulfill()
        }
    }

    waitForExpectations(timeout: 10.0)
}
```

## SwiftUI Integration

Example SwiftUI view:

```swift
import SwiftUI

class TakViewModel: ObservableObject {
    @Published var connectionStatus = "Disconnected"
    @Published var receivedMessages: [String] = []

    private let bridge = OmniTAKNativeBridge()
    private var connectionId: Int?

    func connect(host: String, port: Int) {
        let config: [String: Any] = [
            "host": host,
            "port": port,
            "protocol": "tcp",
            "useTls": false
        ]

        bridge.connect(config: config) { [weak self] id in
            if let id = id {
                self?.connectionId = Int(id)
                self?.connectionStatus = "Connected"

                // Register callback
                self?.bridge.registerCotCallback(connectionId: Int(id)) { xml in
                    self?.receivedMessages.append(xml)
                }
            }
        }
    }

    func disconnect() {
        if let id = connectionId {
            bridge.disconnect(connectionId: id) { [weak self] in
                self?.connectionStatus = "Disconnected"
                self?.connectionId = nil
            }
        }
    }
}

struct TakView: View {
    @StateObject var viewModel = TakViewModel()

    var body: some View {
        VStack {
            Text("Status: \(viewModel.connectionStatus)")

            Button("Connect") {
                viewModel.connect(host: "192.168.1.100", port: 8087)
            }

            Button("Disconnect") {
                viewModel.disconnect()
            }

            List(viewModel.receivedMessages, id: \.self) { msg in
                Text(msg)
                    .font(.system(.caption, design: .monospaced))
            }
        }
    }
}
```

## Further Reading

- [Swift C Interoperability](https://developer.apple.com/documentation/swift/imported_c_and_objective-c_apis)
- [XCFramework Guide](https://developer.apple.com/documentation/xcode/creating-a-multi-platform-binary-framework-bundle)
- [Dispatch Queues](https://developer.apple.com/documentation/dispatch/dispatchqueue)
- [Integration Guide](../../INTEGRATION.md)
- [Build Guide](../../BUILD_GUIDE.md)
