#!/bin/bash
#
# Test iOS plugin
# Usage: ./scripts/test_plugin_ios.sh
#

set -e

echo "Running iOS plugin tests..."

# Check if we're in the plugin template directory
if [ ! -f "plugin.json" ]; then
    echo "Error: plugin.json not found. Are you in the plugin directory?"
    exit 1
fi

# Run tests with Bazel if test target exists
if bazel query //ios:MyPluginTests 2>/dev/null; then
    bazel test \
        --config=ios \
        --test_output=all \
        //ios:MyPluginTests

    echo "All tests passed!"
else
    echo "No tests found. Skipping test execution."
    echo "To add tests, create a test target in ios/BUILD.bazel"
fi
