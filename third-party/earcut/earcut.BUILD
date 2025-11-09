"""
BUILD file for Earcut
Fast polygon triangulation library
https://github.com/mapbox/earcut.hpp
"""

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # ISC License

cc_library(
    name = "earcut",
    hdrs = glob([
        "include/mapbox/*.hpp",
    ]),
    includes = ["include"],
    visibility = ["//visibility:public"],
)
