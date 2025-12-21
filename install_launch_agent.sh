#!/usr/bin/env bash
#
# Install Screenshot Renamer as a macOS Launch Agent
# This script installs the menu bar app to start automatically on login
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

print_header "Screenshot Renamer Launch Agent Installer"

# Check Python installation
print_info "Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    print_error "Python 3 is not installed"
    print_info "Install Python 3 and try again"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
print_success "Found Python $PYTHON_VERSION"

# Check if rumps is installed
print_info "Checking for rumps library..."
if ! python3 -c "import rumps" 2>/dev/null; then
    print_warning "rumps library not found"
    print_info "Installing rumps..."

    if pip3 install 'rumps>=0.4.0'; then
        print_success "rumps installed successfully"
    else
        print_error "Failed to install rumps"
        print_info "Try manually: pip3 install 'rumps>=0.4.0'"
        exit 1
    fi
else
    print_success "rumps library found"
fi

# Check if screenshot-rename-menubar command is available
print_info "Checking for screenshot-rename-menubar command..."
if ! command -v screenshot-rename-menubar &> /dev/null; then
    print_warning "screenshot-rename-menubar command not found"
    print_info "Installing package..."

    # Try to find setup location
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    if [[ -f "$SCRIPT_DIR/pyproject.toml" ]]; then
        print_info "Installing from $SCRIPT_DIR..."
        if pip3 install -e "$SCRIPT_DIR"; then
            print_success "Package installed successfully"
        else
            print_error "Failed to install package"
            exit 1
        fi
    else
        print_error "Cannot find package to install"
        print_info "Run this script from the project root directory"
        exit 1
    fi
else
    MENUBAR_PATH=$(command -v screenshot-rename-menubar)
    print_success "Found screenshot-rename-menubar at: $MENUBAR_PATH"
fi

# Get the final path to the menubar command
MENUBAR_COMMAND=$(command -v screenshot-rename-menubar)

# Create LaunchAgents directory if it doesn't exist
if [[ ! -d "$LAUNCH_AGENTS_DIR" ]]; then
    print_info "Creating LaunchAgents directory..."
    mkdir -p "$LAUNCH_AGENTS_DIR"
    print_success "Created $LAUNCH_AGENTS_DIR"
fi

# Check if plist already exists
if [[ -f "$PLIST_PATH" ]]; then
    print_warning "Launch agent already exists at: $PLIST_PATH"
    echo -n "Do you want to overwrite it? [y/N] "
    read -r response

    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi

    # Unload existing agent
    print_info "Unloading existing launch agent..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    print_success "Unloaded existing agent"
fi

# Create the plist file
print_info "Creating launch agent plist..."
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.screenshot-renamer.menubar</string>

    <key>ProgramArguments</key>
    <array>
        <string>$MENUBAR_COMMAND</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/screenshot-renamer-menubar.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/screenshot-renamer-menubar.err</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

print_success "Created launch agent plist at: $PLIST_PATH"

# Load the launch agent
print_info "Loading launch agent..."
if launchctl load "$PLIST_PATH"; then
    print_success "Launch agent loaded successfully"
else
    print_error "Failed to load launch agent"
    print_info "You can try manually: launchctl load $PLIST_PATH"
    exit 1
fi

# Done
echo ""
print_header "Installation Complete!"
echo ""
print_success "Screenshot Renamer menu bar app is now installed"
print_info "The app will start automatically on login"
print_info "You should see it in your menu bar now"
echo ""
print_info "Useful commands:"
echo "  View logs:     tail -f /tmp/screenshot-renamer-menubar.log"
echo "  View errors:   tail -f /tmp/screenshot-renamer-menubar.err"
echo "  Unload agent:  launchctl unload $PLIST_PATH"
echo "  Reload agent:  launchctl unload $PLIST_PATH && launchctl load $PLIST_PATH"
echo ""
print_info "To uninstall:"
echo "  1. launchctl unload $PLIST_PATH"
echo "  2. rm $PLIST_PATH"
echo ""
