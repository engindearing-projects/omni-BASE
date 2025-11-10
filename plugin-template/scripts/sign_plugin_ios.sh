#!/bin/bash
#
# Sign iOS plugin framework
# Usage: ./scripts/sign_plugin_ios.sh
#
# Environment variables:
#   CODE_SIGNING_IDENTITY - Certificate name (e.g., "Apple Development")
#

set -e

echo "Signing iOS plugin framework..."

# Get signing identity from environment or use default
SIGNING_IDENTITY="${CODE_SIGNING_IDENTITY:-Apple Development}"

# Find the framework
FRAMEWORK_PATH="bazel-bin/ios/MyPlugin.framework"

if [ ! -d "$FRAMEWORK_PATH" ]; then
    echo "Error: Framework not found at $FRAMEWORK_PATH"
    echo "Please build the plugin first with: ./scripts/build_plugin_ios.sh release"
    exit 1
fi

# Create output directory
mkdir -p dist/signed

# Sign the framework
echo "Signing with identity: $SIGNING_IDENTITY"
codesign --force --sign "$SIGNING_IDENTITY" \
    --timestamp \
    --generate-entitlement-der \
    "$FRAMEWORK_PATH"

# Verify signature
echo "Verifying signature..."
codesign --verify --verbose "$FRAMEWORK_PATH"

# Copy signed framework to dist
cp -R "$FRAMEWORK_PATH" dist/signed/

echo "Framework signed successfully!"
echo "Signed framework: dist/signed/MyPlugin.framework"
