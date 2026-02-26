# Screenshot Renamer

[![CI/CD](https://github.com/tpak/ScreenshotRenamer/actions/workflows/swift.yml/badge.svg?branch=main)](https://github.com/tpak/ScreenshotRenamer/actions/workflows/swift.yml)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/tpak/ScreenshotRenamer)](https://github.com/tpak/ScreenshotRenamer/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-macOS%2011.0%2B-blue.svg)](https://www.apple.com/macos/)

Native macOS menu bar app that automatically renames screenshots from 12-hour to 24-hour format so they sort chronologically in Finder.

**Before:** `Screenshot 2024-05-24 at 1.23.45 PM.png`
**After:** `screenshot 2024-05-24 at 13.23.45.png`

Also handles 24-hour timestamps (prefix lowercasing) and parenthesized sequence numbers like `(2)`.

## Installation

### Download (Recommended)

1. Download **ScreenshotRenamer.dmg** from [GitHub Releases](https://github.com/tpak/ScreenshotRenamer/releases/latest)
2. Open the DMG and drag the app to Applications
3. Right-click the app and select "Open" (first run only, to bypass Gatekeeper)
4. The camera icon appears in your menu bar — screenshots are now automatically renamed

### Build from Source

```bash
git clone https://github.com/tpak/ScreenshotRenamer.git
cd ScreenshotRenamer
./Scripts/build-app.sh
open ScreenshotRenamer.app
```

Requires macOS 11.0+ and Swift 5.7+. No external dependencies.

## Features

- **Auto-rename** — watches for new screenshots via FSEvents, renames in real-time
- **Quick Rename** — batch rename existing screenshots in one click
- **Unified Settings** — all preferences in one dialog:
  - Save location (editable field or folder picker)
  - Thumbnail preview, mouse pointer, window shadow, date in filename toggles
  - Launch at login
  - Format (PNG/JPG/PDF/TIFF)
  - Debug logging with custom log location
  - Reset to defaults
- **Menu Quick-Reference** — current settings displayed in menu bar dropdown
- **Single Instance** — prevents duplicate app instances from running
- **Native App Icon** — camera icon displays in Finder and About dialog
- **Lightweight** — native Swift, no dependencies, instant startup

## Usage

Click the camera icon in your menu bar:

| Menu Item | Description |
|-----------|-------------|
| Stop/Start Watcher | Toggle automatic renaming |
| Quick Rename... | Rename all existing screenshots now |
| Settings... | Open the unified settings dialog |
| About | App version and GitHub link |
| Quit | Exit the app |

Below the menu items, you'll see a quick-reference display of your current settings (location, prefix, format, options, debug status).

The app auto-detects your macOS screenshot location and prefix via `com.apple.screencapture` defaults.

## Development

```bash
swift test    # Run all 74 tests
swift build   # Debug build
./Scripts/build-app.sh          # Build release app bundle
./Scripts/build-app.sh --bump   # Build and increment patch version
./Scripts/bump-version.sh minor # Manually bump minor version
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full development workflow and release process.

## Uninstallation

```bash
pkill ScreenshotRenamer; rm -rf /Applications/ScreenshotRenamer.app
```

## License

MIT License — see [LICENSE](LICENSE) for details.

Created by [Chris Tirpak](https://github.com/tpak)
