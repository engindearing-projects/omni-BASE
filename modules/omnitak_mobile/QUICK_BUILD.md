# OmniTAK Mobile - Quick Build Guide

This guide provides quick instructions for building the OmniTAK Mobile module with Bazel.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Build Scripts](#build-scripts)
- [Common Build Commands](#common-build-commands)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

## Prerequisites

### Required Tools

- **Bazel 7.2.1** - Build system
- **Node.js 16+** - JavaScript runtime
- **Git** - Version control

### Platform-Specific Requirements

#### For Android Builds
- **Java 11+** - Android build tools
- **Android SDK** - API level 35
- **Android NDK** - For native code

#### For iOS Builds (macOS only)
- **Xcode** - Apple development tools
- **Xcode Command Line Tools**

### Optional Tools

- **yq** - YAML validation
- **jq** - JSON validation
- **TypeScript** - Type checking

## Quick Start

### 1. Check Dependencies

Run the dependency checker to verify your environment:

```bash
cd /Users/iesouskurios/Downloads/omni-BASE
./scripts/check_dependencies.sh
```

This will check all required tools and dependencies.

### 2. Validate Build Configuration

Verify that all build files are properly configured:

```bash
./scripts/validate_build_config.sh
```

### 3. Build the Module

Build the entire module (all platforms):

```bash
./scripts/build_omnitak_mobile.sh
```

Or build for specific platforms:

```bash
# Android only
./scripts/build_omnitak_mobile.sh --android

# iOS only
./scripts/build_omnitak_mobile.sh --ios

# Debug mode
./scripts/build_omnitak_mobile.sh --debug
```

## Build Scripts

The following scripts are available in `/Users/iesouskurios/Downloads/omni-BASE/scripts/`:

### validate_build_config.sh

Validates the build configuration before building.

```bash
./scripts/validate_build_config.sh
```

**What it checks:**
- Workspace configuration (WORKSPACE, MODULE.bazel)
- Module structure and files
- Dependencies (valdi_core, valdi_tsx)
- TypeScript configuration
- Android/iOS configurations

### check_dependencies.sh

Checks all required dependencies and tools.

```bash
./scripts/check_dependencies.sh
```

**What it checks:**
- Core build tools (Bazel, Git, Node.js)
- Platform tools (Java, Xcode, Android SDK/NDK)
- Valdi module dependencies
- MapLibre frameworks
- npm packages

### build_omnitak_mobile.sh

Performs an incremental build of the module.

```bash
# Build all platforms in release mode
./scripts/build_omnitak_mobile.sh

# Build Android in debug mode
./scripts/build_omnitak_mobile.sh --android --debug

# Build iOS with verbose output
./scripts/build_omnitak_mobile.sh --ios --verbose
```

**Options:**
- `--debug` - Build in debug mode
- `--release` - Build in release mode (default)
- `--android` - Build only Android targets
- `--ios` - Build only iOS targets
- `--verbose, -v` - Enable verbose output
- `--help, -h` - Show help message

### clean_build_omnitak_mobile.sh

Performs a clean build from scratch.

```bash
# Clean module and rebuild
./scripts/clean_build_omnitak_mobile.sh

# Full clean and rebuild
./scripts/clean_build_omnitak_mobile.sh --full

# Clean only, don't rebuild
./scripts/clean_build_omnitak_mobile.sh --skip-build
```

**Options:**
- `--module` - Clean only module outputs (default)
- `--cache` - Clean Bazel cache
- `--full` - Full workspace clean (slow)
- `--skip-build` - Clean only, don't rebuild
- `--debug` - Rebuild in debug mode
- `--release` - Rebuild in release mode (default)

## Common Build Commands

### Using Bazel Directly

If you prefer to use Bazel commands directly:

```bash
cd /Users/iesouskurios/Downloads/omni-BASE

# Build the main module
bazel build //modules/omnitak_mobile:omnitak_mobile

# Build Android targets
bazel build //modules/omnitak_mobile:omnitak_mobile_kt

# Build iOS targets
bazel build //modules/omnitak_mobile:omnitak_mobile_objc

# Build with debug symbols
bazel build --compilation_mode=dbg //modules/omnitak_mobile:omnitak_mobile

# Build with optimizations
bazel build --compilation_mode=opt //modules/omnitak_mobile:omnitak_mobile

# Clean build
bazel clean

# Full clean (removes all caches)
bazel clean --expunge
```

### Build Specific Targets

```bash
# Android valdimodule (release)
bazel build //modules/omnitak_mobile:android.release.valdimodule

# Android valdimodule (debug)
bazel build //modules/omnitak_mobile:android.debug.valdimodule

# iOS valdimodule (release)
bazel build //modules/omnitak_mobile:ios.release.valdimodule

# iOS valdimodule (debug)
bazel build //modules/omnitak_mobile:ios.debug.valdimodule

# Android Kotlin library
bazel build //modules/omnitak_mobile:omnitak_mobile_kt

# iOS Objective-C library
bazel build //modules/omnitak_mobile:omnitak_mobile_objc
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Bazel Version Mismatch

**Error:** Bazel version doesn't match `.bazelversion`

**Solution:**
```bash
# Check required version
cat /Users/iesouskurios/Downloads/omni-BASE/.bazelversion

# Install correct version (macOS)
brew install bazel@7.2.1
```

#### 2. Missing Dependencies

**Error:** Cannot find `valdi_core` or `valdi_tsx`

**Solution:**
```bash
# Check dependencies exist
ls -la /Users/iesouskurios/Downloads/omni-BASE/src/valdi_modules/src/valdi/

# Verify BUILD.bazel files exist
ls -la /Users/iesouskurios/Downloads/omni-BASE/src/valdi_modules/src/valdi/valdi_core/BUILD.bazel
ls -la /Users/iesouskurios/Downloads/omni-BASE/src/valdi_modules/src/valdi/valdi_tsx/BUILD.bazel
```

#### 3. TypeScript Compilation Errors

**Error:** TypeScript files fail to compile

**Solution:**
```bash
# Check TypeScript configuration
cat /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/tsconfig.json

# Verify source files exist
find /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/src -name "*.ts" -o -name "*.tsx"
```

#### 4. Android SDK Not Found

**Error:** Android SDK not configured

**Solution:**
```bash
# Set Android SDK environment variables
export ANDROID_HOME=/path/to/android/sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME

# Add to ~/.bashrc or ~/.zshrc for persistence
```

#### 5. iOS Build Fails (macOS only)

**Error:** Xcode or command line tools not found

**Solution:**
```bash
# Install Xcode command line tools
xcode-select --install

# Set Xcode path
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

#### 6. MapLibre Not Found

**Error:** Cannot find MapLibre framework/library

**Solution:**

For iOS:
```bash
# Check if XCFramework exists
ls -la /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/ios/maplibre/MapLibre.xcframework
```

For Android:
```bash
# Check if AAR exists
ls -la /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/android/maplibre/
```

If missing, you'll need to:
1. Download MapLibre SDK for your platform
2. Place it in the appropriate directory
3. Update BUILD.bazel if necessary

#### 7. Bazel Cache Issues

**Error:** Inconsistent build state or stale artifacts

**Solution:**
```bash
# Clean cache and rebuild
./scripts/clean_build_omnitak_mobile.sh --cache

# Or full clean
./scripts/clean_build_omnitak_mobile.sh --full
```

#### 8. Out of Disk Space

**Error:** No space left on device

**Solution:**
```bash
# Check disk space
df -h

# Clean Bazel cache
bazel clean --expunge

# Remove old build artifacts
rm -rf /Users/iesouskurios/Downloads/omni-BASE/bazel-*
```

#### 9. Permission Denied

**Error:** Permission denied when running scripts

**Solution:**
```bash
# Make scripts executable
chmod +x /Users/iesouskurios/Downloads/omni-BASE/scripts/*.sh
```

#### 10. Module YAML Syntax Error

**Error:** Cannot parse module.yaml

**Solution:**
```bash
# Validate YAML syntax
cat /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/module.yaml

# If yq is installed
yq eval '.' /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/module.yaml
```

### Getting More Help

If you encounter other issues:

1. **Check logs**: Look at Bazel output for detailed error messages
2. **Verbose build**: Run with `--verbose` flag for more details
3. **Validate config**: Run `./scripts/validate_build_config.sh`
4. **Check dependencies**: Run `./scripts/check_dependencies.sh`
5. **Clean rebuild**: Try `./scripts/clean_build_omnitak_mobile.sh --full`

## Next Steps

After successfully building OmniTAK Mobile:

### Integration

1. **Read Integration Guide**: See `INTEGRATION.md` for details on integrating the module into your app
2. **Review Architecture**: Check `ARCHITECTURE_DIAGRAM.md` to understand the module structure
3. **MapLibre Integration**: See `MAPLIBRE_IMPLEMENTATION_SUMMARY.md` for MapLibre setup

### Development

1. **Quick Start**: See `QUICK_START.md` for development workflow
2. **Marker System**: Review `MARKER_SYSTEM_README.md` for marker functionality
3. **Implementation**: Check `IMPLEMENTATION_SUMMARY.md` for implementation details

### Testing

```bash
# Run module tests (if available)
bazel test //modules/omnitak_mobile:test

# Run with hot reload during development
bazel build //modules/omnitak_mobile:omnitak_mobile_hotreload
```

### Build Outputs

After a successful build, you'll find outputs in:

- **Bazel outputs**: `/Users/iesouskurios/Downloads/omni-BASE/bazel-bin/modules/omnitak_mobile/`
- **Android AAR**: `bazel-bin/modules/omnitak_mobile/omnitak_mobile_kt.aar`
- **iOS library**: `bazel-bin/modules/omnitak_mobile/omnitak_mobile_objc.a`
- **Valdimodule files**: `bazel-bin/modules/omnitak_mobile/*.valdimodule`

## Additional Resources

- **Bazel Documentation**: https://bazel.build/docs
- **Valdi Framework**: See project documentation
- **MapLibre**: https://maplibre.org/
- **TypeScript**: https://www.typescriptlang.org/

## Quick Reference Card

```bash
# One-liner to build everything
cd /Users/iesouskurios/Downloads/omni-BASE && ./scripts/check_dependencies.sh && ./scripts/build_omnitak_mobile.sh

# One-liner for clean rebuild
cd /Users/iesouskurios/Downloads/omni-BASE && ./scripts/clean_build_omnitak_mobile.sh --full

# Debug build with validation
cd /Users/iesouskurios/Downloads/omni-BASE && ./scripts/validate_build_config.sh && ./scripts/build_omnitak_mobile.sh --debug --verbose
```

---

**Note**: All paths in this guide assume the project is located at `/Users/iesouskurios/Downloads/omni-BASE`. Adjust paths if your project is in a different location.
