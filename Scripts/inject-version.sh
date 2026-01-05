#!/bin/bash
set -e

# Read version from VERSION file
if [ ! -f "VERSION" ]; then
    echo "❌ ERROR: VERSION file not found"
    exit 1
fi

VERSION=$(cat VERSION | tr -d '[:space:]')

if [ -z "$VERSION" ]; then
    echo "❌ ERROR: VERSION file is empty"
    exit 1
fi

PLIST_PATH="Sources/ScreenshotRenamer/Resources/Info.plist"

if [ ! -f "$PLIST_PATH" ]; then
    echo "❌ ERROR: Info.plist not found at $PLIST_PATH"
    exit 1
fi

echo "📝 Injecting version $VERSION into Info.plist..."

# Update CFBundleShortVersionString
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST_PATH"

# Update CFBundleVersion
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PLIST_PATH"

echo "✅ Version $VERSION injected successfully"
