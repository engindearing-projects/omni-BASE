#!/bin/bash
#
# Setup script for OmniTAK Mobile dependencies
# This script downloads, verifies, and configures all external dependencies
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OmniTAK Mobile Dependency Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print status messages
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if Bazel is installed
check_bazel() {
    print_status "Checking Bazel installation..."
    if ! command -v bazel &> /dev/null; then
        print_error "Bazel is not installed. Please install Bazel first."
        echo "  Visit: https://bazel.build/install"
        exit 1
    fi

    local bazel_version=$(bazel version | grep "Build label" | cut -d' ' -f3)
    print_success "Bazel $bazel_version is installed"
}

# Check if Node.js is installed
check_node() {
    print_status "Checking Node.js installation..."
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js first."
        echo "  Visit: https://nodejs.org/"
        exit 1
    fi

    local node_version=$(node --version)
    print_success "Node.js $node_version is installed"
}

# Install NPM dependencies
install_npm_dependencies() {
    print_status "Installing NPM dependencies..."

    cd "$PROJECT_ROOT"

    if [ -f "package.json" ]; then
        if command -v npm &> /dev/null; then
            npm install
            print_success "NPM dependencies installed"
        else
            print_error "npm is not available"
            exit 1
        fi
    else
        print_warning "No package.json found, skipping NPM dependencies"
    fi
}

# Fetch Bazel dependencies
fetch_bazel_dependencies() {
    print_status "Fetching Bazel dependencies..."

    cd "$PROJECT_ROOT"

    # Fetch all dependencies
    bazel fetch //...

    print_success "Bazel dependencies fetched"
}

# Verify Android SDK setup (if building for Android)
verify_android_sdk() {
    print_status "Verifying Android SDK setup..."

    if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
        print_warning "ANDROID_HOME or ANDROID_SDK_ROOT not set"
        print_warning "Android builds may fail. Please set ANDROID_HOME or ANDROID_SDK_ROOT"
        return 0
    fi

    local sdk_path="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"

    if [ ! -d "$sdk_path" ]; then
        print_warning "Android SDK directory not found at: $sdk_path"
        return 0
    fi

    print_success "Android SDK found at: $sdk_path"

    # Check for required SDK components
    if [ -f "$sdk_path/build-tools/34.0.0/aapt" ] || [ -f "$sdk_path/build-tools/34.0.0/aapt.exe" ]; then
        print_success "Android Build Tools 34.0.0 installed"
    else
        print_warning "Android Build Tools 34.0.0 not found"
        print_warning "Install with: sdkmanager 'build-tools;34.0.0'"
    fi

    # Check for API level 35
    if [ -d "$sdk_path/platforms/android-35" ]; then
        print_success "Android API 35 installed"
    else
        print_warning "Android API 35 not found"
        print_warning "Install with: sdkmanager 'platforms;android-35'"
    fi
}

# Verify iOS/macOS setup (if building for iOS)
verify_xcode() {
    print_status "Verifying Xcode setup..."

    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_warning "Not running on macOS, skipping Xcode verification"
        return 0
    fi

    if ! command -v xcodebuild &> /dev/null; then
        print_warning "Xcode is not installed"
        print_warning "iOS builds will fail. Please install Xcode from the App Store"
        return 0
    fi

    local xcode_version=$(xcodebuild -version | head -n 1)
    print_success "$xcode_version is installed"

    # Check for command line tools
    if xcode-select -p &> /dev/null; then
        print_success "Xcode command line tools are installed"
    else
        print_warning "Xcode command line tools not found"
        print_warning "Install with: xcode-select --install"
    fi
}

# Create third-party BUILD files directory structure
create_build_file_structure() {
    print_status "Creating third-party BUILD file structure..."

    local third_party="$PROJECT_ROOT/third-party"

    # Create directories for OmniTAK dependencies
    mkdir -p "$third_party/rapidjson"
    mkdir -p "$third_party/mapbox_geometry"
    mkdir -p "$third_party/mapbox_variant"
    mkdir -p "$third_party/earcut"
    mkdir -p "$third_party/sqlite"
    mkdir -p "$third_party/maplibre"

    print_success "Third-party directory structure created"
}

# Display dependency summary
show_dependency_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Dependency Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Android Dependencies (Maven):"
    echo "  - MapLibre Android SDK: 11.5.2"
    echo "  - MapLibre Turf: 11.5.2"
    echo "  - JTS Core: 1.19.0"
    echo "  - GeoPackage Android: 6.7.4"
    echo ""
    echo "iOS Dependencies:"
    echo "  - MapLibre GL Native: 6.8.0"
    echo ""
    echo "NPM Dependencies:"
    echo "  - milsymbol: ^2.2.0"
    echo "  - maplibre-gl: ^4.7.1"
    echo "  - @turf/turf: ^7.1.0"
    echo ""
    echo "C++ Libraries:"
    echo "  - RapidJSON: 1.1.0"
    echo "  - Mapbox Geometry: 2.0.3"
    echo "  - Mapbox Variant: 2.0.0"
    echo "  - Earcut: 2.2.4"
    echo "  - SQLite: 3.45.1"
    echo ""
}

# Main execution
main() {
    cd "$PROJECT_ROOT"

    # Check prerequisites
    check_bazel
    check_node

    # Verify platform-specific tools
    verify_android_sdk
    verify_xcode

    # Create directory structure
    create_build_file_structure

    # Install dependencies
    install_npm_dependencies
    fetch_bazel_dependencies

    # Show summary
    show_dependency_summary

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Dependency setup complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review DEPENDENCIES.md for detailed information"
    echo "  2. Run './scripts/clean_build.sh' to perform a clean build"
    echo "  3. Build OmniTAK Mobile: bazel build //modules/omnitak_mobile:omnitak_mobile"
    echo ""
}

# Run main function
main "$@"
