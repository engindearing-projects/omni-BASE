"""
BUILD file for Mapbox Variant
C++11/C++14 header-only variant implementation
https://github.com/mapbox/variant
"""

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # BSD License

cc_library(
    name = "mapbox_variant",
    hdrs = glob([
        "include/mapbox/**/*.hpp",
    ]),
    includes = ["include"],
    visibility = ["//visibility:public"],
)

# Recursive variant support
cc_library(
    name = "recursive_wrapper",
    hdrs = ["include/mapbox/recursive_wrapper.hpp"],
    includes = ["include"],
    visibility = ["//visibility:public"],
)

# Variant utilities
cc_library(
    name = "variant_visitor",
    hdrs = ["include/mapbox/variant_visitor.hpp"],
    includes = ["include"],
    deps = [":mapbox_variant"],
    visibility = ["//visibility:public"],
)
