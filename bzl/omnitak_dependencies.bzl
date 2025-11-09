"""
OmniTAK Mobile external dependencies configuration.

This file defines external dependencies for OmniTAK Mobile, including:
- MapLibre GL Native for iOS
- MapLibre Android SDK
- milsymbol for military symbology
- Additional mapping and geospatial libraries
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@rules_jvm_external//:defs.bzl", "maven_install")

# MapLibre versions
MAPLIBRE_GL_NATIVE_VERSION = "6.8.0"
MAPLIBRE_ANDROID_VERSION = "11.5.2"
MILSYMBOL_VERSION = "2.2.0"

def setup_omnitak_android_dependencies():
    """
    Configure Android-specific dependencies for OmniTAK Mobile.
    Includes MapLibre Android SDK and related mapping libraries.
    """

    # MapLibre Android SDK via Maven
    maven_install(
        name = "omnitak_android_mvn",
        artifacts = [
            # MapLibre Android SDK
            "org.maplibre.gl:android-sdk:{}".format(MAPLIBRE_ANDROID_VERSION),
            "org.maplibre.gl:android-sdk-turf:{}".format(MAPLIBRE_ANDROID_VERSION),

            # Geospatial utilities
            "com.google.android.gms:play-services-location:21.0.1",
            "com.mapbox.mapboxsdk:mapbox-android-gestures:0.7.0",

            # Additional geospatial support
            "org.locationtech.jts:jts-core:1.19.0",
            "mil.nga.geopackage:geopackage-android:6.7.4",

            # Vector tile support
            "com.google.protobuf:protobuf-java:3.21.12",

            # Network and caching
            "com.squareup.okhttp3:okhttp:4.12.0",
            "com.squareup.okio:okio:3.6.0",

            # Image loading for markers
            "com.github.bumptech.glide:glide:4.16.0",

            # Kotlin coroutines for async operations
            "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3",
            "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3",
        ],
        repositories = [
            "https://repo1.maven.org/maven2",
            "https://maven.google.com",
        ],
        aar_import_bzl_label = "@rules_android//rules:rules.bzl",
        use_starlark_android_rules = True,
        version_conflict_policy = "pinned",
        fetch_sources = True,
    )

def setup_omnitak_ios_dependencies():
    """
    Configure iOS-specific dependencies for OmniTAK Mobile.
    Includes MapLibre GL Native for iOS.
    """

    # MapLibre GL Native iOS via http_archive
    http_archive(
        name = "maplibre_gl_native_ios",
        url = "https://github.com/maplibre/maplibre-gl-native/archive/refs/tags/ios-v{}.tar.gz".format(MAPLIBRE_GL_NATIVE_VERSION),
        strip_prefix = "maplibre-gl-native-ios-v{}".format(MAPLIBRE_GL_NATIVE_VERSION),
        build_file = "@valdi//third-party/maplibre:maplibre_ios.BUILD",
        sha256 = "",  # TODO: Add SHA256 checksum
    )

    # Alternative: Use pre-built XCFramework
    http_archive(
        name = "maplibre_gl_native_ios_xcframework",
        url = "https://github.com/maplibre/maplibre-gl-native-distribution/releases/download/ios-v{0}/Mapbox-{0}.zip".format(MAPLIBRE_GL_NATIVE_VERSION),
        build_file = "@valdi//third-party/maplibre:maplibre_ios_xcframework.BUILD",
        sha256 = "",  # TODO: Add SHA256 checksum
    )

def setup_omnitak_npm_dependencies():
    """
    Configure NPM dependencies for OmniTAK Mobile.
    Includes milsymbol and mapping utilities.
    """

    # Note: NPM dependencies are typically managed through package.json
    # and aspect_rules_js. This function serves as documentation.
    #
    # Add to package.json:
    # {
    #   "dependencies": {
    #     "milsymbol": "2.2.0",
    #     "maplibre-gl": "4.7.1",
    #     "@turf/turf": "7.1.0",
    #     "@mapbox/vector-tile": "2.0.3",
    #     "pbf": "4.0.1"
    #   }
    # }
    pass

def setup_omnitak_shared_dependencies():
    """
    Configure shared C++ dependencies for geospatial operations.
    """

    # GeoJSON parsing library
    http_archive(
        name = "rapidjson",
        url = "https://github.com/Tencent/rapidjson/archive/refs/tags/v1.1.0.tar.gz",
        strip_prefix = "rapidjson-1.1.0",
        build_file = "@valdi//third-party/rapidjson:rapidjson.BUILD",
        sha256 = "bf7ced29704a1e696fbccf2a2b4ea068e7774fa37f6d7dd4039d0787f8bed98e",
    )

    # Mapbox Geometry for geospatial primitives
    http_archive(
        name = "mapbox_geometry",
        url = "https://github.com/mapbox/geometry.hpp/archive/refs/tags/v2.0.3.tar.gz",
        strip_prefix = "geometry.hpp-2.0.3",
        build_file = "@valdi//third-party/mapbox_geometry:mapbox_geometry.BUILD",
        sha256 = "f0e494b1ecbcbb0e15f0ac88afc8d30f0f39f549aad00e1d6bb4e1f4e39265e0",
    )

    # Mapbox Variant (required by geometry)
    http_archive(
        name = "mapbox_variant",
        url = "https://github.com/mapbox/variant/archive/refs/tags/v2.0.0.tar.gz",
        strip_prefix = "variant-2.0.0",
        build_file = "@valdi//third-party/mapbox_variant:mapbox_variant.BUILD",
        sha256 = "0c9c1b61c2f49f2fc6fa2ff2da03936050eb82f89c8ab18beaa02f57ac835a93",
    )

    # Earcut for polygon triangulation
    http_archive(
        name = "earcut",
        url = "https://github.com/mapbox/earcut.hpp/archive/refs/tags/v2.2.4.tar.gz",
        strip_prefix = "earcut.hpp-2.2.4",
        build_file = "@valdi//third-party/earcut:earcut.BUILD",
        sha256 = "58eca77ef37bd4d0b77ef88776a5e4e8e7bcbd30c00b5fc66e7a8b3c67b0fde0",
    )

    # SQLite for offline map tile storage
    http_archive(
        name = "sqlite",
        url = "https://www.sqlite.org/2024/sqlite-amalgamation-3450100.zip",
        strip_prefix = "sqlite-amalgamation-3450100",
        build_file = "@valdi//third-party/sqlite:sqlite.BUILD",
        sha256 = "cd9c27841b7a5932c9897651e20b86c701dd740556989b01ca596fcfa3d49a0a",
    )

def setup_omnitak_dependencies(platform = ""):
    """
    Main entry point for setting up OmniTAK Mobile dependencies.

    Args:
        platform: Target platform ("ios", "android", or "" for all)
    """

    # Shared dependencies (always included)
    setup_omnitak_shared_dependencies()

    # Platform-specific dependencies
    if platform == "ios" or platform == "":
        setup_omnitak_ios_dependencies()

    if platform == "android" or platform == "":
        setup_omnitak_android_dependencies()

    # NPM dependencies (documentation)
    setup_omnitak_npm_dependencies()
