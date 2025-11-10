#!/usr/bin/env python3
"""
Validate plugin manifest and structure
"""

import json
import sys
import os
import re

def validate_plugin_id(plugin_id):
    """Validate plugin ID format (reverse DNS)"""
    pattern = r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$'
    if not re.match(pattern, plugin_id):
        return False, f"Invalid plugin ID format: {plugin_id}"
    return True, None

def validate_version(version):
    """Validate semantic version format"""
    pattern = r'^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$'
    if not re.match(pattern, version):
        return False, f"Invalid version format: {version}"
    return True, None

def validate_permissions(permissions):
    """Validate permission list"""
    valid_permissions = [
        'network.access',
        'location.read',
        'location.write',
        'cot.read',
        'cot.write',
        'map.read',
        'map.write',
        'storage.read',
        'storage.write',
        'ui.create',
        'notifications.send',
        'bluetooth.access',
        'filesystem.read',
        'filesystem.write',
    ]

    for perm in permissions:
        if perm not in valid_permissions:
            return False, f"Invalid permission: {perm}"

    return True, None

def validate_manifest(manifest):
    """Validate plugin manifest structure and values"""
    required_fields = [
        'id', 'name', 'version', 'description', 'author',
        'license', 'omnitak_version', 'type', 'platforms',
        'permissions', 'entry_points'
    ]

    # Check required fields
    for field in required_fields:
        if field not in manifest:
            return False, f"Missing required field: {field}"

    # Validate plugin ID
    valid, error = validate_plugin_id(manifest['id'])
    if not valid:
        return False, error

    # Validate version
    valid, error = validate_version(manifest['version'])
    if not valid:
        return False, error

    # Validate permissions
    valid, error = validate_permissions(manifest['permissions'])
    if not valid:
        return False, error

    # Check iOS platform support
    if 'ios' not in manifest['platforms']:
        return False, "iOS platform not supported"

    # Check iOS entry point
    if 'ios' not in manifest['entry_points']:
        return False, "Missing iOS entry point"

    # Validate plugin type
    valid_types = ['ui', 'data', 'protocol', 'map', 'hybrid']
    if manifest['type'] not in valid_types:
        return False, f"Invalid plugin type: {manifest['type']}"

    return True, None

def validate_structure():
    """Validate plugin directory structure"""
    required_files = [
        'plugin.json',
        'ios/BUILD.bazel',
        'ios/Info.plist',
        'ios/Sources/PluginMain.swift',
    ]

    for file_path in required_files:
        if not os.path.exists(file_path):
            return False, f"Missing required file: {file_path}"

    return True, None

def main():
    """Main validation function"""
    print("Validating plugin manifest...")

    # Load manifest
    try:
        with open('plugin.json', 'r') as f:
            manifest = json.load(f)
    except FileNotFoundError:
        print("❌ Error: plugin.json not found")
        return 1
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON in plugin.json: {e}")
        return 1

    # Validate manifest
    valid, error = validate_manifest(manifest)
    if not valid:
        print(f"❌ Manifest validation failed: {error}")
        return 1

    print("✓ Manifest validation passed")

    # Validate structure
    print("Validating plugin structure...")
    valid, error = validate_structure()
    if not valid:
        print(f"❌ Structure validation failed: {error}")
        return 1

    print("✓ Structure validation passed")

    print("✅ Plugin validation successful!")
    print(f"   Plugin ID: {manifest['id']}")
    print(f"   Version: {manifest['version']}")
    print(f"   Permissions: {', '.join(manifest['permissions'])}")

    return 0

if __name__ == '__main__':
    sys.exit(main())
