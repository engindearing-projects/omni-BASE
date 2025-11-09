# OmniTAK Mobile - Bazel Quick Reference

## Quick Start

```bash
# Build for iOS device
./build.sh ios-device

# Build for iOS simulator
./build.sh ios-simulator

# Build for Android
./build.sh android-arm64

# Build everything
./build.sh all

# Clean build
./build.sh clean
```

## Common Build Commands

### iOS

```bash
# Build module for iOS device
bazel build //modules/omnitak_mobile:omnitak_mobile \
  --platforms=@build_bazel_rules_apple//apple:ios_arm64

# Build module for iOS simulator (Apple Silicon Mac)
bazel build //modules/omnitak_mobile:omnitak_mobile \
  --platforms=@build_bazel_rules_apple//apple:ios_sim_arm64

# Build just the native bridge
bazel build //modules/omnitak_mobile:ios_native_bridge \
  --platforms=@build_bazel_rules_apple//apple:ios_arm64

# Build just the MapLibre wrapper
bazel build //modules/omnitak_mobile:ios_maplibre_wrapper \
  --platforms=@build_bazel_rules_apple//apple:ios_arm64
```

### Android

```bash
# Build module for Android ARM64
bazel build //modules/omnitak_mobile:omnitak_mobile \
  --platforms=@snap_platforms//platforms:android_arm64

# Build module for Android x86_64 emulator
bazel build //modules/omnitak_mobile:omnitak_mobile \
  --platforms=@snap_platforms//platforms:android_x86_64

# Build just the JNI bridge
bazel build //modules/omnitak_mobile:android_jni_bridge

# Build just the Kotlin bridge
bazel build //modules/omnitak_mobile:android_native_bridge

# Build just the MapLibre wrapper
bazel build //modules/omnitak_mobile:android_maplibre_wrapper
```

## Build Targets Reference

| Target Name | Description | Platform |
|------------|-------------|----------|
| `:omnitak_mobile` | Main module (TypeScript + native) | All |
| `:omnitak_mobile_kt` | Android Kotlin library | Android |
| `:omnitak_mobile_objc` | iOS Objective-C library | iOS |
| `:omnitak_mobile_swift` | iOS Swift library | iOS |
| `:ios_native_bridge` | Swift FFI bridge | iOS |
| `:ios_maplibre_wrapper` | MapLibre ObjC wrapper | iOS |
| `:android_native_bridge` | Kotlin FFI bridge | Android |
| `:android_jni_bridge` | JNI C++ bridge | Android |
| `:android_maplibre_wrapper` | MapLibre Kotlin wrapper | Android |
| `:omnitak_mobile_xcframework` | Rust static library | iOS |

## Query Commands

```bash
# List all targets
bazel query //modules/omnitak_mobile:all

# Show dependencies of main module
bazel query 'deps(//modules/omnitak_mobile:omnitak_mobile)'

# Show reverse dependencies (what depends on this module)
bazel query 'rdeps(//..., //modules/omnitak_mobile:omnitak_mobile)'

# Show build path between two targets
bazel query 'somepath(//modules/omnitak_mobile:omnitak_mobile, @valdi//valdi_core:valdi_core_objc)'

# Generate dependency graph
bazel query --output=graph //modules/omnitak_mobile:omnitak_mobile > deps.dot
dot -Tpng deps.dot -o deps.png
```

## Testing Commands

```bash
# Run module tests
bazel test //modules/omnitak_mobile:test

# Run tests with verbose output
bazel test //modules/omnitak_mobile:test --test_output=all

# Run tests in debug mode
bazel test //modules/omnitak_mobile:test --compilation_mode=dbg
```

## Build Flags

### Platform Selection

```bash
# iOS device (ARM64)
--platforms=@build_bazel_rules_apple//apple:ios_arm64

# iOS simulator (ARM64 - Apple Silicon Mac)
--platforms=@build_bazel_rules_apple//apple:ios_sim_arm64

# iOS simulator (x86_64 - Intel Mac)
--platforms=@build_bazel_rules_apple//apple:ios_x86_64

# Android ARM64
--platforms=@snap_platforms//platforms:android_arm64

# Android x86_64 (emulator)
--platforms=@snap_platforms//platforms:android_x86_64
```

### Compilation Modes

```bash
# Optimized build (default for release)
--compilation_mode=opt

# Debug build (with debug symbols)
--compilation_mode=dbg

# Fast build (minimal optimization)
--compilation_mode=fastbuild
```

### Debugging Flags

```bash
# Verbose error messages
--verbose_failures

# Show all subcommands
--subcommands

# Sandbox debugging
--sandbox_debug

# Keep build outputs
--keep_going

# Show execution log
--execution_log_binary_file=/tmp/exec.log
```

### Performance Flags

```bash
# Use local cache
--disk_cache=~/.cache/bazel

# Limit jobs (for machines with limited RAM)
--jobs=4

# Remote execution (if configured)
--remote_executor=grpc://your-remote-executor:8980
```

## Incremental Build Tips

```bash
# Build only changed files
bazel build //modules/omnitak_mobile:omnitak_mobile

# Force rebuild of specific target
bazel build --action_env=FORCE_REBUILD=1 //modules/omnitak_mobile:ios_native_bridge

# Clear analysis cache (if seeing stale dependency issues)
bazel sync --configure
```

## File Locations

### Source Files
```
modules/omnitak_mobile/
├── src/valdi/omnitak/          # TypeScript sources
├── ios/native/                 # Swift bridge + XCFramework
├── ios/maplibre/               # iOS MapLibre wrapper
├── android/native/             # Kotlin bridge + JNI
└── android/maplibre/           # Android MapLibre wrapper
```

### Build Outputs
```
bazel-bin/modules/omnitak_mobile/
├── omnitak_mobile              # Main module output
├── ios_native_bridge/          # Swift bridge artifacts
├── android_jni_bridge/         # JNI shared library
└── ...                         # Other generated files
```

### Generated Code (Valdi)
```
bazel-bin/modules/omnitak_mobile/
├── ios/debug/                  # iOS debug generated code
├── ios/release/                # iOS release generated code
├── android/debug/              # Android debug generated code
└── android/release/            # Android release generated code
```

## Cleaning Builds

```bash
# Clean all build artifacts
bazel clean

# Deep clean (removes all cached data)
bazel clean --expunge

# Clean specific target
bazel clean //modules/omnitak_mobile:omnitak_mobile

# Remove external dependencies cache
rm -rf ~/.cache/bazel
```

## Troubleshooting Quick Fixes

### "Cannot find module"
```bash
# Re-sync external dependencies
bazel sync

# Clear analysis cache
bazel clean --expunge
bazel build //modules/omnitak_mobile:omnitak_mobile
```

### "XCFramework not found"
```bash
# Rebuild Rust XCFramework
cd /Users/iesouskurios/Downloads/omni-TAK/crates/omnitak-mobile
./build_ios.sh

# Verify it exists
ls -la /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/ios/native/OmniTAKMobile.xcframework/
```

### "JNI symbols not found"
```bash
# Ensure alwayslink = True in BUILD.bazel
# Check that System.loadLibrary() is called in Kotlin code
```

### "Swift module not found"
```bash
# Check module_name matches import statements
# Verify @build_bazel_rules_swift is loaded in WORKSPACE
```

### "Build too slow"
```bash
# Use local cache
bazel build --disk_cache=~/.cache/bazel //modules/omnitak_mobile:omnitak_mobile

# Limit parallel jobs
bazel build --jobs=4 //modules/omnitak_mobile:omnitak_mobile

# Use remote cache (if available)
bazel build --remote_cache=https://your-cache //modules/omnitak_mobile:omnitak_mobile
```

## Environment Variables

```bash
# Set Bazel output base
export BAZEL_OUTPUT_BASE=~/.cache/bazel/omnitak

# Set Java heap size
export BAZEL_OPTS="-Xmx4g"

# Enable experimental features
export BAZEL_USE_CPP_ONLY_TOOLCHAIN=1

# Set Android SDK/NDK paths
export ANDROID_HOME=/path/to/android-sdk
export ANDROID_NDK_HOME=/path/to/android-ndk
```

## Integration with IDEs

### Xcode
```bash
# Generate Xcode project (if rules_xcodeproj is configured)
bazel run //:xcodeproj

# Or manually add to existing Xcode project
# Link bazel-bin/modules/omnitak_mobile/libomnitak_mobile.a
```

### Android Studio
```bash
# Generate Android Studio project
bazel run //:android_studio

# Or use Bazel plugin in Android Studio
# File -> Settings -> Plugins -> Search "Bazel"
```

### VS Code
```bash
# Install Bazel extension
# Cmd+Shift+P -> Install Extensions -> Search "Bazel"

# Configure .vscode/settings.json
{
  "bazel.executable": "/usr/local/bin/bazel",
  "bazel.buildifierExecutable": "/usr/local/bin/buildifier"
}
```

## Performance Profiling

```bash
# Generate build profile
bazel build //modules/omnitak_mobile:omnitak_mobile --profile=/tmp/profile.json

# Analyze profile
bazel analyze-profile /tmp/profile.json

# Generate HTML profile
bazel analyze-profile --html /tmp/profile.json > /tmp/profile.html
open /tmp/profile.html
```

## Remote Execution (if configured)

```bash
# Build using remote executor
bazel build \
  --remote_executor=grpc://your-executor:8980 \
  --remote_cache=grpc://your-cache:8980 \
  //modules/omnitak_mobile:omnitak_mobile

# Check remote cache stats
bazel build \
  --remote_cache=grpc://your-cache:8980 \
  --execution_log_binary_file=/tmp/exec.log \
  //modules/omnitak_mobile:omnitak_mobile

bazel analyze-profile /tmp/exec.log
```

## Useful Bazel Commands

```bash
# Show build info
bazel info

# Show Bazel version
bazel version

# Show build configuration
bazel config

# Dump BUILD file analysis
bazel dump //modules/omnitak_mobile:BUILD

# Print action graph
bazel aquery 'deps(//modules/omnitak_mobile:omnitak_mobile)'

# Show build event protocol
bazel build --build_event_text_file=/tmp/bep.txt //modules/omnitak_mobile:omnitak_mobile
```

## Helpful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# OmniTAK Mobile build aliases
alias omni-ios="bazel build //modules/omnitak_mobile:omnitak_mobile --platforms=@build_bazel_rules_apple//apple:ios_arm64"
alias omni-sim="bazel build //modules/omnitak_mobile:omnitak_mobile --platforms=@build_bazel_rules_apple//apple:ios_sim_arm64"
alias omni-android="bazel build //modules/omnitak_mobile:omnitak_mobile --platforms=@snap_platforms//platforms:android_arm64"
alias omni-clean="bazel clean"
alias omni-query="bazel query //modules/omnitak_mobile:all"
alias omni-test="bazel test //modules/omnitak_mobile:test"

# Bazel shortcuts
alias b="bazel"
alias bb="bazel build"
alias bt="bazel test"
alias bq="bazel query"
alias bc="bazel clean"
```

## Next Steps

1. **Build the module**: `./build.sh all`
2. **Run tests**: `./build.sh test`
3. **Check dependencies**: `./build.sh deps`
4. **Integrate with your app**: See `BUILD_CONFIGURATION.md`

## Documentation

- `BUILD_CONFIGURATION.md` - Detailed build configuration guide
- `README.md` - Module overview and usage
- `INTEGRATION.md` - Integration with Valdi applications
- `TROUBLESHOOTING.md` - Common issues and solutions

## Support

- Check `BUILD_CONFIGURATION.md` for detailed explanations
- Run `./build.sh --help` for build script options
- See Bazel documentation: https://bazel.build
