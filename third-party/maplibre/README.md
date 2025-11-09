# MapLibre Dependencies

This directory contains BUILD files for MapLibre GL Native dependencies.

## iOS Integration

There are two approaches for integrating MapLibre on iOS:

### 1. XCFramework (Recommended)

Use the pre-built XCFramework for faster builds and easier maintenance:

```python
# In MODULE.bazel
http_archive(
    name = "maplibre_gl_native_ios_xcframework",
    url = "https://github.com/maplibre/maplibre-native-distribution/releases/download/ios-v6.8.0/Mapbox-6.8.0.zip",
    build_file = "@valdi//third-party/maplibre:maplibre_ios_xcframework.BUILD",
)
```

Then reference in your BUILD file:
```python
objc_library(
    name = "my_app",
    deps = [
        "@maplibre_gl_native_ios_xcframework//:maplibre_ios",
    ],
)
```

### 2. Source Build

Build MapLibre from source (advanced, requires extensive configuration):

```python
# In MODULE.bazel
http_archive(
    name = "maplibre_gl_native_ios",
    url = "https://github.com/maplibre/maplibre-gl-native/archive/refs/tags/ios-v6.8.0.tar.gz",
    build_file = "@valdi//third-party/maplibre:maplibre_ios.BUILD",
)
```

Note: Source builds require additional platform-specific configuration and dependencies.

## Android Integration

Android dependencies are managed through Maven:

```python
# In MODULE.bazel
maven.install(
    name = "omnitak_android_mvn",
    artifacts = [
        "org.maplibre.gl:android-sdk:11.5.2",
    ],
)
```

Reference in BUILD file:
```python
android_library(
    name = "my_lib",
    deps = [
        "@omnitak_android_mvn//:org_maplibre_gl_android_sdk",
    ],
)
```

## Resources

- [MapLibre iOS Documentation](https://maplibre.org/maplibre-native/ios/)
- [MapLibre Android Documentation](https://maplibre.org/maplibre-native/android/)
- [MapLibre Native Repository](https://github.com/maplibre/maplibre-gl-native)
