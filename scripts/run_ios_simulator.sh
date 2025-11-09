#!/bin/bash
#
# run_ios_simulator.sh
# Run OmniTAK Mobile on iOS Simulator
#
# Usage:
#   ./scripts/run_ios_simulator.sh [device_name]
#
# Examples:
#   ./scripts/run_ios_simulator.sh                    # Use default simulator
#   ./scripts/run_ios_simulator.sh "iPhone 15 Pro"    # Use specific device
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_NAME=${1:-"iPhone 15 Pro"}
BUNDLE_ID="com.engindearing.omnitak.mobile"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}OmniTAK Mobile - iOS Simulator${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check for required tools
command -v xcrun >/dev/null 2>&1 || {
    echo -e "${RED}Error: xcrun is not installed${NC}"
    echo "Xcode command line tools are required"
    exit 1
}

# Navigate to project root
cd "$PROJECT_ROOT"

# Build for simulator if not already built
echo -e "${YELLOW}Step 1: Building for iOS Simulator...${NC}"
./scripts/build_ios.sh simulator debug

# Find the .app bundle
APP_BUNDLE=$(bazel info bazel-bin 2>/dev/null)/apps/omnitak_mobile_ios/OmniTAKMobile-Simulator.app

if [ ! -d "$APP_BUNDLE" ]; then
    # Try alternative name
    APP_BUNDLE=$(bazel info bazel-bin 2>/dev/null)/apps/omnitak_mobile_ios/OmniTAKMobile.app
fi

if [ ! -d "$APP_BUNDLE" ]; then
    echo -e "${RED}Error: Could not find app bundle${NC}"
    echo "Expected location: $APP_BUNDLE"
    exit 1
fi

echo -e "${GREEN}Found app bundle: $APP_BUNDLE${NC}"
echo ""

# List available simulators
echo -e "${YELLOW}Step 2: Finding iOS Simulators...${NC}"
xcrun simctl list devices available | grep -i iphone || true
echo ""

# Find simulator UDID
SIMULATOR_UDID=$(xcrun simctl list devices available | grep "$DEVICE_NAME" | head -1 | grep -o '[A-F0-9]\{8\}-[A-F0-9]\{4\}-[A-F0-9]\{4\}-[A-F0-9]\{4\}-[A-F0-9]\{12\}' || true)

if [ -z "$SIMULATOR_UDID" ]; then
    echo -e "${YELLOW}Warning: Simulator '$DEVICE_NAME' not found${NC}"
    echo "Using first available iPhone simulator..."

    SIMULATOR_UDID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -o '[A-F0-9]\{8\}-[A-F0-9]\{4\}-[A-F0-9]\{4\}-[A-F0-9]\{4\}-[A-F0-9]\{12\}' || true)

    if [ -z "$SIMULATOR_UDID" ]; then
        echo -e "${RED}Error: No iPhone simulators found${NC}"
        echo ""
        echo "Available devices:"
        xcrun simctl list devices available
        exit 1
    fi

    ACTUAL_DEVICE_NAME=$(xcrun simctl list devices available | grep "$SIMULATOR_UDID" | sed 's/(.*//' | xargs)
    echo -e "${GREEN}Found: $ACTUAL_DEVICE_NAME${NC}"
fi

echo -e "${GREEN}Simulator UDID: $SIMULATOR_UDID${NC}"
echo ""

# Boot simulator if not already booted
echo -e "${YELLOW}Step 3: Booting Simulator...${NC}"
SIMULATOR_STATE=$(xcrun simctl list devices | grep "$SIMULATOR_UDID" | sed 's/.*(//;s/).*//')

if [ "$SIMULATOR_STATE" != "Booted" ]; then
    echo "Booting simulator..."
    xcrun simctl boot "$SIMULATOR_UDID" || true
    sleep 3
    echo -e "${GREEN}Simulator booted${NC}"
else
    echo -e "${GREEN}Simulator already running${NC}"
fi

# Open Simulator.app
open -a Simulator

echo ""
echo -e "${YELLOW}Step 4: Installing App...${NC}"

# Uninstall old version if exists
xcrun simctl uninstall "$SIMULATOR_UDID" "$BUNDLE_ID" 2>/dev/null || true

# Install app
xcrun simctl install "$SIMULATOR_UDID" "$APP_BUNDLE"
echo -e "${GREEN}App installed successfully${NC}"

echo ""
echo -e "${YELLOW}Step 5: Launching App...${NC}"

# Launch app
xcrun simctl launch --console "$SIMULATOR_UDID" "$BUNDLE_ID"

LAUNCH_STATUS=$?

echo ""
if [ $LAUNCH_STATUS -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}App Launched Successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}The app is now running in the simulator.${NC}"
    echo -e "${BLUE}Console output will appear here.${NC}"
    echo ""
    echo "To view logs, run:"
    echo "  xcrun simctl spawn $SIMULATOR_UDID log stream --predicate 'processImagePath contains \"OmniTAK\"'"
    echo ""
    echo "To stop the simulator:"
    echo "  xcrun simctl shutdown $SIMULATOR_UDID"
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Failed to Launch App${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
