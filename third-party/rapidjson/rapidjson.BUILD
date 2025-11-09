"""
BUILD file for RapidJSON - Fast JSON parser/generator for C++
https://github.com/Tencent/rapidjson
"""

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # MIT License

cc_library(
    name = "rapidjson",
    hdrs = glob([
        "include/rapidjson/**/*.h",
    ]),
    includes = ["include"],
    defines = [
        "RAPIDJSON_HAS_STDSTRING=1",
        "RAPIDJSON_HAS_CXX11_RVALUE_REFS=1",
    ],
    visibility = ["//visibility:public"],
)

# Header-only library for error handling
cc_library(
    name = "rapidjson_error",
    hdrs = glob([
        "include/rapidjson/error/*.h",
    ]),
    includes = ["include"],
    deps = [":rapidjson"],
    visibility = ["//visibility:public"],
)

# Internal utilities
cc_library(
    name = "rapidjson_internal",
    hdrs = glob([
        "include/rapidjson/internal/*.h",
    ]),
    includes = ["include"],
    deps = [":rapidjson"],
    visibility = ["//visibility:public"],
)
