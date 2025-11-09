#!/bin/bash
#
# build_ios.sh
# Build OmniTAK Mobile for iOS
#
# Usage:
#   ./scripts/build_ios.sh [device|simulator] [debug|release]
#
# Examples:
#   ./scripts/build_ios.sh simulator debug    # Build for simulator in debug mode
#   ./scripts/build_ios.sh device release     # Build for device in release mode
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TARGET=${1:-simulator}
BUILD_MODE=${2:-debug}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OmniTAK Mobile - iOS Build${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Target: $TARGET"
echo "Build Mode: $BUILD_MODE"
echo "Project Root: $PROJECT_ROOT"
echo ""

# Check for required tools
command -v bazel >/dev/null 2>&1 || {
    echo -e "${RED}Error: bazel is not installed${NC}"
    echo "Install bazel from: https://bazel.build/"
    exit 1
}

command -v xcodebuild >/dev/null 2>&1 || {
    echo -e "${RED}Error: xcodebuild is not installed${NC}"
    echo "Xcode command line tools are required"
    exit 1
}

# Navigate to project root
cd "$PROJECT_ROOT"

# Set Bazel config based on target
if [ "$TARGET" = "simulator" ]; then
    BAZEL_CONFIG="ios_sim_arm64"
    APP_TARGET="//apps/omnitak_mobile_ios:OmniTAKMobile-Simulator"
    echo -e "${YELLOW}Building for iOS Simulator (arm64)${NC}"
elif [ "$TARGET" = "device" ]; then
    BAZEL_CONFIG="ios_arm64"
    APP_TARGET="//apps/omnitak_mobile_ios:OmniTAKMobile"
    echo -e "${YELLOW}Building for iOS Device (arm64)${NC}"
else
    echo -e "${RED}Error: Invalid target '$TARGET'${NC}"
    echo "Usage: $0 [device|simulator] [debug|release]"
    exit 1
fi

# Set compilation mode
if [ "$BUILD_MODE" = "debug" ]; then
    COMPILATION_MODE="dbg"
elif [ "$BUILD_MODE" = "release" ]; then
    COMPILATION_MODE="opt"
else
    echo -e "${RED}Error: Invalid build mode '$BUILD_MODE'${NC}"
    echo "Usage: $0 [device|simulator] [debug|release]"
    exit 1
fi

# Build command
echo -e "${YELLOW}Running Bazel build...${NC}"
echo ""

bazel build \
    --config=macos \
    --compilation_mode=$COMPILATION_MODE \
    --ios_minimum_os=14.0 \
    --apple_platform_type=ios \
    --cpu=${BAZEL_CONFIG/ios_/} \
    $APP_TARGET

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Build Successful!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    # Find the output .app bundle
    APP_BUNDLE=$(bazel info bazel-bin)/apps/omnitak_mobile_ios/OmniTAKMobile*.app

    if [ -d "$APP_BUNDLE" ]; then
        echo "App bundle location:"
        echo "  $APP_BUNDLE"
        echo ""
        echo "To install on simulator, run:"
        echo "  ./scripts/run_ios_simulator.sh"
    fi
else
    echo ""
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Build Failed${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
