#!/bin/bash
#
# Clean build script for OmniTAK Mobile
# This script performs a clean build by removing cached artifacts
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

# Default values
CLEAN_ALL=false
CLEAN_BAZEL=true
CLEAN_NPM=false
CLEAN_EXTERNAL=false
BUILD_TARGET="//modules/omnitak_mobile:omnitak_mobile"

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

# Display help message
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [TARGET]

Clean build script for OmniTAK Mobile.

OPTIONS:
    -h, --help          Show this help message
    -a, --all           Clean everything (Bazel, NPM, external deps)
    -b, --bazel         Clean Bazel cache only (default)
    -n, --npm           Clean NPM node_modules
    -e, --external      Clean external Bazel dependencies
    --no-build          Clean only, do not build

TARGET:
    Bazel build target (default: //modules/omnitak_mobile:omnitak_mobile)

EXAMPLES:
    # Clean Bazel cache and build
    $0

    # Clean everything and build
    $0 --all

    # Clean Bazel cache only, no build
    $0 --no-build

    # Clean and build specific target
    $0 //modules/omnitak_mobile/android:omnitak_android

EOF
}

# Parse command line arguments
parse_args() {
    local do_build=true

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -a|--all)
                CLEAN_ALL=true
                CLEAN_BAZEL=true
                CLEAN_NPM=true
                CLEAN_EXTERNAL=true
                shift
                ;;
            -b|--bazel)
                CLEAN_BAZEL=true
                shift
                ;;
            -n|--npm)
                CLEAN_NPM=true
                shift
                ;;
            -e|--external)
                CLEAN_EXTERNAL=true
                shift
                ;;
            --no-build)
                do_build=false
                shift
                ;;
            //*)
                BUILD_TARGET="$1"
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    echo "$do_build"
}

# Clean Bazel cache
clean_bazel() {
    print_status "Cleaning Bazel cache..."

    cd "$PROJECT_ROOT"

    # Clean build artifacts
    bazel clean

    print_success "Bazel cache cleaned"
}

# Clean Bazel external dependencies
clean_bazel_external() {
    print_status "Cleaning Bazel external dependencies..."

    cd "$PROJECT_ROOT"

    # Expunge all Bazel caches including external repositories
    bazel clean --expunge

    print_success "Bazel external dependencies cleaned"
}

# Clean NPM dependencies
clean_npm() {
    print_status "Cleaning NPM dependencies..."

    cd "$PROJECT_ROOT"

    if [ -d "node_modules" ]; then
        rm -rf node_modules
        print_success "node_modules removed"
    else
        print_warning "node_modules directory not found"
    fi

    if [ -f "package-lock.json" ]; then
        rm -f package-lock.json
        print_success "package-lock.json removed"
    fi
}

# Build target
build_target() {
    local target="$1"

    print_status "Building target: $target"

    cd "$PROJECT_ROOT"

    # Build the target
    if bazel build "$target"; then
        print_success "Build completed successfully"
        return 0
    else
        print_error "Build failed"
        return 1
    fi
}

# Get build outputs location
show_build_outputs() {
    local target="$1"

    print_status "Build output locations:"

    cd "$PROJECT_ROOT"

    # Query output files
    local outputs=$(bazel cquery --output=files "$target" 2>/dev/null || echo "")

    if [ -n "$outputs" ]; then
        echo "$outputs" | while read -r output; do
            if [ -f "$output" ]; then
                echo "  - $output"
            fi
        done
    else
        print_warning "No output files found"
    fi
}

# Main execution
main() {
    local do_build
    do_build=$(parse_args "$@")

    cd "$PROJECT_ROOT"

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}OmniTAK Mobile Clean Build${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Perform cleaning operations
    if [ "$CLEAN_NPM" = true ]; then
        clean_npm
        echo ""
    fi

    if [ "$CLEAN_EXTERNAL" = true ]; then
        clean_bazel_external
        echo ""
    elif [ "$CLEAN_BAZEL" = true ]; then
        clean_bazel
        echo ""
    fi

    # Reinstall NPM dependencies if we cleaned them
    if [ "$CLEAN_NPM" = true ] && [ "$do_build" = true ]; then
        print_status "Reinstalling NPM dependencies..."
        if command -v npm &> /dev/null; then
            npm install
            print_success "NPM dependencies reinstalled"
        fi
        echo ""
    fi

    # Build if requested
    if [ "$do_build" = true ]; then
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}Building${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo ""

        if build_target "$BUILD_TARGET"; then
            echo ""
            show_build_outputs "$BUILD_TARGET"
            echo ""
            echo -e "${GREEN}========================================${NC}"
            echo -e "${GREEN}Clean build successful!${NC}"
            echo -e "${GREEN}========================================${NC}"
        else
            echo ""
            echo -e "${RED}========================================${NC}"
            echo -e "${RED}Clean build failed!${NC}"
            echo -e "${RED}========================================${NC}"
            exit 1
        fi
    else
        echo ""
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}Clean complete!${NC}"
        echo -e "${GREEN}========================================${NC}"
    fi

    echo ""
    echo "Next steps:"
    if [ "$do_build" = false ]; then
        echo "  - Build manually: bazel build $BUILD_TARGET"
    fi
    echo "  - Run tests: bazel test //modules/omnitak_mobile/..."
    echo "  - See DEPENDENCIES.md for more information"
    echo ""
}

# Run main function
main "$@"
