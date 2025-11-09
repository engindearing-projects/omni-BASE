#!/usr/bin/env bash

# Incremental Build Script for OmniTAK Mobile
# This script performs an incremental build of the OmniTAK Mobile module

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE_DIR="$PROJECT_ROOT/modules/omnitak_mobile"

# Build configuration
BUILD_MODE="${BUILD_MODE:-release}"
TARGET_PLATFORM="${TARGET_PLATFORM:-all}"
VERBOSE="${VERBOSE:-false}"

# Build start time
BUILD_START=$(date +%s)

# Helper functions
print_header() {
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  $1${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}\n"
}

print_step() {
    echo -e "${CYAN}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if Bazel is installed
check_bazel() {
    if ! command -v bazel &> /dev/null; then
        print_error "Bazel is not installed"
        echo ""
        echo "Please install Bazel first:"
        echo "  macOS: brew install bazel"
        echo "  Linux: See https://bazel.build/install"
        exit 1
    fi

    local required_version=$(cat "$PROJECT_ROOT/.bazelversion" 2>/dev/null || echo "unknown")
    local installed_version=$(bazel version 2>/dev/null | grep "Build label" | awk '{print $3}' || echo "unknown")

    print_success "Bazel is installed"
    print_info "Required version: $required_version"
    print_info "Installed version: $installed_version"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug)
                BUILD_MODE="debug"
                shift
                ;;
            --release)
                BUILD_MODE="release"
                shift
                ;;
            --android)
                TARGET_PLATFORM="android"
                shift
                ;;
            --ios)
                TARGET_PLATFORM="ios"
                shift
                ;;
            --verbose|-v)
                VERBOSE="true"
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --debug              Build in debug mode (default: release)"
    echo "  --release            Build in release mode"
    echo "  --android            Build only Android targets"
    echo "  --ios                Build only iOS targets"
    echo "  --verbose, -v        Enable verbose output"
    echo "  --help, -h           Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  BUILD_MODE           Set build mode (debug|release)"
    echo "  TARGET_PLATFORM      Set target platform (all|android|ios)"
    echo "  VERBOSE              Enable verbose output (true|false)"
    echo ""
    echo "Examples:"
    echo "  $0                   # Build all targets in release mode"
    echo "  $0 --debug           # Build all targets in debug mode"
    echo "  $0 --android         # Build only Android targets"
    echo "  $0 --ios --debug     # Build iOS targets in debug mode"
}

# Build the main module
build_module() {
    local target="//modules/omnitak_mobile:omnitak_mobile"

    print_step "Building OmniTAK Mobile module..."

    local bazel_args=("build")

    # Add compilation mode
    if [ "$BUILD_MODE" = "debug" ]; then
        bazel_args+=("--compilation_mode=dbg")
    else
        bazel_args+=("--compilation_mode=opt")
    fi

    # Add verbose flag if requested
    if [ "$VERBOSE" = "true" ]; then
        bazel_args+=("--verbose_failures" "--subcommands")
    fi

    # Add target
    bazel_args+=("$target")

    # Run build
    if bazel "${bazel_args[@]}"; then
        print_success "Module compiled successfully"
        return 0
    else
        print_error "Module compilation failed"
        return 1
    fi
}

# Build Android-specific targets
build_android() {
    print_step "Building Android targets..."

    local targets=(
        "//modules/omnitak_mobile:omnitak_mobile_kt"
        "//modules/omnitak_mobile:android.${BUILD_MODE}.valdimodule"
        "//modules/omnitak_mobile:android.${BUILD_MODE}.srcjar"
    )

    local bazel_args=("build")

    if [ "$BUILD_MODE" = "debug" ]; then
        bazel_args+=("--compilation_mode=dbg")
    else
        bazel_args+=("--compilation_mode=opt")
    fi

    if [ "$VERBOSE" = "true" ]; then
        bazel_args+=("--verbose_failures")
    fi

    bazel_args+=("${targets[@]}")

    if bazel "${bazel_args[@]}"; then
        print_success "Android targets built successfully"
        return 0
    else
        print_error "Android build failed"
        return 1
    fi
}

# Build iOS-specific targets
build_ios() {
    print_step "Building iOS targets..."

    local targets=(
        "//modules/omnitak_mobile:omnitak_mobile_objc"
        "//modules/omnitak_mobile:ios.${BUILD_MODE}.valdimodule"
    )

    local bazel_args=("build")

    if [ "$BUILD_MODE" = "debug" ]; then
        bazel_args+=("--compilation_mode=dbg")
    else
        bazel_args+=("--compilation_mode=opt")
    fi

    if [ "$VERBOSE" = "true" ]; then
        bazel_args+=("--verbose_failures")
    fi

    bazel_args+=("${targets[@]}")

    if bazel "${bazel_args[@]}"; then
        print_success "iOS targets built successfully"
        return 0
    else
        print_error "iOS build failed"
        return 1
    fi
}

# Show build summary
show_build_summary() {
    local build_end=$(date +%s)
    local build_duration=$((build_end - BUILD_START))

    print_header "Build Summary"

    echo -e "  Build mode:      ${GREEN}$BUILD_MODE${NC}"
    echo -e "  Target platform: ${GREEN}$TARGET_PLATFORM${NC}"
    echo -e "  Build duration:  ${GREEN}${build_duration}s${NC}"
    echo ""

    # Show output locations
    print_info "Build outputs:"
    echo "  Bazel outputs: $PROJECT_ROOT/bazel-bin/modules/omnitak_mobile/"
    echo ""

    # Show next steps
    print_info "Next steps:"
    if [ "$TARGET_PLATFORM" = "all" ] || [ "$TARGET_PLATFORM" = "android" ]; then
        echo "  Android: Check bazel-bin/modules/omnitak_mobile/omnitak_mobile_kt.aar"
    fi
    if [ "$TARGET_PLATFORM" = "all" ] || [ "$TARGET_PLATFORM" = "ios" ]; then
        echo "  iOS: Check bazel-bin/modules/omnitak_mobile/omnitak_mobile_objc.a"
    fi
}

# Main build process
main() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║          OmniTAK Mobile Incremental Build                ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Parse arguments
    parse_args "$@"

    print_info "Project root: $PROJECT_ROOT"
    print_info "Module directory: $MODULE_DIR"
    print_info "Build mode: $BUILD_MODE"
    print_info "Target platform: $TARGET_PLATFORM"

    # Check prerequisites
    print_header "Checking Prerequisites"
    check_bazel

    # Validate build configuration
    print_header "Validating Build Configuration"
    if [ -x "$SCRIPT_DIR/validate_build_config.sh" ]; then
        if "$SCRIPT_DIR/validate_build_config.sh"; then
            print_success "Build configuration is valid"
        else
            print_error "Build configuration validation failed"
            exit 1
        fi
    else
        print_warning "Validation script not found, skipping validation"
    fi

    # Build based on platform
    print_header "Building OmniTAK Mobile"

    local build_failed=false

    # Build the main module first
    if ! build_module; then
        build_failed=true
    fi

    # Build platform-specific targets
    if [ "$TARGET_PLATFORM" = "all" ]; then
        if ! build_android; then
            build_failed=true
        fi
        if ! build_ios; then
            build_failed=true
        fi
    elif [ "$TARGET_PLATFORM" = "android" ]; then
        if ! build_android; then
            build_failed=true
        fi
    elif [ "$TARGET_PLATFORM" = "ios" ]; then
        if ! build_ios; then
            build_failed=true
        fi
    fi

    # Show summary
    if [ "$build_failed" = "true" ]; then
        echo ""
        print_error "Build failed! Please check the errors above."
        exit 1
    else
        echo ""
        show_build_summary
        print_success "Build completed successfully!"
        exit 0
    fi
}

# Run main function
main "$@"
