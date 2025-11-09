"""
BUILD file for MapLibre GL Native iOS XCFramework
Pre-built binary distribution
https://github.com/maplibre/maplibre-native-distribution
"""

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # BSD-2-Clause License

# Import the pre-built MapLibre XCFramework
objc_import(
    name = "maplibre_ios_xcframework",
    framework_imports = glob(["Mapbox.xcframework/**"]),
    visibility = ["//visibility:public"],
    sdk_frameworks = [
        "UIKit",
        "CoreLocation",
        "CoreGraphics",
        "QuartzCore",
        "Metal",
        "MetalKit",
    ],
)

# Convenience alias
alias(
    name = "maplibre_ios",
    actual = ":maplibre_ios_xcframework",
    visibility = ["//visibility:public"],
)
