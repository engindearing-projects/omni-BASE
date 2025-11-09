# OmniTAK Mobile

Cross-platform TAK (Team Awareness Kit) client built with Valdi framework for native iOS and Android performance.

## Overview

OmniTAK Mobile is a modern, high-performance situational awareness application that provides full interoperability with TAK servers, ATAK, WinTAK, and iTAK devices. Built using Snap's Valdi framework, it delivers true native performance without sacrificing developer velocity.

## Features

- **Real-time CoT Message Handling**: Send and receive Cursor on Target messages in XML and Protobuf formats
- **Multi-Server Support**: Connect to multiple TAK servers simultaneously via omni-TAK backend
- **Certificate Management**: Secure TLS connections with automatic certificate provisioning
- **Interactive Mapping**: High-performance map rendering with MapLibre GL Native
- **MIL-STD-2525 Compliance**: Full support for military symbology and affiliation codes
- **Offline Capabilities**: Work without internet using cached map tiles and local data
- **Cross-Platform**: Single codebase compiles to native iOS and Android apps

## Architecture

```
┌─────────────────────────────────────────┐
│         TypeScript (Valdi)              │
│  ┌────────────┐  ┌──────────────────┐   │
│  │    UI      │  │   Services       │   │
│  │ Components │  │  - TakService    │   │
│  │            │  │  - CotParser     │   │
│  └────────────┘  └──────────────────┘   │
└────────────┬────────────────┬───────────┘
             │                │
    ┌────────▼───────┐   ┌────▼──────────┐
    │  MapLibre GL   │   │   omni-TAK    │
    │    Native      │   │   Rust FFI    │
    │  (custom-view) │   │               │
    └────────────────┘   └───────┬───────┘
                                 │
                         ┌───────▼───────┐
                         │  omni-TAK     │
                         │    Server     │
                         │  (Rust API)   │
                         └───────────────┘
```

## Project Structure

```
omnitak_mobile/
├── src/
│   ├── index.ts                    # Module entry point
│   └── valdi/omnitak/
│       ├── App.tsx                 # Main application component
│       ├── screens/
│       │   └── MapScreen.tsx       # Main map view
│       ├── components/             # Reusable UI components
│       └── services/
│           ├── TakService.ts       # FFI bridge to Rust
│           └── CotParser.ts        # CoT message handling
├── res/                            # Resources (images, icons)
├── BUILD.bazel                     # Bazel build configuration
├── module.yaml                     # Valdi module configuration
└── tsconfig.json                   # TypeScript configuration
```

## Building

### Prerequisites

- macOS (for iOS builds)
- Xcode 15+ (for iOS)
- Android Studio with NDK (for Android)
- Bazel 7+
- Rust toolchain with mobile targets

### iOS Build

```bash
cd /Users/iesouskurios/Downloads/omni-BASE

# Build for iOS
bazel build //modules/omnitak_mobile:omnitak_mobile --ios_output_target=release

# Run on simulator
bazel run //apps/ios:OmniTAK --ios_sdk=iphonesimulator
```

### Android Build

```bash
# Build for Android
bazel build //modules/omnitak_mobile:omnitak_mobile --android_output_target=release

# Build APK
bazel build //apps/android:OmniTAK
```

## Development

### Hot Reload

Valdi supports instant hot reload for rapid development:

```bash
# Start dev server
npm run dev

# Changes to .ts/.tsx files reload instantly
```

### Debugging

Use VSCode with Valdi's Hermes debugger integration:

1. Set breakpoints in TypeScript code
2. Launch app in debug mode
3. Debugger attaches automatically

## Dependencies

- **Valdi Core**: UI framework and component system
- **Valdi TSX**: Native template elements
- **omni-TAK Rust SDK**: TAK server connectivity and CoT processing
- **MapLibre GL Native**: Cross-platform map rendering
- **Platform Specific**:
  - iOS: Swift bindings, Keychain integration
  - Android: JNI bindings, Android Keystore

## Integration with omni-TAK

OmniTAK Mobile integrates with the omni-TAK Rust server for:

1. **Connection Aggregation**: Connect to multiple TAK servers through single API
2. **Certificate Management**: Auto-provision certificates from server
3. **Message Federation**: Centralized CoT message routing
4. **Metrics and Monitoring**: Real-time connection health and performance stats

### FFI Bridge

The Rust FFI bridge (`omnitak-mobile` crate) exposes C-compatible functions:

```rust
#[no_mangle]
pub extern "C" fn omnitak_connect(
    host: *const c_char,
    port: u16,
    cert_pem: *const c_char
) -> *mut Connection
```

TypeScript bindings are generated using Valdi's polyglot annotations:

```typescript
/**
 * @PolyglotModule
 * @ExportModel({
 *   ios: 'OmniTAKNative',
 *   android: 'com.engindearing.omnitak.native.OmniTAKNative'
 * })
 */
export interface OmniTAKNativeModule {
  connect(config: ServerConfig): Promise<number | null>;
  sendCot(connectionId: number, cotXml: string): Promise<boolean>;
}
```

## Roadmap

### Phase 1: Foundation (Complete)
- [x] Valdi project setup
- [x] TypeScript application skeleton
- [x] CoT parser and data structures
- [x] TakService FFI interface design

### Phase 2: Core Functionality (In Progress)
- [ ] Rust FFI bridge implementation
- [ ] MapLibre integration
- [ ] Basic map rendering
- [ ] CoT marker display

### Phase 3: TAK Integration
- [ ] Server connection management
- [ ] Certificate auto-provisioning
- [ ] Real-time message sync
- [ ] Multi-server support

### Phase 4: Advanced Features
- [ ] Offline maps
- [ ] Drawing tools
- [ ] Geofencing
- [ ] File attachments
- [ ] Video feeds

### Phase 5: Polish & Release
- [ ] Performance optimization
- [ ] Field testing
- [ ] App Store submission
- [ ] Documentation

## Contributing

This project is part of the omni-TAK ecosystem. See the main [omni-TAK repository](https://github.com/engindearing-projects/omni-TAK) for contribution guidelines.

## License

MIT License - See LICENSE file for details

## Related Projects

- [omni-TAK](https://github.com/engindearing-projects/omni-TAK) - Rust TAK server aggregator
- [omni-COT](https://github.com/engindearing-projects/omni-COT) - ATAK plugin for affiliation management
- [Valdi](https://github.com/Snapchat/valdi) - Cross-platform UI framework
