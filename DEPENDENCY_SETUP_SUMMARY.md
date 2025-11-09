# OmniTAK Mobile Dependency Setup Summary

## Overview

This document summarizes the external dependency configuration for OmniTAK Mobile. All dependencies have been configured in the Bazel workspace for both Android and iOS platforms.

## Files Created/Modified

### Configuration Files

1. **`/Users/iesouskurios/Downloads/omni-BASE/bzl/omnitak_dependencies.bzl`**
   - Main dependency configuration file
   - Defines setup functions for Android, iOS, and shared dependencies
   - Manages version constants for all external libraries

2. **`/Users/iesouskurios/Downloads/omni-BASE/MODULE.bazel`** (Modified)
   - Added OmniTAK Android Maven dependencies
   - Added geospatial C++ libraries (RapidJSON, Mapbox Geometry, Earcut, SQLite)
   - Configured version pinning and conflict resolution

3. **`/Users/iesouskurios/Downloads/omni-BASE/WORKSPACE`** (Modified)
   - Integrated `setup_omnitak_dependencies()` function
   - Configured platform-specific dependency loading

4. **`/Users/iesouskurios/Downloads/omni-BASE/package.json`** (Modified)
   - Added NPM dependencies: milsymbol, maplibre-gl, @turf/turf
   - Added TypeScript type definitions
   - Configured development dependencies

### Helper Scripts

5. **`/Users/iesouskurios/Downloads/omni-BASE/scripts/setup_dependencies.sh`**
   - Automated dependency setup script
   - Checks prerequisites (Bazel, Node.js, Android SDK, Xcode)
   - Installs NPM packages and fetches Bazel dependencies
   - Provides dependency summary

6. **`/Users/iesouskurios/Downloads/omni-BASE/scripts/clean_build.sh`**
   - Clean build automation script
   - Supports selective cleaning (Bazel, NPM, external deps)
   - Integrated build and verification
   - Flexible command-line options

7. **`/Users/iesouskurios/Downloads/omni-BASE/scripts/verify_dependencies.sh`**
   - Dependency verification script
   - Validates all configuration files
   - Checks platform requirements
   - Provides detailed test results

### Documentation

8. **`/Users/iesouskurios/Downloads/omni-BASE/DEPENDENCIES.md`**
   - Comprehensive dependency documentation
   - Version information for all libraries
   - Upgrade instructions
   - Troubleshooting guide
   - License information

### Third-Party BUILD Files

9. **`/Users/iesouskurios/Downloads/omni-BASE/third-party/rapidjson/rapidjson.BUILD`**
   - Bazel BUILD file for RapidJSON library
   - Configured for JSON parsing in GeoJSON processing

10. **`/Users/iesouskurios/Downloads/omni-BASE/third-party/mapbox_geometry/mapbox_geometry.BUILD`**
    - Bazel BUILD file for Mapbox Geometry library
    - Provides geospatial primitive types

11. **`/Users/iesouskurios/Downloads/omni-BASE/third-party/mapbox_variant/mapbox_variant.BUILD`**
    - Bazel BUILD file for Mapbox Variant library
    - Type-safe variant implementation

12. **`/Users/iesouskurios/Downloads/omni-BASE/third-party/earcut/earcut.BUILD`**
    - Bazel BUILD file for Earcut library
    - Polygon triangulation for rendering

13. **`/Users/iesouskurios/Downloads/omni-BASE/third-party/sqlite/sqlite.BUILD`**
    - Bazel BUILD file for SQLite library
    - Offline map tile storage

14. **`/Users/iesouskurios/Downloads/omni-BASE/third-party/maplibre/maplibre_ios.BUILD`**
    - Bazel BUILD file for MapLibre iOS (source build)
    - Placeholder for advanced source builds

15. **`/Users/iesouskurios/Downloads/omni-BASE/third-party/maplibre/maplibre_ios_xcframework.BUILD`**
    - Bazel BUILD file for MapLibre iOS XCFramework
    - Pre-built binary integration (recommended)

16. **`/Users/iesouskurios/Downloads/omni-BASE/third-party/maplibre/README.md`**
    - MapLibre integration documentation
    - iOS and Android usage examples

## Dependencies Added

### Android Dependencies (Maven)

| Library | Version | Purpose |
|---------|---------|---------|
| MapLibre Android SDK | 11.5.2 | Mobile mapping |
| MapLibre Turf | 11.5.2 | Geospatial operations |
| JTS Core | 1.19.0 | Geometry operations |
| GeoPackage Android | 6.7.4 | Offline geospatial data |
| Play Services Location | 21.0.1 | GPS tracking |
| OkHttp | 4.12.0 | Network requests |
| Glide | 4.16.0 | Image loading |
| Kotlin Coroutines | 1.7.3 | Async operations |

### iOS Dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| MapLibre GL Native | 6.8.0 | Mobile mapping |

### NPM Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| milsymbol | 2.2.0 | Military symbols |
| maplibre-gl | 4.7.1 | Web mapping |
| @turf/turf | 7.1.0 | Geospatial analysis |
| @mapbox/vector-tile | 2.0.3 | Vector tiles |
| pbf | 4.0.1 | Protocol buffers |
| geojson | 0.5.0 | GeoJSON utilities |

### C++ Libraries

| Library | Version | Purpose |
|---------|---------|---------|
| RapidJSON | 1.1.0 | JSON parsing |
| Mapbox Geometry | 2.0.3 | Geospatial primitives |
| Mapbox Variant | 2.0.0 | Type-safe variants |
| Earcut | 2.2.4 | Polygon triangulation |
| SQLite | 3.45.1 | Database storage |

## Usage Instructions

### Initial Setup

1. **Verify Prerequisites:**
   ```bash
   ./scripts/verify_dependencies.sh
   ```

2. **Setup Dependencies:**
   ```bash
   ./scripts/setup_dependencies.sh
   ```

3. **Install NPM Packages:**
   ```bash
   npm install
   ```

### Building

1. **Clean Build:**
   ```bash
   ./scripts/clean_build.sh
   ```

2. **Build OmniTAK Mobile:**
   ```bash
   bazel build //modules/omnitak_mobile:omnitak_mobile
   ```

3. **Build Platform-Specific:**
   ```bash
   # Android
   bazel build //modules/omnitak_mobile/android:omnitak_android

   # iOS
   bazel build //modules/omnitak_mobile/ios:omnitak_ios
   ```

### Verification Commands

```bash
# Check all dependencies are fetched
bazel fetch //modules/omnitak_mobile/...

# Query dependency tree
bazel query "deps(//modules/omnitak_mobile:omnitak_mobile)" --output=graph

# List external repositories
bazel query @... 2>/dev/null | grep -E "(maplibre|milsymbol|rapidjson)"

# Verify NPM packages
npm list --depth=0
```

## Platform Requirements

### All Platforms
- **Bazel:** 6.0.0+ (version specified in `.bazelversion`)
- **Node.js:** 18.0.0+ (for NPM dependencies)

### Android Development
- **Android SDK:** API Level 35
- **Build Tools:** 34.0.0
- **NDK:** Latest (configured via rules_android_ndk)
- **Environment:** `ANDROID_HOME` or `ANDROID_SDK_ROOT` must be set

### iOS Development
- **macOS:** 12.0+
- **Xcode:** 14.0+
- **iOS Deployment Target:** 12.0+
- **Swift:** 5.5+

## Integration with OmniTAK Mobile Module

The dependencies are integrated into the OmniTAK Mobile module through:

1. **Direct Dependencies:** Referenced in `modules/omnitak_mobile/BUILD.bazel`
2. **Platform Libraries:** Android/iOS specific implementations
3. **TypeScript Bindings:** NPM packages available to TypeScript code
4. **Native Bridges:** C++ libraries accessible via native bridges

## Troubleshooting

### Common Issues

1. **Dependency Resolution Failures:**
   - Run `bazel clean --expunge`
   - Delete `~/.m2/repository/org/maplibre`
   - Re-run `./scripts/setup_dependencies.sh`

2. **NPM Package Issues:**
   - Run `npm cache clean --force`
   - Delete `node_modules` and `package-lock.json`
   - Run `npm install`

3. **Platform-Specific Errors:**
   - See DEPENDENCIES.md for detailed troubleshooting
   - Verify platform requirements are met
   - Check environment variables

## Next Steps

1. **Review Documentation:**
   - Read `/Users/iesouskurios/Downloads/omni-BASE/DEPENDENCIES.md` for detailed information
   - Check `/Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/BUILD_GUIDE.md`

2. **Implement Native Bridges:**
   - Create Kotlin/Swift wrappers for MapLibre
   - Implement milsymbol rendering integration
   - Add geospatial utility functions

3. **Configure Resources:**
   - Add map styles and tile sources
   - Configure offline map storage
   - Set up symbol icon resources

4. **Testing:**
   - Create unit tests for geospatial operations
   - Add integration tests for map rendering
   - Implement end-to-end tests

## License Compliance

All dependencies use permissive licenses compatible with OmniTAK Mobile:
- **BSD-2-Clause:** MapLibre GL Native
- **MIT:** milsymbol, RapidJSON, GeoPackage, Kotlin Coroutines
- **Apache 2.0:** Android support libraries, OkHttp, Glide
- **ISC:** Mapbox Geometry, Earcut
- **Public Domain:** SQLite

See individual dependency documentation in DEPENDENCIES.md for complete license information.

## Maintenance

### Updating Dependencies

1. Check release notes for breaking changes
2. Update version numbers in MODULE.bazel or omnitak_dependencies.bzl
3. Update SHA256 checksums for http_archive dependencies
4. Run verification: `./scripts/verify_dependencies.sh`
5. Clean build: `./scripts/clean_build.sh --all`
6. Run tests: `bazel test //modules/omnitak_mobile/...`
7. Update DEPENDENCIES.md with new version information

### Security Updates

Monitor security advisories for:
- MapLibre releases
- Android Maven dependencies
- NPM packages (use `npm audit`)
- C++ libraries

## Support Resources

- **OmniTAK Mobile Documentation:** `/Users/iesouskurios/Downloads/omni-BASE/modules/omnitak_mobile/`
- **Dependency Documentation:** `/Users/iesouskurios/Downloads/omni-BASE/DEPENDENCIES.md`
- **MapLibre Documentation:** https://maplibre.org/
- **Bazel Documentation:** https://bazel.build/
- **Issue Tracking:** File issues with logs from `bazel build --verbose_failures`

---

**Configuration Date:** 2025-11-08
**OmniTAK Mobile Version:** 0.1.0
**Bazel Version:** See `.bazelversion`
