# OmniTAK Mobile - Build Configuration Checklist

## Pre-Build Verification

### 1. File Structure Check

```bash
cd /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile

# Verify build files exist
✓ [ ] BUILD.bazel exists
✓ [ ] build.sh exists and is executable
✓ [ ] module.yaml exists
✓ [ ] tsconfig.json exists

# Verify iOS files exist
✓ [ ] ios/BUILD.bazel exists
✓ [ ] ios/native/OmniTAKNativeBridge.swift exists
✓ [ ] ios/maplibre/SCMapLibreMapView.h exists
✓ [ ] ios/maplibre/SCMapLibreMapView.m exists

# Verify Android files exist
✓ [ ] android/BUILD.bazel exists
✓ [ ] android/native/omnitak_jni.cpp exists
✓ [ ] android/native/OmniTAKNativeBridge.kt exists
✓ [ ] android/maplibre/MapLibreMapView.kt exists

# Verify TypeScript sources exist
✓ [ ] src/valdi/omnitak/ directory exists
✓ [ ] TypeScript files present
```

**Run this command:**
```bash
ls -la BUILD.bazel build.sh ios/BUILD.bazel android/BUILD.bazel && echo "✓ All build files present"
```

### 2. Rust XCFramework Check

```bash
# Verify XCFramework exists
✓ [ ] ios/native/OmniTAKMobile.xcframework/ exists
✓ [ ] ios/native/OmniTAKMobile.xcframework/ios-arm64/libomnitak_mobile.a exists
✓ [ ] ios/native/OmniTAKMobile.xcframework/ios-arm64_x86_64-simulator/libomnitak_mobile.a exists

# Verify headers
✓ [ ] ios/native/omnitak_mobile.h exists
```

**Run this command:**
```bash
ls -la ios/native/OmniTAKMobile.xcframework/*/libomnitak_mobile.a && echo "✓ XCFramework present"
```

**If missing**, build it:
```bash
cd /Users/iesouskurios/Downloads/omni-TAK/crates/omnitak-mobile
./build_ios.sh
```

### 3. Bazel Setup Check

```bash
# Verify Bazel is installed
✓ [ ] bazel --version works
✓ [ ] Bazel version >= 6.0

# Verify workspace
✓ [ ] WORKSPACE file exists at repo root
✓ [ ] @valdi workspace is configured
✓ [ ] @build_bazel_rules_swift is loaded
✓ [ ] @rules_kotlin is loaded
```

**Run this command:**
```bash
cd /Users/iesouskurios/Downloads/omni-BASE
bazel version && echo "✓ Bazel installed"
```

### 4. Query Test

```bash
# Test that Bazel can see our targets
✓ [ ] bazel query //modules/omnitak_mobile:all works
✓ [ ] Shows multiple targets (omnitak_mobile, ios_native_bridge, etc.)
```

**Run this command:**
```bash
cd /Users/iesouskurios/Downloads/omni-BASE
bazel query //modules/omnitak_mobile:all
```

**Expected output:**
```
//modules/omnitak_mobile:omnitak_mobile
//modules/omnitak_mobile:ios_native_bridge
//modules/omnitak_mobile:ios_maplibre_wrapper
//modules/omnitak_mobile:android_jni_bridge
//modules/omnitak_mobile:android_native_bridge
//modules/omnitak_mobile:android_maplibre_wrapper
...
```

## Build Order

### Step 1: Build Individual Targets (iOS)

```bash
cd /Users/iesouskurios/Downloads/omni-BASE

# 1. Build XCFramework import
✓ [ ] bazel build //modules/omnitak_mobile:omnitak_mobile_xcframework \
      --platforms=@build_bazel_rules_apple//apple:ios_arm64

# 2. Build Swift native bridge
✓ [ ] bazel build //modules/omnitak_mobile:ios_native_bridge \
      --platforms=@build_bazel_rules_apple//apple:ios_arm64

# 3. Build Objective-C MapLibre wrapper
✓ [ ] bazel build //modules/omnitak_mobile:ios_maplibre_wrapper \
      --platforms=@build_bazel_rules_apple//apple:ios_arm64

# 4. Build complete module
✓ [ ] bazel build //modules/omnitak_mobile:omnitak_mobile \
      --platforms=@build_bazel_rules_apple//apple:ios_arm64
```

**Or use build script:**
```bash
cd /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile
✓ [ ] ./build.sh ios-device
```

### Step 2: Build Individual Targets (Android)

```bash
cd /Users/iesouskurios/Downloads/omni-BASE

# 1. Build JNI bridge
✓ [ ] bazel build //modules/omnitak_mobile:android_jni_bridge \
      --platforms=@snap_platforms//platforms:android_arm64

# 2. Build Kotlin native bridge
✓ [ ] bazel build //modules/omnitak_mobile:android_native_bridge \
      --platforms=@snap_platforms//platforms:android_arm64

# 3. Build Kotlin MapLibre wrapper
✓ [ ] bazel build //modules/omnitak_mobile:android_maplibre_wrapper \
      --platforms=@snap_platforms//platforms:android_arm64

# 4. Build complete module
✓ [ ] bazel build //modules/omnitak_mobile:omnitak_mobile \
      --platforms=@snap_platforms//platforms:android_arm64
```

**Or use build script:**
```bash
cd /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile
✓ [ ] ./build.sh android-arm64
```

### Step 3: Build All Platforms

```bash
cd /Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile

✓ [ ] ./build.sh all
```

## Troubleshooting Checklist

### If iOS Build Fails

```bash
# 1. Check XCFramework
✓ [ ] XCFramework exists at correct path
✓ [ ] XCFramework contains libomnitak_mobile.a for both architectures

# 2. Check Swift rules
✓ [ ] @build_bazel_rules_swift is loaded in WORKSPACE
✓ [ ] Swift version is compatible (check with: swift --version)

# 3. Check Objective-C code
✓ [ ] SCMapLibreMapView.{h,m} compile without MapLibre
✓ [ ] Comment out @import MapLibre if not available

# 4. Check platform flag
✓ [ ] Using correct --platforms flag
✓ [ ] Platform matches architecture (device vs simulator)

# 5. Clean and retry
✓ [ ] Run: bazel clean
✓ [ ] Run: bazel build //modules/omnitak_mobile:omnitak_mobile --platforms=...
```

### If Android Build Fails

```bash
# 1. Check JNI code
✓ [ ] omnitak_jni.cpp compiles
✓ [ ] JNI function names match Kotlin package/class

# 2. Check Kotlin rules
✓ [ ] @rules_kotlin is loaded in WORKSPACE
✓ [ ] Kotlin version is compatible

# 3. Check Maven dependencies
✓ [ ] @maven is configured in WORKSPACE
✓ [ ] AndroidX dependencies are available

# 4. Check Android SDK/NDK
✓ [ ] ANDROID_HOME is set
✓ [ ] ANDROID_NDK_HOME is set

# 5. Clean and retry
✓ [ ] Run: bazel clean
✓ [ ] Run: bazel build //modules/omnitak_mobile:omnitak_mobile --platforms=...
```

### Common Error Solutions

#### "Cannot find XCFramework"
```bash
✓ [ ] Build XCFramework: cd /Users/iesouskurios/Downloads/omni-TAK/crates/omnitak-mobile && ./build_ios.sh
✓ [ ] Verify path in BUILD.bazel matches actual file location
```

#### "Swift module not found"
```bash
✓ [ ] Check module_name in swift_library matches import statement
✓ [ ] Run: bazel clean --expunge
✓ [ ] Retry build
```

#### "JNI symbols not found"
```bash
✓ [ ] Check alwayslink = True in android_jni_bridge
✓ [ ] Verify System.loadLibrary("omnitak_jni") is called in Kotlin
✓ [ ] Check JNI function names match exactly
```

#### "MapLibre not found"
```bash
✓ [ ] iOS: Comment out @import MapLibre for initial build
✓ [ ] Android: Add Maven dependencies to WORKSPACE
✓ [ ] See TROUBLESHOOTING.md for detailed steps
```

## Integration Checklist

### Integrate with Valdi Application

```bash
# 1. Add dependency to app BUILD.bazel
✓ [ ] Added //modules/omnitak_mobile:omnitak_mobile to deps

# 2. Import in TypeScript
✓ [ ] import { OmniTAKModule } from '@valdi/omnitak/OmniTAKModule';

# 3. Build application
✓ [ ] iOS: bazel build //apps/my_app:my_app_ios
✓ [ ] Android: bazel build //apps/my_app:my_app_android

# 4. Test in emulator/simulator
✓ [ ] iOS: Xcode simulator runs
✓ [ ] Android: Android emulator runs
```

## Performance Verification

```bash
# 1. Measure build times
✓ [ ] Clean build: bazel clean && time ./build.sh all
✓ [ ] Incremental build: time ./build.sh all
✓ [ ] Incremental should be much faster (< 1 min)

# 2. Check cache usage
✓ [ ] Enable disk cache: --disk_cache=~/.cache/bazel
✓ [ ] Verify cache is being used

# 3. Profile build
✓ [ ] Generate profile: bazel build ... --profile=/tmp/profile.json
✓ [ ] Analyze: bazel analyze-profile /tmp/profile.json
```

## Documentation Verification

```bash
# Verify all documentation is present
✓ [ ] BUILD_CONFIGURATION.md exists
✓ [ ] BAZEL_QUICK_REFERENCE.md exists
✓ [ ] TROUBLESHOOTING.md exists
✓ [ ] BAZEL_BUILD_SUMMARY.md exists
✓ [ ] BUILD_CHECKLIST.md exists (this file)

# Verify documentation is accurate
✓ [ ] File paths in docs match actual structure
✓ [ ] Build commands in docs work
✓ [ ] Examples in docs are correct
```

## Final Validation

```bash
cd /Users/iesouskurios/Downloads/omni-BASE

# 1. Query all targets
✓ [ ] bazel query //modules/omnitak_mobile:all

# 2. Build for all platforms
✓ [ ] ./modules/omnitak_mobile/build.sh all

# 3. Verify outputs
✓ [ ] bazel-bin/modules/omnitak_mobile/ contains build artifacts
✓ [ ] No error messages

# 4. Run tests (if configured)
✓ [ ] bazel test //modules/omnitak_mobile:test
```

## Success Criteria

The build configuration is successful when:

- ✓ All targets can be queried without errors
- ✓ iOS device build completes without errors
- ✓ iOS simulator build completes without errors
- ✓ Android ARM64 build completes without errors
- ✓ Incremental builds are fast (< 1 minute)
- ✓ Module can be integrated into a Valdi application
- ✓ All documentation is complete and accurate

## Next Steps After Successful Build

1. **Test the module in an application**
   - Integrate with a test Valdi app
   - Verify TypeScript API works
   - Test MapLibre rendering
   - Test Rust FFI calls

2. **Optimize build performance**
   - Configure remote caching
   - Profile slow targets
   - Optimize dependency tree

3. **Add comprehensive tests**
   - Unit tests for Swift bridge
   - Unit tests for Kotlin bridge
   - Integration tests for MapLibre
   - End-to-end tests

4. **Set up CI/CD**
   - Automated builds on push
   - Artifact publishing
   - Version management

5. **Improve developer experience**
   - IDE integration
   - Live reload
   - Better error messages

## Quick Commands Reference

```bash
# Build script
./build.sh ios-device          # Build for iOS device
./build.sh ios-simulator       # Build for iOS simulator
./build.sh android-arm64       # Build for Android
./build.sh all                 # Build everything
./build.sh clean               # Clean build
./build.sh query               # List targets
./build.sh deps                # Show dependency graph

# Direct Bazel
bazel query //modules/omnitak_mobile:all                    # List targets
bazel build //modules/omnitak_mobile:omnitak_mobile ...     # Build with flags
bazel test //modules/omnitak_mobile:test                    # Run tests
bazel clean                                                  # Clean build
bazel clean --expunge                                       # Deep clean

# Debugging
bazel build ... --verbose_failures                          # Verbose errors
bazel build ... --subcommands                               # Show commands
bazel build ... --sandbox_debug                             # Debug sandbox
```

## Support Resources

- **Detailed Guide**: `BUILD_CONFIGURATION.md`
- **Quick Reference**: `BAZEL_QUICK_REFERENCE.md`
- **Troubleshooting**: `TROUBLESHOOTING.md`
- **Summary**: `BAZEL_BUILD_SUMMARY.md`
- **This Checklist**: `BUILD_CHECKLIST.md`

## Getting Help

If stuck:

1. Check `TROUBLESHOOTING.md` for your specific error
2. Run `./build.sh query` to verify targets exist
3. Run `bazel build --verbose_failures ...` to see detailed errors
4. Clean and retry: `bazel clean --expunge && ./build.sh all`
5. Check documentation for examples and explanations

---

**Good luck with your build!** 🚀

Check off items as you complete them. Once all items are checked, your build configuration is ready to use.
