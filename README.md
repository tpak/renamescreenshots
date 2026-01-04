# Screenshot Renamer
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Native macOS menu bar app to automatically rename screenshots from 12-hour to 24-hour format.

**Before:** `Screenshot 2024-05-24 at 1.23.45 PM.png`
**After:** `screenshot 2024-05-24 at 13.23.45.png`

## Why?

macOS screenshot names don't sort chronologically in Finder due to 12-hour time format. This native Swift app fixes that, making screenshots easier to find and organize.

**Features:**
- 📷 Menu bar app - lives in your status bar
- 🔄 Auto-rename - watches for new screenshots
- ⚡ Instant startup - native Swift binary (224KB)
- 🎯 Auto-detect - reads your macOS screenshot settings
- 🔒 Secure - full path validation and sandboxing support

## Requirements

- **macOS 11.0 (Big Sur)** or later
- No external dependencies!

## Quick Start

### 1. Build

```bash
./Scripts/build-app.sh
```

This creates `ScreenshotRenamer.app` (224KB) in seconds.

### 2. Install

```bash
cp -r ScreenshotRenamer.app /Applications/
```

### 3. Run

```bash
open /Applications/ScreenshotRenamer.app
```

The 📷 camera icon will appear in your menu bar. Take a screenshot and it will be automatically renamed!

## Building from Source

### Quick Build (Recommended)

```bash
./Scripts/build-app.sh
```

### Manual Build

```bash
# Build release binary
swift build -c release

# Create .app bundle
mkdir -p ScreenshotRenamer.app/Contents/{MacOS,Resources}
cp .build/release/ScreenshotRenamer ScreenshotRenamer.app/Contents/MacOS/
cp Sources/ScreenshotRenamer/Resources/Info.plist ScreenshotRenamer.app/Contents/
chmod +x ScreenshotRenamer.app/Contents/MacOS/ScreenshotRenamer

# Code sign
codesign --force --deep --sign - ScreenshotRenamer.app
```

## Usage

Once installed, the camera icon 📷 appears in your menu bar with these options:

- **Stop/Start Watcher** - Toggle automatic renaming (on by default)
- **Quick Rename...** - Manually rename existing screenshots
- **Location** - Shows your screenshot save directory
- **Prefix** - Shows detected screenshot prefix
- **Quit** - Exit the app

### Auto-Start on Login

**Option 1: System Preferences**
1. Open System Settings → General → Login Items
2. Click `+` and add Screenshot Renamer.app

**Option 2: LaunchAgent**

Create `~/Library/LaunchAgents/com.tirpak.screenshot-renamer.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tirpak.screenshot-renamer</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/ScreenshotRenamer.app/Contents/MacOS/ScreenshotRenamer</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Then load it:
```bash
launchctl load ~/Library/LaunchAgents/com.tirpak.screenshot-renamer.plist
```

## Advanced Features

### Auto-Detection

The app automatically detects your macOS screenshot settings:
```bash
defaults read com.apple.screencapture location  # Where screenshots save
defaults read com.apple.screencapture name      # Filename prefix
```

### Custom Prefix Support

If you've customized your screenshot name in System Settings, the app preserves it:
- **macOS default:** "Screenshot" → "screenshot"
- **Custom prefix:** "MyScreenshot" → "myscreenshot"

### Sequential Screenshots

Handles rapid screenshots with sequence numbers:
- `Screenshot 2024-01-03 at 1.23.45 PM 1.png` → `screenshot 2024-01-03 at 13.23.45 1.png`
- `Screenshot 2024-01-03 at 1.23.45 PM 2.png` → `screenshot 2024-01-03 at 13.23.45 2.png`

### Security

- **Path validation** - Prevents directory traversal
- **Filename sanitization** - Blocks unsafe characters
- **Whitelist support** - Optional directory restrictions
- **Sandbox ready** - Can run with App Sandbox enabled

## Development

### Running Tests

```bash
swift test
```

All 25 unit tests cover:
- Pattern matching (13 tests)
- File validation (12 tests)

### Project Structure

```
.
├── Sources/
│   └── ScreenshotRenamer/
│       ├── App/
│       │   ├── AppDelegate.swift         # App lifecycle
│       │   ├── MenuBarController.swift   # Menu bar UI
│       │   └── main.swift                # Entry point
│       ├── Core/
│       │   ├── ScreenshotDetector.swift  # Settings detection
│       │   ├── ScreenshotRenamer.swift   # Rename logic
│       │   ├── PatternMatcher.swift      # Regex matching
│       │   └── FileValidator.swift       # Security
│       ├── FileWatcher/
│       │   └── ScreenshotWatcher.swift   # FSEvents watcher
│       ├── Models/
│       │   ├── ScreenshotSettings.swift
│       │   ├── RenameResult.swift
│       │   ├── ScreenshotMatch.swift
│       │   └── ScreenshotError.swift
│       ├── Utilities/
│       │   └── ShellExecutor.swift       # Shell commands
│       └── Resources/
│           └── Info.plist                # App metadata
├── Tests/
│   └── ScreenshotRenamerTests/           # Unit tests
├── Scripts/
│   ├── build-app.sh                      # Build script
│   └── test-rename.swift                 # Test utility
├── Package.swift                         # Swift Package Manager
├── README.md                             # This file
└── LICENSE
```

## Distribution

### Code Signing

**For local use:**
```bash
codesign --force --deep --sign - ScreenshotRenamer.app
```

**For distribution:**

Requires Apple Developer account ($99/year):

```bash
# 1. Sign with Developer ID
codesign --force --deep --sign "Developer ID Application: Your Name" ScreenshotRenamer.app

# 2. Create ZIP
ditto -c -k --keepParent ScreenshotRenamer.app ScreenshotRenamer.zip

# 3. Notarize
xcrun notarytool submit ScreenshotRenamer.zip \
    --apple-id your@email.com \
    --password "app-specific-password" \
    --team-id TEAM_ID \
    --wait

# 4. Staple ticket
xcrun stapler staple ScreenshotRenamer.app

# 5. Create DMG
hdiutil create -volname "Screenshot Renamer" \
    -srcfolder ScreenshotRenamer.app \
    -ov -format UDZO \
    ScreenshotRenamer.dmg
```

## Uninstallation

```bash
# Kill app if running
pkill -9 ScreenshotRenamer

# Remove from Applications
rm -rf /Applications/ScreenshotRenamer.app

# Remove LaunchAgent (if installed)
launchctl unload ~/Library/LaunchAgents/com.tirpak.screenshot-renamer.plist
rm ~/Library/LaunchAgents/com.tirpak.screenshot-renamer.plist
```

## Technical Details

- **Language:** Swift 5.7+
- **Frameworks:** AppKit, CoreServices (FSEvents), Foundation
- **Build System:** Swift Package Manager
- **Binary Size:** 224KB (release build)
- **Memory Usage:** ~20MB at runtime
- **Startup Time:** Instant (<100ms)
- **Tests:** 25 unit tests, 100% core coverage

## Contributing

Contributions welcome! Please:
- Maintain test coverage
- Follow Swift API design guidelines
- Update documentation
- Keep it simple and focused

## Acknowledgments

**Built with native macOS frameworks:**
- **AppKit** - Menu bar UI (NSStatusBar, NSMenu)
- **CoreServices** - FSEvents file monitoring
- **Foundation** - Core Swift functionality

No third-party dependencies! 🎉

## License

MIT License - see [LICENSE](LICENSE) file for details.

Created by [Chris Tirpak](https://github.com/tpak)

---

## Why Native Swift?

Originally built in Python with rumps, this native Swift rewrite offers:

| Feature | Python | Swift |
|---------|--------|-------|
| **Startup** | 1-2 seconds | Instant |
| **Size** | ~100MB | 224KB |
| **Dependencies** | pip, rumps, Flask | None |
| **Performance** | Good | Excellent |
| **Distribution** | pip install | .app / .dmg |
| **Integration** | Good | Native |

The Swift version provides a better user experience while maintaining 100% feature parity.
