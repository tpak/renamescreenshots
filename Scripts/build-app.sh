#!/bin/bash
set -e

echo "🔨 Building Screenshot Renamer..."

# Read version from VERSION file
if [ ! -f "VERSION" ]; then
    echo "❌ ERROR: VERSION file not found"
    exit 1
fi
VERSION=$(cat VERSION | tr -d '[:space:]')
echo "📌 Version: $VERSION"

# Backup original Info.plist
PLIST_PATH="Sources/ScreenshotRenamer/Resources/Info.plist"
cp "$PLIST_PATH" "$PLIST_PATH.backup"

# Inject version into Info.plist
./Scripts/inject-version.sh

# Build release binary
swift build -c release

# Restore original Info.plist
mv "$PLIST_PATH.backup" "$PLIST_PATH"

# Create .app bundle structure
APP_NAME="ScreenshotRenamer.app"
APP_DIR="$APP_NAME/Contents"
rm -rf "$APP_NAME"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

# Copy binary
cp .build/release/ScreenshotRenamer "$APP_DIR/MacOS/"
chmod +x "$APP_DIR/MacOS/ScreenshotRenamer"

# Copy Info.plist
cp Sources/ScreenshotRenamer/Resources/Info.plist "$APP_DIR/"

# Code sign (ad-hoc for local use)
codesign --force --deep --sign - "$APP_NAME"

echo ""
echo "✅ Build complete!"
echo "📦 App bundle: $(pwd)/$APP_NAME"
echo "📏 Size: $(du -sh "$APP_NAME" | cut -f1)"
echo "🏷️  Version: $VERSION"
echo ""
echo "To install: cp -r $APP_NAME /Applications/"
echo "To run now: open $APP_NAME"
