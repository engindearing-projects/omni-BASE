"""
BUILD file for Mapbox Geometry
Header-only C++ library for geospatial primitives
https://github.com/mapbox/geometry.hpp
"""

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # ISC License

cc_library(
    name = "mapbox_geometry",
    hdrs = glob([
        "include/mapbox/**/*.hpp",
    ]),
    includes = ["include"],
    deps = [
        "@mapbox_variant",
    ],
    visibility = ["//visibility:public"],
)

# Individual geometry types for selective inclusion
cc_library(
    name = "point",
    hdrs = ["include/mapbox/geometry/point.hpp"],
    includes = ["include"],
    deps = ["@mapbox_variant"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "line_string",
    hdrs = ["include/mapbox/geometry/line_string.hpp"],
    includes = ["include"],
    deps = [":point"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "polygon",
    hdrs = ["include/mapbox/geometry/polygon.hpp"],
    includes = ["include"],
    deps = [":line_string"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "multi_point",
    hdrs = ["include/mapbox/geometry/multi_point.hpp"],
    includes = ["include"],
    deps = [":point"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "multi_line_string",
    hdrs = ["include/mapbox/geometry/multi_line_string.hpp"],
    includes = ["include"],
    deps = [":line_string"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "multi_polygon",
    hdrs = ["include/mapbox/geometry/multi_polygon.hpp"],
    includes = ["include"],
    deps = [":polygon"],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "geometry",
    hdrs = ["include/mapbox/geometry/geometry.hpp"],
    includes = ["include"],
    deps = [
        ":point",
        ":line_string",
        ":polygon",
        ":multi_point",
        ":multi_line_string",
        ":multi_polygon",
    ],
    visibility = ["//visibility:public"],
)

cc_library(
    name = "feature",
    hdrs = ["include/mapbox/geometry/feature.hpp"],
    includes = ["include"],
    deps = [
        ":geometry",
        "@mapbox_variant",
    ],
    visibility = ["//visibility:public"],
)
