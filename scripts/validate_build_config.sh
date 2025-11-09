#!/usr/bin/env bash

# Build Configuration Validation Script for OmniTAK Mobile
# This script validates that all required Bazel build files and configurations are present

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULE_DIR="$PROJECT_ROOT/modules/omnitak_mobile"

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
    ((CHECKS_PASSED++))
}

print_error() {
    echo -e "${RED}✗${NC} $1"
    ((CHECKS_FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if file exists
check_file_exists() {
    local file_path="$1"
    local description="$2"

    if [ -f "$file_path" ]; then
        print_success "$description exists: $file_path"
        return 0
    else
        print_error "$description missing: $file_path"
        return 1
    fi
}

# Check if directory exists
check_dir_exists() {
    local dir_path="$1"
    local description="$2"

    if [ -d "$dir_path" ]; then
        print_success "$description exists: $dir_path"
        return 0
    else
        print_error "$description missing: $dir_path"
        return 1
    fi
}

# Validate BUILD.bazel syntax
validate_build_bazel() {
    local build_file="$1"

    if ! command -v bazel &> /dev/null; then
        print_warning "Bazel not installed, skipping syntax validation"
        return 0
    fi

    # Try to parse the BUILD file
    if bazel query "kind(rule, $build_file:*)" &> /dev/null 2>&1; then
        print_success "BUILD.bazel syntax is valid"
        return 0
    else
        print_error "BUILD.bazel has syntax errors"
        return 1
    fi
}

# Validate module.yaml
validate_module_yaml() {
    local yaml_file="$1"

    if ! command -v yq &> /dev/null; then
        print_warning "yq not installed, skipping YAML validation"
        return 0
    fi

    # Check if YAML is valid
    if yq eval '.' "$yaml_file" &> /dev/null; then
        print_success "module.yaml is valid YAML"

        # Check required fields
        if yq eval '.output_target' "$yaml_file" &> /dev/null; then
            print_success "module.yaml has output_target field"
        else
            print_warning "module.yaml missing output_target field"
        fi

        if yq eval '.dependencies' "$yaml_file" &> /dev/null; then
            print_success "module.yaml has dependencies field"
        else
            print_warning "module.yaml missing dependencies field"
        fi

        if yq eval '.compilation_mode' "$yaml_file" &> /dev/null; then
            print_success "module.yaml has compilation_mode field"
        else
            print_warning "module.yaml missing compilation_mode field"
        fi

        return 0
    else
        print_error "module.yaml is not valid YAML"
        return 1
    fi
}

# Check TypeScript configuration
check_typescript_config() {
    local tsconfig="$MODULE_DIR/tsconfig.json"

    if [ -f "$tsconfig" ]; then
        print_success "tsconfig.json exists"

        # Validate JSON if jq is available
        if command -v jq &> /dev/null; then
            if jq empty "$tsconfig" &> /dev/null; then
                print_success "tsconfig.json is valid JSON"
            else
                print_error "tsconfig.json is not valid JSON"
            fi
        fi
    else
        print_error "tsconfig.json missing"
    fi
}

# Check for TypeScript source files
check_typescript_sources() {
    local src_count=$(find "$MODULE_DIR/src" -name "*.ts" -o -name "*.tsx" 2>/dev/null | wc -l)

    if [ "$src_count" -gt 0 ]; then
        print_success "Found $src_count TypeScript source files"
    else
        print_error "No TypeScript source files found in src/"
    fi
}

# Check dependencies
check_dependencies() {
    print_header "Checking Dependencies"

    # Check valdi_core
    if [ -d "$PROJECT_ROOT/src/valdi_modules/src/valdi/valdi_core" ]; then
        print_success "valdi_core dependency found"
    else
        print_error "valdi_core dependency missing"
    fi

    # Check valdi_tsx
    if [ -d "$PROJECT_ROOT/src/valdi_modules/src/valdi/valdi_tsx" ]; then
        print_success "valdi_tsx dependency found"
    else
        print_error "valdi_tsx dependency missing"
    fi
}

# Check Bazel workspace configuration
check_workspace_config() {
    print_header "Checking Workspace Configuration"

    check_file_exists "$PROJECT_ROOT/WORKSPACE" "WORKSPACE file"
    check_file_exists "$PROJECT_ROOT/MODULE.bazel" "MODULE.bazel file"
    check_file_exists "$PROJECT_ROOT/.bazelrc" ".bazelrc file"
    check_file_exists "$PROJECT_ROOT/.bazelversion" ".bazelversion file"

    if [ -f "$PROJECT_ROOT/.bazelversion" ]; then
        local bazel_version=$(cat "$PROJECT_ROOT/.bazelversion")
        print_info "Required Bazel version: $bazel_version"

        if command -v bazel &> /dev/null; then
            local installed_version=$(bazel version | grep "Build label" | awk '{print $3}')
            print_info "Installed Bazel version: $installed_version"
        fi
    fi
}

# Check module structure
check_module_structure() {
    print_header "Checking Module Structure"

    check_dir_exists "$MODULE_DIR" "OmniTAK Mobile module directory"
    check_file_exists "$MODULE_DIR/BUILD.bazel" "Module BUILD.bazel"
    check_file_exists "$MODULE_DIR/module.yaml" "Module module.yaml"
    check_dir_exists "$MODULE_DIR/src" "Source directory"
    check_dir_exists "$MODULE_DIR/android" "Android directory"
    check_dir_exists "$MODULE_DIR/ios" "iOS directory"

    # Check for res directory (optional)
    if [ -d "$MODULE_DIR/res" ]; then
        print_success "Resource directory exists"
    else
        print_warning "Resource directory (res/) not found - this is optional"
    fi
}

# Check Android configuration
check_android_config() {
    print_header "Checking Android Configuration"

    check_dir_exists "$MODULE_DIR/android" "Android directory"

    if [ -d "$MODULE_DIR/android/native" ]; then
        print_success "Android native directory exists"
    fi

    if [ -d "$MODULE_DIR/android/maplibre" ]; then
        print_success "Android MapLibre directory exists"
    fi
}

# Check iOS configuration
check_ios_config() {
    print_header "Checking iOS Configuration"

    check_dir_exists "$MODULE_DIR/ios" "iOS directory"

    if [ -d "$MODULE_DIR/ios/native" ]; then
        print_success "iOS native directory exists"
    fi

    if [ -d "$MODULE_DIR/ios/maplibre" ]; then
        print_success "iOS MapLibre directory exists"
    fi
}

# Check bzl files
check_bzl_files() {
    print_header "Checking Bazel Build Files"

    check_file_exists "$PROJECT_ROOT/bzl/valdi/valdi_module.bzl" "valdi_module.bzl"

    if [ -d "$PROJECT_ROOT/bzl/valdi" ]; then
        local bzl_count=$(find "$PROJECT_ROOT/bzl/valdi" -name "*.bzl" | wc -l)
        print_success "Found $bzl_count .bzl files in bzl/valdi"
    fi
}

# Main validation
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║     OmniTAK Mobile Build Configuration Validator         ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    print_info "Project root: $PROJECT_ROOT"
    print_info "Module directory: $MODULE_DIR"

    # Run all checks
    check_workspace_config
    check_module_structure
    check_dependencies
    check_typescript_config
    check_typescript_sources
    check_android_config
    check_ios_config
    check_bzl_files

    # Validate configuration files
    print_header "Validating Configuration Files"

    if [ -f "$MODULE_DIR/BUILD.bazel" ]; then
        # Note: Full validation requires Bazel to be installed
        print_info "BUILD.bazel validation requires Bazel to be installed"
    fi

    if [ -f "$MODULE_DIR/module.yaml" ]; then
        validate_module_yaml "$MODULE_DIR/module.yaml"
    fi

    # Print summary
    print_header "Validation Summary"

    local total_checks=$((CHECKS_PASSED + CHECKS_FAILED))
    echo -e "Total checks: $total_checks"
    echo -e "${GREEN}Passed: $CHECKS_PASSED${NC}"

    if [ $CHECKS_FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
        echo ""
        print_error "Build configuration validation failed!"
        echo ""
        echo "Please fix the issues above before attempting to build."
        exit 1
    else
        echo -e "${RED}Failed: $CHECKS_FAILED${NC}"
        echo ""
        print_success "All checks passed! Build configuration is valid."
        echo ""
        echo "You can now run:"
        echo "  ./scripts/build_omnitak_mobile.sh"
        exit 0
    fi
}

# Run main function
main "$@"
