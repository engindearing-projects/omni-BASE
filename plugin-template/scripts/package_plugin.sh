#!/bin/bash
#
# Package plugin into .omniplugin bundle
# Usage: ./scripts/package_plugin.sh
#

set -e

echo "Packaging plugin bundle..."

# Check if we're in the plugin template directory
if [ ! -f "plugin.json" ]; then
    echo "Error: plugin.json not found. Are you in the plugin directory?"
    exit 1
fi

# Read plugin ID from manifest
PLUGIN_ID=$(python3 -c "import json; print(json.load(open('plugin.json'))['id'])")
PLUGIN_VERSION=$(python3 -c "import json; print(json.load(open('plugin.json'))['version'])")

echo "Packaging plugin: $PLUGIN_ID v$PLUGIN_VERSION"

# Create bundle directory structure
BUNDLE_DIR="dist/${PLUGIN_ID}.omniplugin"
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/ios"
mkdir -p "$BUNDLE_DIR/assets"

# Copy manifest
cp plugin.json "$BUNDLE_DIR/manifest.json"

# Copy signed framework
if [ -d "dist/signed/MyPlugin.framework" ]; then
    cp -R dist/signed/MyPlugin.framework "$BUNDLE_DIR/ios/"
else
    echo "Error: Signed framework not found. Please run sign_plugin_ios.sh first"
    exit 1
fi

# Copy assets if they exist
if [ -d "assets" ]; then
    cp -R assets/* "$BUNDLE_DIR/assets/"
fi

# Create signature file
# TODO: Implement proper cryptographic signing
cat > "$BUNDLE_DIR/signature.json" <<EOF
{
  "algorithm": "SHA256withRSA",
  "signature": "PLACEHOLDER_SIGNATURE",
  "certificate": "PLACEHOLDER_CERTIFICATE",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Create ZIP archive
cd dist
ZIP_NAME="${PLUGIN_ID}-${PLUGIN_VERSION}.omniplugin"
zip -r "$ZIP_NAME" "${PLUGIN_ID}.omniplugin"
cd ..

echo "Plugin packaged successfully!"
echo "Bundle: dist/${PLUGIN_ID}.omniplugin"
echo "Archive: dist/${ZIP_NAME}"
