"""
BUILD file for SQLite
Self-contained, serverless SQL database engine
https://www.sqlite.org/
"""

package(default_visibility = ["//visibility:public"])

licenses(["unencumbered"])  # Public Domain

cc_library(
    name = "sqlite",
    srcs = [
        "sqlite3.c",
    ],
    hdrs = [
        "sqlite3.h",
        "sqlite3ext.h",
    ],
    copts = [
        "-DSQLITE_ENABLE_FTS3",
        "-DSQLITE_ENABLE_FTS4",
        "-DSQLITE_ENABLE_FTS5",
        "-DSQLITE_ENABLE_JSON1",
        "-DSQLITE_ENABLE_RTREE",
        "-DSQLITE_ENABLE_GEOPOLY",
        "-DSQLITE_THREADSAFE=1",
        "-DSQLITE_ENABLE_COLUMN_METADATA",
        "-DSQLITE_SOUNDEX",
    ] + select({
        "@platforms//os:linux": [
            "-DHAVE_USLEEP=1",
            "-DHAVE_FDATASYNC=1",
        ],
        "@platforms//os:macos": [
            "-DHAVE_USLEEP=1",
            "-DHAVE_FDATASYNC=1",
        ],
        "@platforms//os:ios": [
            "-DHAVE_USLEEP=1",
        ],
        "//conditions:default": [],
    }),
    linkopts = select({
        "@platforms//os:linux": ["-lpthread", "-ldl"],
        "@platforms//os:macos": ["-lpthread"],
        "@platforms//os:ios": ["-lpthread"],
        "@platforms//os:android": ["-llog"],
        "//conditions:default": [],
    }),
    visibility = ["//visibility:public"],
)

# SQLite shell (command-line interface)
cc_binary(
    name = "sqlite3_shell",
    srcs = [
        "shell.c",
    ],
    deps = [":sqlite"],
    copts = [
        "-DSQLITE_THREADSAFE=0",
        "-DSQLITE_OMIT_LOAD_EXTENSION",
    ],
    visibility = ["//visibility:public"],
)
