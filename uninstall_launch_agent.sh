#!/usr/bin/env bash
#
# Uninstall Screenshot Renamer Launch Agent
# Removes the launch agent that auto-starts the menu bar app on login
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PLIST_NAME="com.screenshot-renamer.menubar.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$PLIST_NAME"

# Helper functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script only works on macOS"
    exit 1
fi

print_header "Screenshot Renamer Launch Agent Uninstaller"

# Check if launch agent exists
if [[ ! -f "$PLIST_PATH" ]]; then
    print_warning "Launch agent not found at: $PLIST_PATH"
    print_info "It may have been already uninstalled or never installed."
    exit 0
fi

print_info "Found launch agent at: $PLIST_PATH"

# Check if it's currently loaded
if launchctl list | grep -q "com.screenshot-renamer.menubar"; then
    print_info "Unloading launch agent..."
    if launchctl unload "$PLIST_PATH" 2>/dev/null; then
        print_success "Launch agent unloaded"
    else
        print_warning "Failed to unload (may not be running)"
    fi
else
    print_info "Launch agent is not currently loaded"
fi

# Remove the plist file
print_info "Removing launch agent file..."
if rm "$PLIST_PATH"; then
    print_success "Removed $PLIST_PATH"
else
    print_error "Failed to remove launch agent file"
    exit 1
fi

# Done
echo ""
print_header "Uninstallation Complete!"
echo ""
print_success "Screenshot Renamer launch agent has been removed"
print_info "The menu bar app will no longer start automatically on login"
echo ""
print_info "The Python package is still installed. To remove it completely:"
echo "  pip uninstall screenshot-renamer"
echo ""
print_info "To reinstall the launch agent later:"
echo "  ./install_launch_agent.sh"
echo ""
