#!/usr/bin/env bash

# Clean Build Script for OmniTAK Mobile
# This script performs a clean build by removing cached outputs and rebuilding from scratch

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

# Clean configuration
CLEAN_LEVEL="${CLEAN_LEVEL:-module}"
BUILD_MODE="${BUILD_MODE:-release}"
TARGET_PLATFORM="${TARGET_PLATFORM:-all}"
SKIP_BUILD="${SKIP_BUILD:-false}"

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

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --full)
                CLEAN_LEVEL="full"
                shift
                ;;
            --module)
                CLEAN_LEVEL="module"
                shift
                ;;
            --cache)
                CLEAN_LEVEL="cache"
                shift
                ;;
            --skip-build)
                SKIP_BUILD="true"
                shift
                ;;
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
    echo "Clean levels:"
    echo "  --module             Clean only OmniTAK Mobile module outputs (default)"
    echo "  --cache              Clean Bazel cache for the module"
    echo "  --full               Clean entire Bazel workspace (WARNING: slow rebuild)"
    echo ""
    echo "Build options:"
    echo "  --skip-build         Clean only, don't rebuild"
    echo "  --debug              Rebuild in debug mode"
    echo "  --release            Rebuild in release mode (default)"
    echo "  --android            Build only Android targets"
    echo "  --ios                Build only iOS targets"
    echo ""
    echo "Other options:"
    echo "  --help, -h           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Clean module and rebuild"
    echo "  $0 --full                   # Full clean and rebuild"
    echo "  $0 --cache --skip-build     # Clean cache only, no rebuild"
    echo "  $0 --module --android       # Clean and rebuild Android only"
}

# Check if Bazel is installed
check_bazel() {
    if ! command -v bazel &> /dev/null; then
        print_error "Bazel is not installed"
        exit 1
    fi
    print_success "Bazel is installed"
}

# Clean module outputs
clean_module() {
    print_step "Cleaning OmniTAK Mobile module outputs..."

    # Use Bazel to clean specific targets
    local targets=(
        "//modules/omnitak_mobile/..."
    )

    if bazel clean --expunge_async "${targets[@]}" 2>/dev/null; then
        print_success "Module outputs cleaned"
    else
        print_warning "Module clean command not fully supported, using workspace clean"
        bazel clean
        print_success "Module outputs cleaned"
    fi
}

# Clean Bazel cache
clean_cache() {
    print_step "Cleaning Bazel cache..."

    # Clean without expunging (keeps external dependencies)
    if bazel clean; then
        print_success "Bazel cache cleaned"
    else
        print_error "Failed to clean Bazel cache"
        return 1
    fi
}

# Full clean of Bazel workspace
clean_full() {
    print_step "Performing full clean of Bazel workspace..."
    print_warning "This will remove ALL build artifacts and external dependencies"
    print_warning "Next build will be slow as it re-downloads everything"

    # Expunge everything
    if bazel clean --expunge; then
        print_success "Full workspace cleaned"
    else
        print_error "Failed to clean workspace"
        return 1
    fi

    # Also clean any symlinks
    print_step "Removing Bazel symlinks..."
    cd "$PROJECT_ROOT"
    rm -rf bazel-* 2>/dev/null || true
    print_success "Symlinks removed"
}

# Verify outputs were cleaned
verify_clean() {
    print_step "Verifying clean..."

    local bazel_bin="$PROJECT_ROOT/bazel-bin/modules/omnitak_mobile"

    if [ ! -d "$bazel_bin" ]; then
        print_success "Build outputs are clean"
        return 0
    else
        print_warning "Some build outputs may still exist"
        return 0
    fi
}

# Rebuild after cleaning
rebuild() {
    print_header "Rebuilding OmniTAK Mobile"

    if [ -x "$SCRIPT_DIR/build_omnitak_mobile.sh" ]; then
        local build_args=()

        if [ "$BUILD_MODE" = "debug" ]; then
            build_args+=("--debug")
        else
            build_args+=("--release")
        fi

        if [ "$TARGET_PLATFORM" = "android" ]; then
            build_args+=("--android")
        elif [ "$TARGET_PLATFORM" = "ios" ]; then
            build_args+=("--ios")
        fi

        if "$SCRIPT_DIR/build_omnitak_mobile.sh" "${build_args[@]}"; then
            print_success "Rebuild completed successfully"
            return 0
        else
            print_error "Rebuild failed"
            return 1
        fi
    else
        print_warning "Build script not found, skipping rebuild"
        print_info "You can manually build with: bazel build //modules/omnitak_mobile:omnitak_mobile"
        return 0
    fi
}

# Show disk space freed
show_disk_space() {
    # This is approximate and platform-dependent
    if command -v du &> /dev/null; then
        print_step "Checking disk space..."

        local output_dir="$PROJECT_ROOT/bazel-bin"
        if [ -d "$output_dir" ]; then
            local size=$(du -sh "$output_dir" 2>/dev/null | awk '{print $1}')
            print_info "Current build outputs: $size"
        fi
    fi
}

# Main clean process
main() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║            OmniTAK Mobile Clean Build                    ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Parse arguments
    parse_args "$@"

    print_info "Project root: $PROJECT_ROOT"
    print_info "Module directory: $MODULE_DIR"
    print_info "Clean level: $CLEAN_LEVEL"
    print_info "Build mode: $BUILD_MODE"

    # Check prerequisites
    print_header "Checking Prerequisites"
    check_bazel

    # Show current state
    show_disk_space

    # Perform cleaning based on level
    print_header "Cleaning Build Artifacts"

    case $CLEAN_LEVEL in
        module)
            clean_module
            ;;
        cache)
            clean_cache
            ;;
        full)
            clean_full
            ;;
        *)
            print_error "Invalid clean level: $CLEAN_LEVEL"
            exit 1
            ;;
    esac

    # Verify clean
    verify_clean

    # Rebuild if requested
    if [ "$SKIP_BUILD" = "false" ]; then
        if ! rebuild; then
            print_error "Clean build failed!"
            exit 1
        fi
    else
        print_info "Skipping rebuild (--skip-build specified)"
        echo ""
        print_info "To rebuild, run: ./scripts/build_omnitak_mobile.sh"
    fi

    # Show completion
    echo ""
    print_success "Clean build process completed successfully!"

    if [ "$SKIP_BUILD" = "false" ]; then
        print_info "OmniTAK Mobile has been rebuilt from scratch"
    else
        print_info "Build artifacts have been cleaned"
    fi

    exit 0
}

# Run main function
main "$@"
