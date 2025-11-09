#!/bin/bash
#
# test_ios.sh
# Run OmniTAK Mobile iOS tests
#
# Usage:
#   ./scripts/test_ios.sh [test_filter]
#
# Examples:
#   ./scripts/test_ios.sh                              # Run all tests
#   ./scripts/test_ios.sh OmniTAKNativeBridgeTests    # Run specific test class
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_FILTER=${1:-""}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OmniTAK Mobile - iOS Tests${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check for required tools
command -v bazel >/dev/null 2>&1 || {
    echo -e "${RED}Error: bazel is not installed${NC}"
    exit 1
}

# Navigate to project root
cd "$PROJECT_ROOT"

# Build test command
TEST_CMD="bazel test //apps/omnitak_mobile_ios:OmniTAKMobileTests \
    --config=ios_sim_debug \
    --test_output=all \
    --ios_minimum_os=14.0"

# Add test filter if specified
if [ -n "$TEST_FILTER" ]; then
    echo -e "${YELLOW}Running tests matching: $TEST_FILTER${NC}"
    TEST_CMD="$TEST_CMD --test_filter=$TEST_FILTER"
else
    echo -e "${YELLOW}Running all tests${NC}"
fi

echo ""
echo -e "${YELLOW}Test command:${NC}"
echo "$TEST_CMD"
echo ""

# Run tests
eval $TEST_CMD

TEST_STATUS=$?

echo ""
if [ $TEST_STATUS -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}All Tests Passed!${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Tests Failed${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
