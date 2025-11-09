# OmniTAK Mobile - Android Native Bridge

This directory contains the Android native bridge components for OmniTAK Mobile.

## Structure

```
android/native/
├── README.md                        # This file
├── CMakeLists.txt                   # CMake build configuration
├── omnitak_jni.cpp                  # JNI bridge implementation
├── OmniTAKNativeBridge.kt          # Kotlin wrapper
├── include/
│   └── omnitak_mobile.h            # C FFI header from Rust
└── lib/
    ├── arm64-v8a/                  # 64-bit ARM (modern devices)
    │   └── libomnitak_mobile.a
    ├── armeabi-v7a/                # 32-bit ARM (older devices)
    │   └── libomnitak_mobile.a
    ├── x86_64/                     # 64-bit Intel (emulator)
    │   └── libomnitak_mobile.a
    └── x86/                        # 32-bit Intel (legacy)
        └── libomnitak_mobile.a
```

## Components

### OmniTAKNativeBridge.kt

Kotlin bridge that:
- Declares JNI native methods
- Manages callbacks from native to Kotlin
- Provides coroutine-based async API
- Handles certificate storage
- Implements singleton pattern for callback management

Key features:
- Thread-safe callback storage
- Automatic JNI library loading
- Coroutine support for async operations
- Comprehensive error handling and logging

### omnitak_jni.cpp

JNI implementation that:
- Bridges between Kotlin/Java and Rust C FFI
- Converts JNI strings to C strings and vice versa
- Manages callbacks from Rust background threads
- Attaches/detaches threads to/from JVM as needed
- Maintains global references for callback objects

Key features:
- Thread-safe callback map with mutex protection
- Automatic JVM thread attachment
- Comprehensive Android logging
- Proper JNI reference management

### CMakeLists.txt

CMake configuration that:
- Builds JNI bridge as shared library
- Links with pre-built Rust static libraries
- Supports all Android ABIs
- Configures include directories
- Sets up compiler flags

## Building

### Prerequisites

1. **Android NDK r21+**
   - Install via Android Studio SDK Manager
   - Or download from: https://developer.android.com/ndk/downloads

2. **CMake 3.18.1+**
   - Install via Android Studio SDK Manager

3. **Rust Libraries**
   - Build Rust libraries for all Android targets
   - Place in `lib/${ABI}/libomnitak_mobile.a`
   - See [BUILD_GUIDE.md](../../BUILD_GUIDE.md) for instructions

### Build Process

The native library is built automatically by Gradle when you build the Android app:

```bash
# From Android project root
./gradlew assembleDebug
```

This will:
1. Run CMake to configure the build
2. Compile `omnitak_jni.cpp`
3. Link with Rust static libraries
4. Produce `libomnitak_mobile.so` for each ABI
5. Package into APK

### Manual CMake Build

For debugging, you can build manually:

```bash
# Create build directory
mkdir -p build/arm64-v8a
cd build/arm64-v8a

# Configure
cmake ../.. \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-21 \
  -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build .
```

## Gradle Integration

Add to your `app/build.gradle`:

```gradle
android {
    defaultConfig {
        ndk {
            abiFilters 'arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'
        }
    }

    externalNativeBuild {
        cmake {
            path "path/to/modules/omnitak_mobile/android/native/CMakeLists.txt"
            version "3.18.1"
        }
    }
}
```

## Usage from Kotlin

### Initialize

```kotlin
val bridge = OmniTAKNativeBridge.getInstance()
```

### Connect to Server

```kotlin
val config = OmniTAKNativeBridge.ServerConfig(
    host = "192.168.1.100",
    port = 8087,
    protocol = "tcp",
    useTls = false,
    reconnect = true,
    reconnectDelayMs = 5000
)

val connectionId = bridge.connect(config)
if (connectionId != null) {
    println("Connected: $connectionId")
}
```

### Register Callback

```kotlin
bridge.registerCotCallback(connectionId) { cotXml ->
    // Called on main thread when CoT received
    println("Received CoT: $cotXml")
}
```

### Send CoT

```kotlin
val success = bridge.sendCot(connectionId, cotXml)
if (success) {
    println("CoT sent successfully")
}
```

### Disconnect

```kotlin
bridge.disconnect(connectionId)
```

## Thread Safety

### Callback Threading

1. **Rust Layer**: Callbacks originate from Rust background threads
2. **JNI Layer**: Threads are attached to JVM, callback dispatched
3. **Kotlin Layer**: Callback dispatched to `Dispatchers.Main`
4. **Application**: Callback executed on main thread

This ensures callbacks are always safe for UI updates.

### Synchronization

- **Callback map**: Protected by C++ `std::mutex`
- **Kotlin collections**: Use `ConcurrentHashMap`
- **JNI references**: Global references managed with locks

## Memory Management

### JNI References

- **Local references**: Created/deleted within JNI call
- **Global references**: Created for callback objects, deleted on disconnect
- All references properly managed to prevent leaks

### Strings

- **Kotlin → JNI**: Converted via `GetStringUTFChars`
- **JNI → C++**: Copied to `std::string`
- **C++ → JNI**: Converted via `NewStringUTF`
- All conversions properly released

### Lifecycle

```kotlin
// On app start
val bridge = OmniTAKNativeBridge.getInstance()

// On activity destroy
bridge.shutdown()
```

## Debugging

### Enable Verbose Logging

Modify log level in `omnitak_jni.cpp`:

```cpp
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
```

### View Logs

```bash
# Filter for OmniTAK logs
adb logcat | grep "OmniTAK"

# Or use Android Studio Logcat
```

### Common Log Messages

```
I/OmniTAK-JNI: JNI_OnLoad called
I/OmniTAKNative: Native library loaded successfully
I/OmniTAKNative: Native library initialized successfully
I/OmniTAK-JNI: Connecting to 192.168.1.100:8087 (protocol=0, tls=0)
I/OmniTAK-JNI: Connected successfully: 1
D/OmniTAK-JNI: CoT callback triggered for connection 1
D/OmniTAKNative: CoT received on connection 1
```

## Troubleshooting

### Library Not Loaded

**Error:**
```
java.lang.UnsatisfiedLinkError: couldn't find DSO to load: libomnitak_mobile.so
```

**Solutions:**
1. Check CMakeLists.txt path in build.gradle
2. Verify Rust libraries exist in `lib/${ABI}/`
3. Clean and rebuild: `./gradlew clean assembleDebug`
4. Check build output for CMake errors

### Method Not Found

**Error:**
```
java.lang.UnsatisfiedLinkError: No implementation found for int nativeInit()
```

**Solutions:**
1. Verify JNI function signature matches Kotlin declaration
2. Check package name in JNI function name:
   ```cpp
   Java_com_engindearing_omnitak_native_OmniTAKNativeBridge_nativeInit
   ```
3. Rebuild native library

### Callback Crashes

**Error:**
```
A/libc: Fatal signal 11 (SIGSEGV), code 1
```

**Solutions:**
1. Check JVM thread attachment
2. Verify global reference is valid
3. Check for JNI exceptions: `env->ExceptionCheck()`
4. Ensure callback object hasn't been garbage collected

### Missing Rust Library

**Warning:**
```
CMake Warning: Rust library directory not found
```

**Solutions:**
1. Build Rust libraries: see [BUILD_GUIDE.md](../../BUILD_GUIDE.md)
2. Copy to correct location: `lib/${ABI}/libomnitak_mobile.a`
3. Verify ABI matches: arm64-v8a, armeabi-v7a, x86_64, x86

## Performance

### Library Size

Typical sizes per ABI:
- arm64-v8a: ~2-3 MB
- armeabi-v7a: ~2-3 MB
- x86_64: ~3-4 MB
- x86: ~2-3 MB

Total: ~10-15 MB for all ABIs

### Optimization

For release builds, CMake applies:
- `-Wl,--gc-sections`: Remove unused sections
- `-Wl,--strip-all`: Strip debug symbols
- Link-time optimization (LTO) via Rust

### ABI Filtering

To reduce APK size, limit ABIs:

```gradle
android {
    defaultConfig {
        ndk {
            // Only include 64-bit ARM (most common)
            abiFilters 'arm64-v8a'
        }
    }
}
```

Or use App Bundles for per-device optimization.

## Testing

### Unit Tests

Test native bridge with Robolectric:

```kotlin
@RunWith(RobolectricTestRunner::class)
class OmniTAKNativeTest {
    @Test
    fun testVersion() {
        val bridge = OmniTAKNativeBridge.getInstance()
        val version = bridge.getVersion()
        assertNotNull(version)
        assertTrue(version.isNotEmpty())
    }
}
```

### Instrumented Tests

Test on device/emulator:

```kotlin
@RunWith(AndroidJUnit4::class)
class OmniTAKInstrumentedTest {
    @Test
    fun testConnect() = runBlocking {
        val bridge = OmniTAKNativeBridge.getInstance()
        val config = OmniTAKNativeBridge.ServerConfig(
            host = "localhost",
            port = 8087,
            protocol = "tcp",
            useTls = false,
            reconnect = false,
            reconnectDelayMs = 0
        )
        val connectionId = bridge.connect(config)
        // May be null if server not running
        // Just verify no crash
    }
}
```

## Further Reading

- [Android JNI Guide](https://developer.android.com/training/articles/perf-jni)
- [CMake Android Build](https://developer.android.com/ndk/guides/cmake)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [Integration Guide](../../INTEGRATION.md)
- [Build Guide](../../BUILD_GUIDE.md)
