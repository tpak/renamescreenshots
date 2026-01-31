# Screenshot Renamer

[![CI/CD](https://github.com/tpak/renamescreenshots/actions/workflows/swift.yml/badge.svg?branch=main)](https://github.com/tpak/renamescreenshots/actions/workflows/swift.yml)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/tpak/renamescreenshots)](https://github.com/tpak/renamescreenshots/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-macOS%2011.0%2B-blue.svg)](https://www.apple.com/macos/)

Native macOS menu bar app that automatically renames screenshots from 12-hour to 24-hour format so they sort chronologically in Finder.

**Before:** `Screenshot 2024-05-24 at 1.23.45 PM.png`
**After:** `screenshot 2024-05-24 at 13.23.45.png`

Also handles 24-hour timestamps (prefix lowercasing) and parenthesized sequence numbers like `(2)`.

## Installation

### Download (Recommended)

1. Download **ScreenshotRenamer.dmg** from [GitHub Releases](https://github.com/tpak/renamescreenshots/releases/latest)
2. Open the DMG and drag the app to Applications
3. Right-click the app and select "Open" (first run only, to bypass Gatekeeper)
4. The camera icon appears in your menu bar — screenshots are now automatically renamed

### Build from Source

```bash
git clone https://github.com/tpak/renamescreenshots.git
cd renamescreenshots
./Scripts/build-app.sh
open ScreenshotRenamer.app
```

Requires macOS 11.0+ and Swift 5.7+. No external dependencies.

## Features

- **Auto-rename** — watches for new screenshots via FSEvents, renames in real-time
- **Quick Rename** — batch rename existing screenshots in one click
- **Screenshot Settings** — control macOS screenshot preferences from the menu:
  - Save location, filename prefix
  - Thumbnail preview, mouse pointer, window shadow toggles
  - Include date in filename toggle
  - Format (PNG/JPG/PDF/TIFF)
  - Reset to defaults
- **Launch at Login** — native SMAppService on macOS 13+, LaunchAgent on older versions
- **Debug Logging** — optional file-based logging for diagnostics
- **264KB binary** — native Swift, no dependencies, instant startup

## Usage

The camera icon in your menu bar provides:

| Menu Item | Description |
|-----------|-------------|
| Stop/Start Watcher | Toggle automatic renaming |
| Quick Rename... | Rename all existing screenshots now |
| Change Location... | Set system screenshot save folder |
| Screenshot Settings | Submenu for all macOS screenshot preferences |
| Debug | Enable/disable debug logging, set log location |
| Launch at Login | Toggle auto-start |
| Quit | Exit the app |

The app auto-detects your macOS screenshot location and prefix via `com.apple.screencapture` defaults.

## Development

```bash
swift test    # Run all 74 tests
swift build   # Debug build
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full development workflow and release process.

## Uninstallation

```bash
pkill -9 ScreenshotRenamer
rm -rf /Applications/ScreenshotRenamer.app
```

## License

MIT License — see [LICENSE](LICENSE) for details.

Created by [Chris Tirpak](https://github.com/tpak)
