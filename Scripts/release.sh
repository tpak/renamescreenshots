#!/bin/bash
set -euo pipefail

VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        *)
            if [[ -z "$VERSION" ]]; then
                VERSION="$1"
            fi
            shift
            ;;
    esac
done

# ── Phase 1: Validate ──────────────────────────────────────────────

if [[ -z "$VERSION" ]]; then
    echo "Usage: Scripts/release.sh X.Y.Z"
    exit 1
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: VERSION must match X.Y.Z pattern (got: $VERSION)"
    exit 1
fi

if [[ "$(git branch --show-current)" != "main" ]]; then
    echo "Error: Must be on 'main' branch (currently on '$(git branch --show-current)')"
    exit 1
fi

if [[ -n "$(git diff --stat HEAD)" ]]; then
    echo "Error: Working tree has uncommitted changes. Commit or stash changes first."
    exit 1
fi

if git tag -l "v$VERSION" | grep -q "v$VERSION"; then
    echo "Error: Tag v$VERSION already exists"
    exit 1
fi

for cmd in gh ditto xcrun codesign; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: Required tool '$cmd' not found"
        exit 1
    fi
done

# Verify Developer ID certificate is available
SIGN_IDENTITY="Developer ID Application"
if ! security find-identity -v -p codesigning | grep -q "$SIGN_IDENTITY"; then
    echo "Error: No '$SIGN_IDENTITY' certificate found in keychain."
    echo "       Install a Developer ID Application certificate from https://developer.apple.com"
    exit 1
fi

# Verify notarization credentials are stored
NOTARY_PROFILE="screenshotrenamer-notary"
if ! xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" &>/dev/null; then
    echo "Error: Notarization credentials not found. Store them with:"
    echo "  xcrun notarytool store-credentials \"$NOTARY_PROFILE\" \\"
    echo "    --apple-id \"YOUR_APPLE_ID\" --team-id \"YOUR_TEAM_ID\" --password \"APP_SPECIFIC_PASSWORD\""
    exit 1
fi

# Find sign_update (Sparkle EdDSA signing tool)
SIGN_UPDATE=""
SPARKLE_PATHS=(
    ".build/artifacts/sparkle/Sparkle/bin/sign_update"
)
for path in "${SPARKLE_PATHS[@]}"; do
    for expanded in $path; do
        if [[ -x "$expanded" ]]; then
            SIGN_UPDATE="$expanded"
            break 2
        fi
    done
done

if [[ -z "$SIGN_UPDATE" ]]; then
    echo "Error: Sparkle sign_update not found. Run 'swift build' first to resolve SPM packages."
    exit 1
fi

echo "Using sign_update: $SIGN_UPDATE"

# Verify Sparkle EdDSA private key is available
if ! "$SIGN_UPDATE" --help &>/dev/null && ! "$SIGN_UPDATE" 2>&1 | grep -q "Usage"; then
    echo "Warning: sign_update may not be working correctly"
fi

echo ""
echo "=== Releasing Screenshot Renamer v$VERSION ==="
echo ""

# ── Phase 2: Bump version + build ──────────────────────────────────

CURRENT_VERSION=$(cat VERSION | tr -d '[:space:]')
if [[ "$CURRENT_VERSION" != "$VERSION" ]]; then
    echo "── Bumping version from $CURRENT_VERSION to $VERSION..."
    echo "$VERSION" > VERSION
    ./Scripts/inject-version.sh
    git add VERSION
    git commit -m "Bump version to $VERSION"
else
    echo "── Version already set to $VERSION."
fi

echo "── Building release..."
./Scripts/build-app.sh --sign

APP_NAME="ScreenshotRenamer.app"
if [[ ! -d "$APP_NAME" ]]; then
    echo "Error: $APP_NAME not found after build"
    exit 1
fi

# ── Phase 3: Notarize ──────────────────────────────────────────────

RELEASE_DIR="/tmp/screenshotrenamer-release"
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

ZIP_PATH="$RELEASE_DIR/ScreenshotRenamer.zip"
echo "── Creating zip for notarization..."
ditto -c -k --norsrc --keepParent "$APP_NAME" "$ZIP_PATH"

echo "── Submitting for notarization (this may take a few minutes)..."
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "── Stapling notarization ticket..."
xcrun stapler staple "$APP_NAME"

# Strip xattrs after stapling, re-zip without resource forks
xattr -rc "$APP_NAME"
rm "$ZIP_PATH"
ditto -c -k --norsrc --keepParent "$APP_NAME" "$ZIP_PATH"
echo "  Notarized and stapled."

# ── Phase 4: Create DMG ────────────────────────────────────────────

DMG_PATH="$RELEASE_DIR/ScreenshotRenamer.dmg"
echo "── Creating DMG..."
hdiutil create -volname "Screenshot Renamer" \
    -srcfolder "$APP_NAME" \
    -ov -format UDZO \
    "$DMG_PATH"

# ── Phase 5: Sparkle EdDSA sign ────────────────────────────────────

echo "── Signing with Sparkle EdDSA..."
SIGN_OUTPUT="$("$SIGN_UPDATE" "$ZIP_PATH")"
echo "  $SIGN_OUTPUT"

ED_SIGNATURE="$(echo "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
FILE_LENGTH="$(echo "$SIGN_OUTPUT" | sed -n 's/.*length="\([^"]*\)".*/\1/p')"

if [[ -z "$ED_SIGNATURE" || -z "$FILE_LENGTH" ]]; then
    echo "Error: Failed to parse Sparkle signature output"
    echo "Raw output: $SIGN_OUTPUT"
    exit 1
fi

echo "  Signature: ${ED_SIGNATURE:0:20}..."
echo "  Length: $FILE_LENGTH"

# ── Phase 6: Generate checksums ────────────────────────────────────

echo "── Generating checksums..."
cd "$RELEASE_DIR"
shasum -a 256 ScreenshotRenamer.zip > ScreenshotRenamer.zip.sha256
shasum -a 256 ScreenshotRenamer.dmg > ScreenshotRenamer.dmg.sha256
ZIP_SHA256=$(shasum -a 256 ScreenshotRenamer.zip | awk '{print $1}')
cd - > /dev/null

echo "  ZIP SHA256: $ZIP_SHA256"

# ── Phase 7: GitHub release ────────────────────────────────────────

echo "── Creating git tag and pushing..."
# Check if tag already exists remotely (e.g., created by auto-tag.yml)
if git ls-remote --tags origin "refs/tags/v$VERSION" | grep -q "v$VERSION"; then
    echo "  Tag v$VERSION already exists on remote (created by auto-tag workflow)."
    # Ensure we have the tag locally
    git fetch origin "refs/tags/v$VERSION:refs/tags/v$VERSION" 2>/dev/null || true
else
    git tag -a "v$VERSION" -m "Release v$VERSION"
fi
# Push version bump and tag (skips tag if already exists)
git push origin main 2>/dev/null || true
git push origin "v$VERSION" 2>/dev/null || true

echo "── Creating GitHub release..."

# Generate changelog from git log
PREVIOUS_TAG=$(git describe --tags --abbrev=0 "v$VERSION^" 2>/dev/null || echo "")
if [[ -n "$PREVIOUS_TAG" ]]; then
    COMMITS=$(git log "$PREVIOUS_TAG..v$VERSION" --pretty=format:"- %s (%h)" --no-merges)
else
    COMMITS=$(git log --pretty=format:"- %s (%h)" --no-merges -10)
fi

RELEASE_NOTES="## What's Changed

$COMMITS

**Full Changelog**: https://github.com/tpak/ScreenshotRenamer/compare/${PREVIOUS_TAG}...v$VERSION

---
📖 See the [README](https://github.com/tpak/ScreenshotRenamer#readme) for installation and usage instructions."

gh release create "v$VERSION" \
    "$ZIP_PATH" \
    "$ZIP_PATH.sha256" \
    "$DMG_PATH" \
    "$DMG_PATH.sha256" \
    --title "Screenshot Renamer v$VERSION" \
    --notes "$RELEASE_NOTES" \
    --latest

echo "── GitHub release created."

# ── Phase 8: Update appcast ────────────────────────────────────────

echo "── Updating appcast.xml..."
PUB_DATE="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S %z')"
DOWNLOAD_URL="https://github.com/tpak/ScreenshotRenamer/releases/download/v$VERSION/ScreenshotRenamer.zip"

APPCAST_CONTENT="<?xml version=\"1.0\" standalone=\"yes\"?>
<rss xmlns:sparkle=\"http://www.andymatuschak.org/xml-namespaces/sparkle\" version=\"2.0\">
  <channel>
    <title>Screenshot Renamer</title>
    <item>
      <title>Version $VERSION</title>
      <pubDate>$PUB_DATE</pubDate>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>11.0</sparkle:minimumSystemVersion>
      <enclosure url=\"$DOWNLOAD_URL\"
                 sparkle:edSignature=\"$ED_SIGNATURE\"
                 length=\"$FILE_LENGTH\"
                 type=\"application/octet-stream\" />
    </item>
  </channel>
</rss>"

# Deploy appcast to gh-pages using a temporary clone (avoids polluting working tree)
PAGES_DIR="/tmp/screenshotrenamer-ghpages"
rm -rf "$PAGES_DIR"
git clone --branch gh-pages --single-branch --depth 1 \
    "https://github.com/tpak/ScreenshotRenamer.git" "$PAGES_DIR" 2>/dev/null

echo "$APPCAST_CONTENT" > "$PAGES_DIR/appcast.xml"
cd "$PAGES_DIR"
git add appcast.xml
if ! git diff --cached --quiet; then
    git commit -m "Update appcast for v$VERSION"
    git push origin gh-pages
    echo "── Appcast deployed to gh-pages."
else
    echo "── Appcast unchanged."
fi
cd - > /dev/null
rm -rf "$PAGES_DIR"

# ── Phase 9: Update Homebrew Cask ──────────────────────────────────

echo "── Updating Homebrew Cask..."
TAP_DIR="/tmp/homebrew-screenshotrenamer"
if gh repo view tpak/homebrew-screenshotrenamer &>/dev/null; then
    rm -rf "$TAP_DIR"
    gh repo clone tpak/homebrew-screenshotrenamer "$TAP_DIR" 2>/dev/null

    CASK_FILE="$TAP_DIR/Casks/screenshot-renamer.rb"
    if [[ -f "$CASK_FILE" ]]; then
        sed -i '' "s/version \"[^\"]*\"/version \"$VERSION\"/" "$CASK_FILE"
        sed -i '' "s/sha256 \"[^\"]*\"/sha256 \"$ZIP_SHA256\"/" "$CASK_FILE"

        cd "$TAP_DIR"
        git add -A
        if ! git diff --cached --quiet; then
            git commit -m "Update to v$VERSION"
            git push origin main
            echo "── Homebrew Cask updated to v$VERSION."
        else
            echo "── Cask already up to date."
        fi
        cd - > /dev/null
    else
        echo "  Warning: Cask file not found at $CASK_FILE. Skipping Homebrew update."
    fi
    rm -rf "$TAP_DIR"
else
    echo "  Homebrew tap repo not found. Skipping. Create it with:"
    echo "    gh repo create tpak/homebrew-screenshotrenamer --public"
fi

# ── Phase 10: Summary ─────────────────────────────────────────────

echo ""
echo "=== Release v$VERSION complete! ==="
echo ""
echo "  GitHub release: https://github.com/tpak/ScreenshotRenamer/releases/tag/v$VERSION"
echo "  Appcast updated with EdDSA signature"
echo "  ZIP SHA256: $ZIP_SHA256"
echo ""
echo "  Artifacts in $RELEASE_DIR:"
echo "    - ScreenshotRenamer.zip (signed, notarized, stapled)"
echo "    - ScreenshotRenamer.dmg"
echo "    - *.sha256 checksums"
echo ""
