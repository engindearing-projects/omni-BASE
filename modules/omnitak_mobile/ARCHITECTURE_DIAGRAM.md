# OmniTAK Mobile - Polyglot Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Application Layer                            │
│                     (Valdi/TypeScript App)                           │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    TypeScript Service Layer                          │
│                                                                       │
│  TakService.ts (@PolyglotModule)                                    │
│  ├─ connect(config: ServerConfig): Promise<number>                  │
│  ├─ disconnect(connectionId: number): Promise<void>                 │
│  ├─ sendCot(connectionId: number, cotXml: string): Promise<boolean> │
│  ├─ registerCotCallback(connectionId, callback)                     │
│  ├─ getConnectionStatus(connectionId): Promise<ConnectionInfo>      │
│  └─ importCertificate(certPem, keyPem, caPem): Promise<string>      │
│                                                                       │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                    Valdi Polyglot Bridge
                    (Runtime Dependency Injection)
                               │
                ┌──────────────┴──────────────┐
                │                              │
                ↓                              ↓
┌───────────────────────────┐    ┌───────────────────────────┐
│    iOS Native Bridge      │    │  Android Native Bridge    │
│   (Swift + C FFI)         │    │  (Kotlin + JNI + C++)    │
│                           │    │                           │
│ OmniTAKNativeBridge.swift │    │ OmniTAKNativeBridge.kt   │
│ ├─ Singleton instance     │    │ ├─ Singleton instance     │
│ ├─ C FFI imports          │    │ ├─ JNI method decl.       │
│ ├─ Callback storage       │    │ ├─ Callback storage       │
│ ├─ Main queue dispatch    │    │ ├─ Coroutine support      │
│ ├─ Certificate storage    │    │ └─ Main dispatcher        │
│ └─ Thread safety (NSLock) │    │                           │
│                           │    │ omnitak_jni.cpp           │
│ Links to:                 │    │ ├─ JNI implementations    │
│ OmniTAKMobile.xcframework │    │ ├─ C callback bridge      │
│ └─ ios-arm64/             │    │ ├─ Thread attachment      │
│ └─ ios-arm64_x86_64-sim/  │    │ ├─ String conversion      │
│                           │    │ └─ Global ref mgmt        │
│                           │    │                           │
│                           │    │ CMakeLists.txt            │
│                           │    │ └─ Builds libomnitak      │
│                           │    │    _mobile.so             │
└─────────────┬─────────────┘    └─────────────┬─────────────┘
              │                                 │
              │      C FFI Interface            │
              │      (omnitak_mobile.h)         │
              │                                 │
              └────────────┬────────────────────┘
                           │
                           ↓
┌─────────────────────────────────────────────────────────────────────┐
│                     Rust Core Library                                │
│                   (omnitak-mobile crate)                             │
│                                                                       │
│  FFI Functions:                                                      │
│  ├─ omnitak_init() -> int32                                         │
│  ├─ omnitak_shutdown()                                              │
│  ├─ omnitak_connect(host, port, protocol, ...) -> uint64           │
│  ├─ omnitak_disconnect(connection_id) -> int32                      │
│  ├─ omnitak_send_cot(connection_id, cot_xml) -> int32              │
│  ├─ omnitak_register_callback(connection_id, callback, user_data)  │
│  ├─ omnitak_unregister_callback(connection_id) -> int32            │
│  ├─ omnitak_get_status(connection_id, status_out) -> int32         │
│  └─ omnitak_version() -> const char*                               │
│                                                                       │
│  Core Features:                                                      │
│  ├─ TAK Protocol Implementation (TCP, UDP, TLS, WebSocket)          │
│  ├─ CoT Message Parsing/Generation                                  │
│  ├─ TLS Certificate Management                                      │
│  ├─ Multi-threaded Network I/O                                      │
│  └─ Connection State Management                                     │
│                                                                       │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         Network Layer                                │
│                    (TAK Server Connections)                          │
│                                                                       │
│  ├─ TCP/UDP Sockets                                                 │
│  ├─ TLS/SSL Connections                                             │
│  ├─ WebSocket Connections                                           │
│  └─ Certificate Verification                                        │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Flow - Connect to Server

```
User Action (TypeScript)
  │
  ↓ takService.connect(config)
  │
  ├─[iOS]──────────────────────────────────────┐
  │                                             │
  │ OmniTAKNativeBridge.connect()              │
  │   │                                         │
  │   ↓ Dispatch to background queue           │
  │   │                                         │
  │   ↓ config.host.withCString { hostPtr in   │
  │       omnitak_connect(                     │
  │         hostPtr,                           │
  │         port,                              │
  │         protocol,                          │
  │         useTls,                            │
  │         certPem, keyPem, caPem             │
  │       )                                    │
  │     }                                       │
  │   │                                         │
  │   ↓                                         │
  │ Rust: Create connection, return ID         │
  │   │                                         │
  │   ↓                                         │
  │ Swift: Call completion(connectionId)       │
  │   │                                         │
  │   ↓                                         │
  │ TypeScript: Promise resolves with ID       │
  │                                             │
  └─────────────────────────────────────────────┘

  ├─[Android]──────────────────────────────────┐
  │                                             │
  │ OmniTAKNativeBridge.connect()              │
  │   │                                         │
  │   ↓ suspend fun, Dispatchers.IO            │
  │   │                                         │
  │   ↓ nativeConnect(                         │
  │       host: String,                        │
  │       port: Int,                           │
  │       protocol: Int,                       │
  │       useTls: Boolean,                     │
  │       certPem, keyPem, caPem               │
  │     )                                       │
  │   │                                         │
  │   ↓ JNI Bridge                             │
  │   │                                         │
  │   ↓ String conversion (JNI → C++)          │
  │   │                                         │
  │   ↓ omnitak_connect(...)                   │
  │   │                                         │
  │   ↓                                         │
  │ Rust: Create connection, return ID         │
  │   │                                         │
  │   ↓ JNI: Cast to jlong                     │
  │   │                                         │
  │   ↓ Kotlin: Return from suspend fun        │
  │   │                                         │
  │   ↓                                         │
  │ TypeScript: Promise resolves with ID       │
  │                                             │
  └─────────────────────────────────────────────┘
```

## Data Flow - Receive CoT Message

```
TAK Server sends CoT XML
  │
  ↓
Rust network thread receives data
  │
  ↓ Parse CoT XML
  │
  ↓ Find registered callback for connection_id
  │
  ↓ C callback function
  │
  ├─[iOS]──────────────────────────────────────┐
  │                                             │
  │ cot_callback_bridge(                       │
  │   user_data,                               │
  │   connection_id,                           │
  │   cot_xml: UnsafePointer<CChar>            │
  │ )                                           │
  │   │                                         │
  │   ↓ Convert C string to Swift String       │
  │   │                                         │
  │   ↓ DispatchQueue.main.async {             │
  │       bridge.callbacks[connId]?(xml)       │
  │     }                                       │
  │   │                                         │
  │   ↓                                         │
  │ Swift callback invoked on main queue       │
  │   │                                         │
  │   ↓                                         │
  │ Valdi bridge → TypeScript callback         │
  │   │                                         │
  │   ↓                                         │
  │ User callback(cotXml) executed             │
  │                                             │
  └─────────────────────────────────────────────┘

  ├─[Android]──────────────────────────────────┐
  │                                             │
  │ cot_callback_bridge(                       │
  │   user_data,                               │
  │   connection_id,                           │
  │   cot_xml: const char*                     │
  │ )                                           │
  │   │                                         │
  │   ↓ Get JNI environment                    │
  │   │                                         │
  │   ↓ Attach thread to JVM if needed         │
  │   │                                         │
  │   ↓ env->CallVoidMethod(                   │
  │       bridgeInstance,                      │
  │       onCotReceivedMethod,                 │
  │       connection_id,                       │
  │       env->NewStringUTF(cot_xml)           │
  │     )                                       │
  │   │                                         │
  │   ↓ Detach thread if we attached           │
  │   │                                         │
  │   ↓                                         │
  │ OmniTAKNativeBridge.onCotReceived()        │
  │   │                                         │
  │   ↓ scope.launch(Dispatchers.Main) {       │
  │       callbacks[connId]?.invoke(xml)       │
  │     }                                       │
  │   │                                         │
  │   ↓                                         │
  │ Kotlin callback on main thread             │
  │   │                                         │
  │   ↓                                         │
  │ Valdi bridge → TypeScript callback         │
  │   │                                         │
  │   ↓                                         │
  │ User callback(cotXml) executed             │
  │                                             │
  └─────────────────────────────────────────────┘
```

## Thread Safety Architecture

```
iOS Threading Model:
┌────────────────────────────────────┐
│ Main Queue (UI Thread)             │
│ - All callbacks executed here      │
│ - Safe for UI updates              │
│ - DispatchQueue.main.async         │
└──────────────┬─────────────────────┘
               ↑
               │ Dispatch
┌──────────────┴─────────────────────┐
│ Background Queue                   │
│ - C callback receives here         │
│ - String conversion                │
│ - Dispatch to main                 │
└──────────────┬─────────────────────┘
               ↑
               │ C callback
┌──────────────┴─────────────────────┐
│ Rust Background Thread             │
│ - Network I/O                      │
│ - CoT parsing                      │
│ - Callback invocation              │
└────────────────────────────────────┘

Synchronization:
- NSLock for initialization
- Serial queue for callback map
- Main queue for all user callbacks


Android Threading Model:
┌────────────────────────────────────┐
│ Main Thread (UI Thread)            │
│ - All callbacks executed here      │
│ - Safe for UI updates              │
│ - Dispatchers.Main                 │
└──────────────┬─────────────────────┘
               ↑
               │ Launch
┌──────────────┴─────────────────────┐
│ Kotlin Coroutine                   │
│ - onCotReceived() method           │
│ - Launch to Dispatchers.Main       │
└──────────────┬─────────────────────┘
               ↑
               │ JNI call
┌──────────────┴─────────────────────┐
│ JNI Bridge Thread                  │
│ - Attach to JVM                    │
│ - Call Kotlin method               │
│ - Detach from JVM                  │
└──────────────┬─────────────────────┘
               ↑
               │ C callback
┌──────────────┴─────────────────────┐
│ Rust Background Thread             │
│ - Network I/O                      │
│ - CoT parsing                      │
│ - Callback invocation              │
└────────────────────────────────────┘

Synchronization:
- ConcurrentHashMap for callback map
- std::mutex in C++ layer
- Global reference protection
- Main dispatcher for user callbacks
```

## Memory Management

```
iOS Memory Model:
┌────────────────────────────────────────────┐
│ Swift (ARC)                                │
│ ├─ OmniTAKNativeBridge (singleton)        │
│ ├─ Callbacks: [UInt64: (String)->Void]    │
│ │  └─ Automatic cleanup on disconnect     │
│ └─ Certificates: [String: Bundle]         │
│    └─ String copies, not references       │
└────────────────────────────────────────────┘
                    ↕
              withCString
                    ↕
┌────────────────────────────────────────────┐
│ C FFI                                      │
│ ├─ Temporary C strings (auto-cleanup)     │
│ ├─ Static strings from Rust (no cleanup)  │
│ └─ Function pointers                      │
└────────────────────────────────────────────┘
                    ↕
                  FFI
                    ↕
┌────────────────────────────────────────────┐
│ Rust                                       │
│ ├─ Connection state (Arc<Mutex<>>)        │
│ ├─ Callback storage (HashMap)             │
│ └─ Network buffers (Vec<u8>)              │
└────────────────────────────────────────────┘


Android Memory Model:
┌────────────────────────────────────────────┐
│ Kotlin (JVM GC)                            │
│ ├─ OmniTAKNativeBridge (singleton)        │
│ ├─ Callbacks: ConcurrentHashMap           │
│ │  └─ Removed on disconnect              │
│ └─ Certificates: ConcurrentHashMap        │
└────────────────────────────────────────────┘
                    ↕
              JNI calls
                    ↕
┌────────────────────────────────────────────┐
│ JNI Layer (C++)                            │
│ ├─ Global references (manually managed)   │
│ │  └─ DeleteGlobalRef on cleanup         │
│ ├─ Local references (auto-cleanup)        │
│ ├─ String conversion (copy to std::string)│
│ └─ Callback map: std::map + std::mutex    │
└────────────────────────────────────────────┘
                    ↕
                  FFI
                    ↕
┌────────────────────────────────────────────┐
│ Rust                                       │
│ ├─ Connection state (Arc<Mutex<>>)        │
│ ├─ Callback storage (HashMap)             │
│ └─ Network buffers (Vec<u8>)              │
└────────────────────────────────────────────┘
```

## Build System Integration

```
iOS Build Flow:
Developer
    ↓ cargo build --target aarch64-apple-ios
Rust Source
    ↓ Compile
libomnitak_mobile.a (arm64)
libomnitak_mobile.a (arm64-sim)
libomnitak_mobile.a (x86_64-sim)
    ↓ xcodebuild -create-xcframework
OmniTAKMobile.xcframework
    ↓ Add to Xcode project
Xcode Project
    ↓ Add OmniTAKNativeBridge.swift
Swift Bridge
    ↓ Xcode build
App.ipa
    ↓ App thinning
Deployed App (~2-3MB library)


Android Build Flow:
Developer
    ↓ cargo build --target aarch64-linux-android (etc.)
Rust Source
    ↓ Compile
libomnitak_mobile.a (arm64-v8a)
libomnitak_mobile.a (armeabi-v7a)
libomnitak_mobile.a (x86_64)
libomnitak_mobile.a (x86)
    ↓ Copy to android/native/lib/
Static Libraries
    ↓ ./gradlew build
Gradle
    ↓ Invoke CMake
CMake
    ↓ Compile omnitak_jni.cpp
    ↓ Link with libomnitak_mobile.a
libomnitak_mobile.so
    ↓ Package with OmniTAKNativeBridge.kt
APK/AAB
    ↓ App Bundle optimization
Deployed App (per-device ABI)
```

## Key Design Patterns

1. **Singleton Pattern**
   - Both iOS and Android bridges use singleton
   - Ensures single callback map instance
   - Thread-safe initialization

2. **Callback Registry**
   - Map connection ID to callback function
   - Thread-safe storage
   - Cleanup on disconnect

3. **Thread Dispatch**
   - All callbacks dispatched to main thread
   - Prevents race conditions
   - Safe for UI updates

4. **Memory Safety**
   - Automatic cleanup in Swift (ARC)
   - Manual cleanup in JNI (global refs)
   - No dangling pointers

5. **Error Propagation**
   - Rust Result → C error code → Platform check → TS null/false
   - Comprehensive logging at each layer

6. **Async/Await**
   - iOS: Completion handlers
   - Android: Kotlin coroutines
   - TypeScript: Promises

## File Organization

```
omnitak_mobile/
│
├── src/valdi/omnitak/services/
│   └── TakService.ts              # TypeScript API layer
│
├── ios/native/
│   ├── OmniTAKNativeBridge.swift  # Swift bridge
│   ├── omnitak_mobile.h           # C FFI header
│   ├── OmniTAKMobile.xcframework/ # Rust library
│   └── README.md                  # iOS guide
│
├── android/native/
│   ├── OmniTAKNativeBridge.kt     # Kotlin bridge
│   ├── omnitak_jni.cpp            # JNI implementation
│   ├── CMakeLists.txt             # Build config
│   ├── include/
│   │   └── omnitak_mobile.h       # C FFI header
│   └── README.md                  # Android guide
│
├── INTEGRATION.md                 # Integration guide
├── BUILD_GUIDE.md                 # Build instructions
├── POLYGLOT_IMPLEMENTATION_SUMMARY.md
├── IMPLEMENTATION_COMPLETE.md
└── ARCHITECTURE_DIAGRAM.md        # This file
```

---

This architecture provides a robust, thread-safe, and performant bridge between TypeScript and Rust for tactical awareness applications.
