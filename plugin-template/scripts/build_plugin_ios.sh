#!/bin/bash
#
# Build iOS plugin
# Usage: ./scripts/build_plugin_ios.sh [debug|release]
#

set -e

# Parse arguments
BUILD_MODE="${1:-debug}"

if [ "$BUILD_MODE" = "release" ]; then
    COMPILATION_MODE="opt"
else
    COMPILATION_MODE="dbg"
fi

echo "Building iOS plugin in $BUILD_MODE mode..."

# Check if we're in the plugin template directory
if [ ! -f "plugin.json" ]; then
    echo "Error: plugin.json not found. Are you in the plugin directory?"
    exit 1
fi

# Build with Bazel
bazel build \
    --config=ios \
    --compilation_mode="$COMPILATION_MODE" \
    //ios:MyPlugin

echo "Build completed successfully!"
echo "Output: bazel-bin/ios/MyPlugin.framework"
