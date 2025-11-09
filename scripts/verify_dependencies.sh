#!/bin/bash
#
# Verification script for OmniTAK Mobile dependencies
# Checks that all dependencies are properly configured
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Function to print status messages
print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN_COUNT++))
}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OmniTAK Mobile Dependency Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd "$PROJECT_ROOT"

# Test 1: Check WORKSPACE file
print_test "Checking WORKSPACE file..."
if [ -f "WORKSPACE" ]; then
    if grep -q "omnitak_dependencies" WORKSPACE; then
        print_pass "WORKSPACE contains OmniTAK dependencies"
    else
        print_fail "WORKSPACE missing OmniTAK dependencies"
    fi
else
    print_fail "WORKSPACE file not found"
fi

# Test 2: Check MODULE.bazel file
print_test "Checking MODULE.bazel file..."
if [ -f "MODULE.bazel" ]; then
    if grep -q "omnitak_android_mvn" MODULE.bazel; then
        print_pass "MODULE.bazel contains OmniTAK Android dependencies"
    else
        print_fail "MODULE.bazel missing OmniTAK Android dependencies"
    fi

    if grep -q "rapidjson" MODULE.bazel; then
        print_pass "MODULE.bazel contains RapidJSON dependency"
    else
        print_fail "MODULE.bazel missing RapidJSON dependency"
    fi
else
    print_fail "MODULE.bazel file not found"
fi

# Test 3: Check omnitak_dependencies.bzl
print_test "Checking omnitak_dependencies.bzl..."
if [ -f "bzl/omnitak_dependencies.bzl" ]; then
    print_pass "omnitak_dependencies.bzl exists"

    if grep -q "setup_omnitak_android_dependencies" bzl/omnitak_dependencies.bzl; then
        print_pass "Android dependency setup function exists"
    else
        print_fail "Android dependency setup function missing"
    fi

    if grep -q "setup_omnitak_ios_dependencies" bzl/omnitak_dependencies.bzl; then
        print_pass "iOS dependency setup function exists"
    else
        print_fail "iOS dependency setup function missing"
    fi
else
    print_fail "omnitak_dependencies.bzl not found"
fi

# Test 4: Check package.json
print_test "Checking package.json..."
if [ -f "package.json" ]; then
    if grep -q "milsymbol" package.json; then
        print_pass "package.json contains milsymbol"
    else
        print_fail "package.json missing milsymbol"
    fi

    if grep -q "maplibre-gl" package.json; then
        print_pass "package.json contains maplibre-gl"
    else
        print_fail "package.json missing maplibre-gl"
    fi

    if grep -q "@turf/turf" package.json; then
        print_pass "package.json contains @turf/turf"
    else
        print_fail "package.json missing @turf/turf"
    fi
else
    print_fail "package.json not found"
fi

# Test 5: Check third-party BUILD files
print_test "Checking third-party BUILD files..."
declare -a build_files=(
    "third-party/rapidjson/rapidjson.BUILD"
    "third-party/mapbox_geometry/mapbox_geometry.BUILD"
    "third-party/mapbox_variant/mapbox_variant.BUILD"
    "third-party/earcut/earcut.BUILD"
    "third-party/sqlite/sqlite.BUILD"
    "third-party/maplibre/maplibre_ios.BUILD"
    "third-party/maplibre/maplibre_ios_xcframework.BUILD"
)

for build_file in "${build_files[@]}"; do
    if [ -f "$build_file" ]; then
        print_pass "$build_file exists"
    else
        print_fail "$build_file not found"
    fi
done

# Test 6: Check scripts
print_test "Checking helper scripts..."
if [ -f "scripts/setup_dependencies.sh" ] && [ -x "scripts/setup_dependencies.sh" ]; then
    print_pass "setup_dependencies.sh exists and is executable"
else
    print_fail "setup_dependencies.sh missing or not executable"
fi

if [ -f "scripts/clean_build.sh" ] && [ -x "scripts/clean_build.sh" ]; then
    print_pass "clean_build.sh exists and is executable"
else
    print_fail "clean_build.sh missing or not executable"
fi

# Test 7: Check DEPENDENCIES.md
print_test "Checking documentation..."
if [ -f "DEPENDENCIES.md" ]; then
    print_pass "DEPENDENCIES.md exists"

    if grep -q "MapLibre" DEPENDENCIES.md; then
        print_pass "DEPENDENCIES.md documents MapLibre"
    else
        print_warn "DEPENDENCIES.md missing MapLibre documentation"
    fi

    if grep -q "milsymbol" DEPENDENCIES.md; then
        print_pass "DEPENDENCIES.md documents milsymbol"
    else
        print_warn "DEPENDENCIES.md missing milsymbol documentation"
    fi
else
    print_fail "DEPENDENCIES.md not found"
fi

# Test 8: Validate Bazel syntax
print_test "Validating Bazel configuration..."
if command -v bazel &> /dev/null; then
    # Try to query a simple target to validate syntax
    if bazel query //... --output=label > /dev/null 2>&1; then
        print_pass "Bazel configuration is valid"
    else
        print_warn "Bazel configuration may have issues (run 'bazel query //...' for details)"
    fi
else
    print_warn "Bazel not installed, skipping syntax validation"
fi

# Test 9: Check NPM packages (if node_modules exists)
print_test "Checking NPM packages..."
if [ -d "node_modules" ]; then
    if [ -d "node_modules/milsymbol" ]; then
        print_pass "milsymbol is installed"
    else
        print_warn "milsymbol not installed (run 'npm install')"
    fi

    if [ -d "node_modules/maplibre-gl" ]; then
        print_pass "maplibre-gl is installed"
    else
        print_warn "maplibre-gl not installed (run 'npm install')"
    fi

    if [ -d "node_modules/@turf/turf" ]; then
        print_pass "@turf/turf is installed"
    else
        print_warn "@turf/turf not installed (run 'npm install')"
    fi
else
    print_warn "node_modules not found (run 'npm install')"
fi

# Test 10: Check platform-specific requirements
print_test "Checking platform requirements..."

# Android
if [ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ]; then
    print_pass "Android SDK environment variable set"
else
    print_warn "ANDROID_HOME/ANDROID_SDK_ROOT not set (Android builds may fail)"
fi

# iOS/macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v xcodebuild &> /dev/null; then
        print_pass "Xcode is installed"
    else
        print_warn "Xcode not found (iOS builds will fail)"
    fi
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Verification Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Passed:${NC} $PASS_COUNT"
echo -e "${YELLOW}Warnings:${NC} $WARN_COUNT"
echo -e "${RED}Failed:${NC} $FAIL_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}All critical tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run './scripts/setup_dependencies.sh' to install dependencies"
    echo "  2. Run './scripts/clean_build.sh' to perform a clean build"
    echo "  3. Build OmniTAK Mobile: bazel build //modules/omnitak_mobile:omnitak_mobile"
    echo ""
    exit 0
else
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    echo ""
    echo "Recommended actions:"
    echo "  1. Review DEPENDENCIES.md for setup instructions"
    echo "  2. Ensure all files are in place"
    echo "  3. Run verification again after fixes"
    echo ""
    exit 1
fi
