#!/bin/bash
set -e

echo "🔨 Building Screenshot Renamer..."

# Build release binary
swift build -c release

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
echo ""
echo "To install: cp -r $APP_NAME /Applications/"
echo "To run now: open $APP_NAME"
