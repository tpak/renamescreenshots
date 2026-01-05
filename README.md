# Screenshot Renamer
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/tpak/renamescreenshots)](https://github.com/tpak/renamescreenshots/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Native macOS menu bar app to automatically rename screenshots from 12-hour to 24-hour format.

**Before:** `Screenshot 2024-05-24 at 1.23.45 PM.png`
**After:** `screenshot 2024-05-24 at 13.23.45.png`

## Why?

macOS screenshot names don't sort chronologically in Finder due to 12-hour time format. This native Swift app fixes that, making screenshots easier to find and organize.

**Features:**
- 📷 Menu bar app - lives in your status bar
- 🔄 Auto-rename - watches for new screenshots in real-time
- ⚙️ Settings control - manage all macOS screenshot preferences
- 📁 Location changer - set system screenshot save location
- 🚀 Launch at login - one-click auto-start on system boot
- ⚡ Instant startup - native Swift binary (264KB)
- 🎯 Auto-detect - reads your macOS screenshot settings
- 🔒 Secure - full path validation and sandboxing support

## Requirements

- **macOS 11.0 (Big Sur)** or later
- No external dependencies!

## Installation

### Option 1: Download from GitHub Releases (Recommended)

**Latest stable release:**

1. Download the latest release from [GitHub Releases](https://github.com/tpak/renamescreenshots/releases/latest)
2. Choose either:
   - **ScreenshotRenamer.dmg** - Disk image with drag-and-drop installer
   - **ScreenshotRenamer.zip** - ZIP archive
3. Open the downloaded file
4. For DMG: Drag app to Applications folder
5. For ZIP: Unzip and move app to Applications
6. Launch the app (Right-click → Open on first run to bypass Gatekeeper)

**Latest development build:**

Get the cutting-edge version from the [latest tag](https://github.com/tpak/renamescreenshots/releases/tag/latest)

**Verify download (optional):**
```bash
shasum -a 256 -c ScreenshotRenamer.zip.sha256
```

### Option 2: Build from Source

See [Building from Source](#building-from-source) below.

### Option 3: Homebrew (Coming Soon)

Homebrew distribution will be available once code signing and notarization are implemented.

## Quick Start

1. [Download the latest release](https://github.com/tpak/renamescreenshots/releases/latest)
2. Open `ScreenshotRenamer.dmg` or unzip `ScreenshotRenamer.zip`
3. Move `ScreenshotRenamer.app` to your Applications folder
4. Right-click the app and select "Open" (first time only, to bypass Gatekeeper)
5. The 📷 camera icon appears in your menu bar
6. Take a screenshot (⌘⇧4) and it will be automatically renamed!

No build required - just download and run!

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

### Main Menu

- **Stop/Start Watcher** - Toggle automatic renaming (auto-starts on launch)
- **Quick Rename...** - Manually rename existing screenshots in current location
- **Change Location...** - Set system screenshot save location (changes where ⌘⇧4 saves)
- **Screenshot Settings** - Configure macOS screenshot preferences (see below)
- **Launch at Login** - Toggle auto-start on login (macOS 11+)
- **Location** - Shows current screenshot save directory
- **Prefix** - Shows detected screenshot filename prefix
- **Quit** - Exit the app (⌘Q)

### Screenshot Settings

Control all macOS screenshot preferences from one menu:

**Toggle Options:**
- **Show Thumbnail Preview** - Enable/disable preview editor after screenshot
- **Include Mouse Pointer** - Show/hide cursor in screenshots
- **Disable Window Shadow** - Remove drop shadow from window captures

**Format Options:**
- **PNG** (default) - Lossless, best quality
- **JPG** - Smaller file size, compressed
- **PDF** - Document format
- **TIFF** - Uncompressed, maximum quality

**Maintenance:**
- **Reset to Defaults** - Restore all settings to macOS defaults

All settings apply system-wide and persist across app restarts. The menu bar may briefly flicker when applying settings (SystemUIServer restart).

### Auto-Start on Login

**Built-in Menu Option (Recommended)**

Simply click **"Launch at Login"** in the menu bar to toggle auto-start on or off. The checkmark shows the current state.

- **macOS 13+**: Uses native SMAppService API
- **macOS 11-12**: Automatically creates LaunchAgent
- Settings persist across system restarts

**Manual Options**

If you prefer to configure auto-start manually:

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

### System Integration

**Change Screenshot Location:**
The app can change your system screenshot save location, affecting all screenshot operations:
- Click "Change Location..." to open folder picker
- Select any folder (creates if needed)
- System preference updates automatically
- Watcher switches to new location immediately

This modifies the same setting as:
```bash
defaults write com.apple.screencapture location "/path/to/folder"
```

**Auto-Detection:**
The app automatically detects your current macOS screenshot settings:
```bash
defaults read com.apple.screencapture location        # Where screenshots save
defaults read com.apple.screencapture name            # Filename prefix
defaults read com.apple.screencapture show-thumbnail  # Preview enabled
defaults read com.apple.screencapture type            # File format (png/jpg/pdf/tiff)
```

### Custom Prefix Support

If you've customized your screenshot name in System Settings, the app preserves it:
- **macOS default:** "Screenshot" → "screenshot"
- **Custom prefix:** "MyScreenshot" → "myscreenshot"

### Duplicate Handling

Handles rapid screenshots with identical timestamps by appending sequence numbers:
- `Screenshot 2024-01-03 at 1.23.45 PM.png` → `screenshot 2024-01-03 at 13.23.45.png`
- Second screenshot with same timestamp → `screenshot 2024-01-03 at 13.23.45 1.png`
- Third screenshot → `screenshot 2024-01-03 at 13.23.45 2.png`

Supports up to 999 duplicates, then falls back to Unix timestamp.

### Screenshot Settings Management

The app provides a unified interface for all macOS screenshot settings that are normally scattered across System Settings and terminal commands:

**Settings Managed:**
- `com.apple.screencapture location` - Save location
- `com.apple.screencapture name` - Filename prefix
- `com.apple.screencapture show-thumbnail` - Preview editor
- `com.apple.screencapture show-cursor` - Mouse pointer
- `com.apple.screencapture disable-shadow` - Window shadow
- `com.apple.screencapture type` - File format (png/jpg/pdf/tiff)

**Benefits:**
- No need to remember terminal commands
- Visual feedback with checkmarks
- Instant notifications on changes
- Settings persist across system restarts
- One-click reset to defaults

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

All 55 unit tests cover:
- Pattern matching (13 tests)
- File validation (12 tests)
- Screenshot detection (10 tests)
- Launch at login (10 tests)
- Shell command execution (5 tests)
- Screenshot renaming with duplicates (5 tests)

### Project Structure

```
.
├── Sources/
│   └── ScreenshotRenamer/
│       ├── App/
│       │   ├── AppDelegate.swift         # App lifecycle
│       │   ├── MenuBarController.swift   # Menu bar UI and settings
│       │   └── main.swift                # Entry point
│       ├── Core/
│       │   ├── ScreenshotDetector.swift  # Settings detection and modification
│       │   ├── ScreenshotRenamer.swift   # Rename logic with duplicate handling
│       │   ├── PatternMatcher.swift      # Regex matching
│       │   └── FileValidator.swift       # Security validation
│       ├── FileWatcher/
│       │   └── ScreenshotWatcher.swift   # FSEvents file monitoring
│       ├── Models/
│       │   ├── ScreenshotSettings.swift      # Location and prefix
│       │   ├── ScreenshotPreferences.swift   # Advanced settings (format, thumbnail, etc)
│       │   ├── RenameResult.swift            # Rename operation results
│       │   ├── ScreenshotMatch.swift         # Pattern match data
│       │   └── ScreenshotError.swift         # Error types
│       ├── Utilities/
│       │   └── ShellExecutor.swift       # Shell command execution
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

### Current: GitHub Releases

All releases are available as downloadable ZIP and DMG files from [GitHub Releases](https://github.com/tpak/renamescreenshots/releases).

**Automated Release Process:**
- Every push to `main` creates a "latest" pre-release build
- Git tags (e.g., `v1.0.0`) create official versioned releases
- All releases include ZIP, DMG, and SHA256 checksums
- Direct download links never expire

### Future: Code Signing & Notarization

Full code signing and Apple notarization will be added in a future release to eliminate Gatekeeper warnings. This requires an Apple Developer account ($99/year).

### Future: Homebrew

Homebrew cask distribution is planned once code signing and notarization are implemented.

### Code Signing (Current: Ad-hoc)

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
- **Frameworks:** AppKit, CoreServices (FSEvents), Foundation, ServiceManagement, UserNotifications
- **Build System:** Swift Package Manager
- **Binary Size:** 264KB (release build)
- **Memory Usage:** ~20MB at runtime
- **Startup Time:** Instant (<100ms)
- **Tests:** 55 unit tests covering all core functionality
- **macOS APIs:** NSStatusBar, NSMenu, FSEvents, defaults system

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
| **Size** | ~100MB | 264KB |
| **Dependencies** | pip, rumps, Flask | None |
| **Performance** | Good | Excellent |
| **Distribution** | pip install | .app / .dmg |
| **Integration** | Good | Native |
| **Settings UI** | Terminal commands | Native menu |

The Swift version provides a superior user experience with native macOS integration and comprehensive settings control.
