#!/usr/bin/env bash

# Dependency Checker Script for OmniTAK Mobile
# This script verifies that all required dependencies and tools are available

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

# Counters
DEPS_OK=0
DEPS_MISSING=0
DEPS_WARNING=0

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
    ((DEPS_OK++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((DEPS_MISSING++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((DEPS_WARNING++))
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check Bazel
check_bazel() {
    print_step "Checking Bazel..."

    if command_exists bazel; then
        local version=$(bazel version 2>/dev/null | grep "Build label" | awk '{print $3}')
        print_success "Bazel installed: $version"

        # Check version matches requirement
        if [ -f "$PROJECT_ROOT/.bazelversion" ]; then
            local required=$(cat "$PROJECT_ROOT/.bazelversion")
            if [ "$version" = "$required" ]; then
                print_success "Bazel version matches requirement: $required"
            else
                print_warning "Bazel version mismatch. Required: $required, Installed: $version"
            fi
        fi
    else
        print_error "Bazel not found"
        print_info "Install with: brew install bazel (macOS) or see https://bazel.build/install"
    fi
}

# Check Node.js and npm
check_nodejs() {
    print_step "Checking Node.js and npm..."

    if command_exists node; then
        local version=$(node --version)
        print_success "Node.js installed: $version"

        # Check minimum version (16.x or higher recommended)
        local major_version=$(echo "$version" | sed 's/v\([0-9]*\).*/\1/')
        if [ "$major_version" -ge 16 ]; then
            print_success "Node.js version is compatible (>= 16.x)"
        else
            print_warning "Node.js version may be too old. Recommended: >= 16.x"
        fi
    else
        print_error "Node.js not found"
        print_info "Install with: brew install node (macOS)"
    fi

    if command_exists npm; then
        local npm_version=$(npm --version)
        print_success "npm installed: $npm_version"
    else
        print_error "npm not found (usually comes with Node.js)"
    fi
}

# Check TypeScript
check_typescript() {
    print_step "Checking TypeScript..."

    if command_exists tsc; then
        local version=$(tsc --version)
        print_success "TypeScript installed: $version"
    else
        print_warning "TypeScript not found globally"
        print_info "Install with: npm install -g typescript"
        print_info "Or use local version via npm scripts"
    fi
}

# Check Java (required for Android builds)
check_java() {
    print_step "Checking Java..."

    if command_exists java; then
        local version=$(java -version 2>&1 | head -n 1)
        print_success "Java installed: $version"

        # Check for Java 11 or higher (required for modern Android builds)
        if java -version 2>&1 | grep -q "version \"1[1-9]"; then
            print_success "Java version is compatible for Android builds"
        elif java -version 2>&1 | grep -q "version \"[2-9]"; then
            print_success "Java version is compatible for Android builds"
        else
            print_warning "Java version may be too old for Android builds (need 11+)"
        fi
    else
        print_warning "Java not found (required for Android builds)"
        print_info "Install with: brew install openjdk@11 (macOS)"
    fi
}

# Check Xcode (required for iOS builds on macOS)
check_xcode() {
    if [ "$(uname)" != "Darwin" ]; then
        print_info "Skipping Xcode check (not on macOS)"
        return 0
    fi

    print_step "Checking Xcode..."

    if command_exists xcodebuild; then
        local version=$(xcodebuild -version | head -n 1)
        print_success "Xcode installed: $version"

        # Check for command line tools
        if xcode-select -p &> /dev/null; then
            local cli_path=$(xcode-select -p)
            print_success "Xcode command line tools configured: $cli_path"
        else
            print_warning "Xcode command line tools not configured"
            print_info "Run: xcode-select --install"
        fi
    else
        print_warning "Xcode not found (required for iOS builds)"
        print_info "Install from Mac App Store"
    fi
}

# Check Android SDK
check_android_sdk() {
    print_step "Checking Android SDK..."

    if [ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ]; then
        local sdk_root="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
        print_success "Android SDK configured: $sdk_root"

        # Check for required SDK components
        if [ -d "$sdk_root/platforms" ]; then
            local platforms=$(ls "$sdk_root/platforms" 2>/dev/null | wc -l)
            print_success "Android platforms found: $platforms"
        else
            print_warning "No Android platforms found in SDK"
        fi

        if [ -d "$sdk_root/build-tools" ]; then
            local build_tools=$(ls "$sdk_root/build-tools" 2>/dev/null | wc -l)
            print_success "Android build-tools found: $build_tools"
        else
            print_warning "No Android build-tools found in SDK"
        fi
    else
        print_warning "Android SDK not configured (ANDROID_HOME/ANDROID_SDK_ROOT not set)"
        print_info "Install Android Studio or set up SDK manually"
    fi
}

# Check Android NDK
check_android_ndk() {
    print_step "Checking Android NDK..."

    if [ -n "$ANDROID_NDK_HOME" ]; then
        print_success "Android NDK configured: $ANDROID_NDK_HOME"

        if [ -f "$ANDROID_NDK_HOME/ndk-build" ]; then
            print_success "NDK build tools found"
        else
            print_warning "NDK build tools not found at configured path"
        fi
    else
        print_warning "Android NDK not configured (ANDROID_NDK_HOME not set)"
        print_info "Install via Android Studio SDK Manager or download from Google"
    fi
}

# Check Python (required for some build tools)
check_python() {
    print_step "Checking Python..."

    if command_exists python3; then
        local version=$(python3 --version)
        print_success "Python 3 installed: $version"
    else
        print_warning "Python 3 not found (may be needed for some build tools)"
        print_info "Install with: brew install python3 (macOS)"
    fi
}

# Check Git
check_git() {
    print_step "Checking Git..."

    if command_exists git; then
        local version=$(git --version)
        print_success "Git installed: $version"
    else
        print_error "Git not found (required for version control)"
        print_info "Install with: brew install git (macOS)"
    fi
}

# Check optional tools
check_optional_tools() {
    print_header "Checking Optional Tools"

    # yq (for YAML parsing)
    if command_exists yq; then
        local version=$(yq --version 2>/dev/null || echo "unknown")
        print_success "yq installed: $version"
    else
        print_info "yq not found (optional, for YAML validation)"
        print_info "Install with: brew install yq (macOS)"
    fi

    # jq (for JSON parsing)
    if command_exists jq; then
        local version=$(jq --version)
        print_success "jq installed: $version"
    else
        print_info "jq not found (optional, for JSON validation)"
        print_info "Install with: brew install jq (macOS)"
    fi

    # clang-format (for code formatting)
    if command_exists clang-format; then
        local version=$(clang-format --version | head -n 1)
        print_success "clang-format installed: $version"
    else
        print_info "clang-format not found (optional, for code formatting)"
    fi
}

# Check Valdi dependencies
check_valdi_deps() {
    print_header "Checking Valdi Module Dependencies"

    # Check valdi_core
    if [ -d "$PROJECT_ROOT/src/valdi_modules/src/valdi/valdi_core" ]; then
        print_success "valdi_core module found"

        # Check for BUILD.bazel
        if [ -f "$PROJECT_ROOT/src/valdi_modules/src/valdi/valdi_core/BUILD.bazel" ]; then
            print_success "valdi_core BUILD.bazel exists"
        else
            print_warning "valdi_core BUILD.bazel not found"
        fi
    else
        print_error "valdi_core module not found"
        print_info "Expected at: $PROJECT_ROOT/src/valdi_modules/src/valdi/valdi_core"
    fi

    # Check valdi_tsx
    if [ -d "$PROJECT_ROOT/src/valdi_modules/src/valdi/valdi_tsx" ]; then
        print_success "valdi_tsx module found"

        # Check for BUILD.bazel
        if [ -f "$PROJECT_ROOT/src/valdi_modules/src/valdi/valdi_tsx/BUILD.bazel" ]; then
            print_success "valdi_tsx BUILD.bazel exists"
        else
            print_warning "valdi_tsx BUILD.bazel not found"
        fi
    else
        print_error "valdi_tsx module not found"
        print_info "Expected at: $PROJECT_ROOT/src/valdi_modules/src/valdi/valdi_tsx"
    fi
}

# Check MapLibre XCFramework
check_maplibre_xcframework() {
    print_header "Checking MapLibre XCFramework"

    # Check iOS MapLibre
    local ios_maplibre="$MODULE_DIR/ios/maplibre/MapLibre.xcframework"
    if [ -d "$ios_maplibre" ]; then
        print_success "iOS MapLibre XCFramework found"

        # Check structure
        if [ -d "$ios_maplibre/ios-arm64" ] || [ -d "$ios_maplibre/ios-x86_64-simulator" ]; then
            print_success "MapLibre XCFramework structure looks valid"
        else
            print_warning "MapLibre XCFramework structure may be incomplete"
        fi
    else
        print_warning "iOS MapLibre XCFramework not found"
        print_info "Expected at: $ios_maplibre"
        print_info "You may need to build or download it separately"
    fi

    # Check Android MapLibre
    local android_maplibre="$MODULE_DIR/android/maplibre"
    if [ -d "$android_maplibre" ]; then
        print_success "Android MapLibre directory found"

        # Check for AAR or JAR files
        if find "$android_maplibre" -name "*.aar" -o -name "*.jar" | grep -q .; then
            print_success "Android MapLibre libraries found"
        else
            print_warning "No Android MapLibre AAR/JAR files found"
        fi
    else
        print_warning "Android MapLibre directory not found"
        print_info "Expected at: $android_maplibre"
    fi
}

# Check npm packages
check_npm_packages() {
    print_header "Checking npm Packages"

    if [ -f "$PROJECT_ROOT/package.json" ]; then
        print_success "Root package.json found"

        # Check if node_modules exists
        if [ -d "$PROJECT_ROOT/node_modules" ]; then
            print_success "node_modules directory exists"
        else
            print_warning "node_modules not found"
            print_info "Run: npm install"
        fi
    else
        print_warning "Root package.json not found"
    fi

    # Check module package.json if it exists
    if [ -f "$MODULE_DIR/package.json" ]; then
        print_success "Module package.json found"
    fi
}

# Check build environment
check_build_environment() {
    print_header "Checking Build Environment"

    # Check disk space
    if command_exists df; then
        local available=$(df -h "$PROJECT_ROOT" | tail -1 | awk '{print $4}')
        print_info "Available disk space: $available"

        # Warn if less than 10GB available (approximate)
        local available_gb=$(df -g "$PROJECT_ROOT" 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
        if [ "$available_gb" -lt 10 ] 2>/dev/null; then
            print_warning "Low disk space (less than 10GB available)"
            print_info "Bazel builds can require significant disk space"
        fi
    fi

    # Check for Bazel workspace
    if [ -f "$PROJECT_ROOT/WORKSPACE" ]; then
        print_success "Bazel WORKSPACE file exists"
    else
        print_error "Bazel WORKSPACE file not found"
    fi

    if [ -f "$PROJECT_ROOT/MODULE.bazel" ]; then
        print_success "MODULE.bazel file exists"
    else
        print_error "MODULE.bazel file not found"
    fi
}

# Show dependency summary
show_summary() {
    print_header "Dependency Check Summary"

    local total_checks=$((DEPS_OK + DEPS_MISSING + DEPS_WARNING))

    echo -e "Total checks: $total_checks"
    echo -e "${GREEN}OK: $DEPS_OK${NC}"
    echo -e "${YELLOW}Warnings: $DEPS_WARNING${NC}"
    echo -e "${RED}Missing: $DEPS_MISSING${NC}"
    echo ""

    if [ $DEPS_MISSING -gt 0 ]; then
        print_error "Some required dependencies are missing!"
        echo ""
        echo "Please install the missing dependencies before building."
        return 1
    elif [ $DEPS_WARNING -gt 0 ]; then
        print_warning "Some optional dependencies are missing"
        echo ""
        echo "You may still be able to build, but some features might not work."
        return 0
    else
        print_success "All dependencies are satisfied!"
        echo ""
        echo "You can now build OmniTAK Mobile with:"
        echo "  ./scripts/build_omnitak_mobile.sh"
        return 0
    fi
}

# Main function
main() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║        OmniTAK Mobile Dependency Checker                 ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    print_info "Project root: $PROJECT_ROOT"
    print_info "Module directory: $MODULE_DIR"
    print_info "Platform: $(uname)"

    # Run all checks
    print_header "Checking Core Build Tools"
    check_bazel
    check_git
    check_nodejs
    check_typescript
    check_python

    print_header "Checking Platform Tools"
    check_java
    check_xcode
    check_android_sdk
    check_android_ndk

    check_optional_tools
    check_valdi_deps
    check_maplibre_xcframework
    check_npm_packages
    check_build_environment

    # Show summary and exit
    if show_summary; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
