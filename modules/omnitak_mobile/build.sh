#!/bin/bash
# OmniTAK Mobile - Bazel Build Helper Script
# This script provides convenient commands for building the module

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

function print_usage() {
    echo -e "${BLUE}OmniTAK Mobile Build Script${NC}"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  ios-device           Build for iOS device (arm64)"
    echo "  ios-simulator        Build for iOS simulator"
    echo "  android-arm64        Build for Android ARM64"
    echo "  android-x86          Build for Android x86_64 emulator"
    echo "  all                  Build for all platforms"
    echo "  clean                Clean build artifacts"
    echo "  query                Show all build targets"
    echo "  deps                 Show dependency graph"
    echo "  test                 Run tests"
    echo ""
    echo "Options:"
    echo "  --debug              Build with debug symbols"
    echo "  --verbose            Enable verbose output"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ios-device"
    echo "  $0 android-arm64 --debug"
    echo "  $0 all --verbose"
}

function print_step() {
    echo -e "${GREEN}==>${NC} $1"
}

function print_error() {
    echo -e "${RED}Error:${NC} $1" >&2
}

function print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Parse arguments
COMMAND=""
BUILD_MODE="opt"
VERBOSE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        ios-device|ios-simulator|android-arm64|android-x86|all|clean|query|deps|test)
            COMMAND="$1"
            shift
            ;;
        --debug)
            BUILD_MODE="dbg"
            shift
            ;;
        --verbose)
            VERBOSE="--verbose_failures"
            shift
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

if [ -z "$COMMAND" ]; then
    print_error "No command specified"
    print_usage
    exit 1
fi

# Build targets
MODULE_TARGET="//modules/omnitak_mobile:omnitak_mobile"
IOS_MAPLIBRE="//modules/omnitak_mobile:ios_maplibre_wrapper"
IOS_BRIDGE="//modules/omnitak_mobile:ios_native_bridge"
ANDROID_JNI="//modules/omnitak_mobile:android_jni_bridge"
ANDROID_BRIDGE="//modules/omnitak_mobile:android_native_bridge"
ANDROID_MAPLIBRE="//modules/omnitak_mobile:android_maplibre_wrapper"

function build_ios_device() {
    print_step "Building OmniTAK Mobile for iOS device (arm64)..."

    bazel build \
        --compilation_mode="$BUILD_MODE" \
        --platforms=@build_bazel_rules_apple//apple:ios_arm64 \
        --ios_minimum_os=14.0 \
        $VERBOSE \
        "$MODULE_TARGET" \
        "$IOS_MAPLIBRE" \
        "$IOS_BRIDGE"

    print_step "iOS device build completed!"
}

function build_ios_simulator() {
    print_step "Building OmniTAK Mobile for iOS simulator..."

    bazel build \
        --compilation_mode="$BUILD_MODE" \
        --platforms=@build_bazel_rules_apple//apple:ios_sim_arm64 \
        --ios_minimum_os=14.0 \
        $VERBOSE \
        "$MODULE_TARGET" \
        "$IOS_MAPLIBRE" \
        "$IOS_BRIDGE"

    print_step "iOS simulator build completed!"
}

function build_android_arm64() {
    print_step "Building OmniTAK Mobile for Android ARM64..."

    bazel build \
        --compilation_mode="$BUILD_MODE" \
        --platforms=@snap_platforms//platforms:android_arm64 \
        --android_min_sdk=21 \
        $VERBOSE \
        "$MODULE_TARGET" \
        "$ANDROID_JNI" \
        "$ANDROID_BRIDGE" \
        "$ANDROID_MAPLIBRE"

    print_step "Android ARM64 build completed!"
}

function build_android_x86() {
    print_step "Building OmniTAK Mobile for Android x86_64 emulator..."

    bazel build \
        --compilation_mode="$BUILD_MODE" \
        --platforms=@snap_platforms//platforms:android_x86_64 \
        --android_min_sdk=21 \
        $VERBOSE \
        "$MODULE_TARGET" \
        "$ANDROID_JNI" \
        "$ANDROID_BRIDGE" \
        "$ANDROID_MAPLIBRE"

    print_step "Android x86_64 build completed!"
}

function build_all() {
    print_step "Building OmniTAK Mobile for all platforms..."
    echo ""

    build_ios_device
    echo ""

    build_ios_simulator
    echo ""

    build_android_arm64
    echo ""

    print_step "All platforms built successfully!"
}

function clean_build() {
    print_step "Cleaning build artifacts..."

    bazel clean

    print_step "Clean completed!"
}

function query_targets() {
    print_step "Querying build targets..."
    echo ""

    bazel query //modules/omnitak_mobile:all

    echo ""
    print_step "Query completed!"
}

function show_deps() {
    print_step "Showing dependency graph..."
    echo ""

    bazel query --output=graph "$MODULE_TARGET" > /tmp/omnitak_deps.dot

    if command -v dot &> /dev/null; then
        dot -Tpng /tmp/omnitak_deps.dot -o /tmp/omnitak_deps.png
        print_step "Dependency graph saved to /tmp/omnitak_deps.png"

        if command -v open &> /dev/null; then
            open /tmp/omnitak_deps.png
        fi
    else
        print_warning "Graphviz not installed. Raw graph saved to /tmp/omnitak_deps.dot"
        echo "Install Graphviz to generate PNG: brew install graphviz"
    fi
}

function run_tests() {
    print_step "Running tests..."

    bazel test \
        --compilation_mode="$BUILD_MODE" \
        $VERBOSE \
        //modules/omnitak_mobile:test

    print_step "Tests completed!"
}

# Execute command
case $COMMAND in
    ios-device)
        build_ios_device
        ;;
    ios-simulator)
        build_ios_simulator
        ;;
    android-arm64)
        build_android_arm64
        ;;
    android-x86)
        build_android_x86
        ;;
    all)
        build_all
        ;;
    clean)
        clean_build
        ;;
    query)
        query_targets
        ;;
    deps)
        show_deps
        ;;
    test)
        run_tests
        ;;
esac

echo ""
echo -e "${GREEN}Done!${NC}"
