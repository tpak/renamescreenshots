# Screenshot Renamer (Swift)

Native macOS menu bar app to automatically rename screenshots from 12-hour to 24-hour format.

**Before:** `Screenshot 2024-05-24 at 1.23.45 PM.png`
**After:** `screenshot 2024-05-24 at 13.23.45.png`

## Why Swift?

This is a native Swift port of the [Python version](../README.md) with several advantages:

- **Native Performance**: Instant startup, no Python runtime
- **Smaller Size**: ~5MB .app bundle vs ~100MB Python distribution
- **Better Integration**: Native macOS APIs (SF Symbols, FSEvents, notifications)
- **Easier Distribution**: Single .app bundle, no pip/Python dependencies
- **Type Safety**: Swift's type system catches errors at compile time

## Requirements

- **macOS 11.0 (Big Sur)** or later
- **Xcode 13+** (for building)

## Building

### Option 1: Xcode GUI

1. Open `ScreenshotRenamer.xcodeproj` in Xcode
2. Select "ScreenshotRenamer" scheme
3. Build: `⌘B` or Product → Build
4. Run: `⌘R` or Product → Run

### Option 2: Command Line

```bash
# Build for release
xcodebuild -project ScreenshotRenamer.xcodeproj \
    -scheme ScreenshotRenamer \
    -configuration Release \
    build

# Run the built app
open build/Release/ScreenshotRenamer.app
```

## Installation

### From .app Bundle

1. Build the app (see above)
2. Copy to Applications:
   ```bash
   cp -r build/Release/ScreenshotRenamer.app /Applications/
   ```
3. Launch from Applications or Spotlight

### Auto-Start on Login

**Option 1: System Preferences**
1. Open System Preferences → Users & Groups → Login Items
2. Click `+` and add Screenshot Renamer.app

**Option 2: LaunchAgent (Advanced)**

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

Load it:
```bash
launchctl load ~/Library/LaunchAgents/com.tirpak.screenshot-renamer.plist
```

## Usage

Once running, the camera icon 📷 appears in your menu bar:

**Menu Options:**
- **Stop/Start Watcher** - Toggle automatic renaming (on by default)
- **Quick Rename...** - Manually rename existing screenshots
- **Location** - Shows screenshot save directory
- **Prefix** - Shows detected screenshot prefix
- **Quit** - Exit the app

## Features

- **Auto-Detection**: Reads macOS screenshot settings automatically
  ```bash
  defaults read com.apple.screencapture location  # Where screenshots save
  defaults read com.apple.screencapture name      # Filename prefix
  ```

- **Custom Prefix Support**: Preserves your custom screenshot prefix (e.g., "MyScreenshot" → "myscreenshot")

- **Sequential Screenshots**: Handles rapid screenshots (adds sequence numbers)

- **File Watching**: Uses FSEvents for efficient, native file monitoring

- **Security**:
  - Path validation prevents directory traversal
  - Filename sanitization blocks unsafe characters
  - Whitelist support for directory restrictions

## Project Structure

```
ScreenshotRenamer/
├── ScreenshotRenamer/
│   ├── App/
│   │   ├── AppDelegate.swift         # App lifecycle
│   │   └── MenuBarController.swift   # Menu bar UI
│   ├── Core/
│   │   ├── ScreenshotDetector.swift  # macOS settings detection
│   │   ├── ScreenshotRenamer.swift   # Renaming logic
│   │   ├── PatternMatcher.swift      # Regex matching
│   │   └── FileValidator.swift       # Security validation
│   ├── FileWatcher/
│   │   └── ScreenshotWatcher.swift   # FSEvents watcher
│   ├── Models/
│   │   ├── ScreenshotSettings.swift
│   │   ├── RenameResult.swift
│   │   ├── ScreenshotMatch.swift
│   │   └── ScreenshotError.swift
│   ├── Utilities/
│   │   └── ShellExecutor.swift       # Shell command execution
│   └── Resources/
│       └── Info.plist                # App metadata
└── ScreenshotRenamerTests/
    ├── PatternMatcherTests.swift      # Pattern matching tests
    └── FileValidatorTests.swift       # Validation tests
```

## Running Tests

```bash
# In Xcode: ⌘U or Product → Test

# Command line:
xcodebuild test -project ScreenshotRenamer.xcodeproj -scheme ScreenshotRenamer
```

## Distribution

### Code Signing (Local Use)

```bash
# Ad-hoc signing (no developer account needed)
codesign --force --deep --sign - ScreenshotRenamer.app
```

### Notarization (Public Distribution)

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

# 5. Create DMG for distribution
hdiutil create -volname "Screenshot Renamer" \
    -srcfolder ScreenshotRenamer.app \
    -ov -format UDZO \
    ScreenshotRenamer.dmg
```

## Uninstallation

```bash
# Stop app if running
pkill -9 ScreenshotRenamer

# Remove from Applications
rm -rf /Applications/ScreenshotRenamer.app

# Remove LaunchAgent (if installed)
launchctl unload ~/Library/LaunchAgents/com.tirpak.screenshot-renamer.plist
rm ~/Library/LaunchAgents/com.tirpak.screenshot-renamer.plist
```

## Comparison with Python Version

| Feature | Python (rumps) | Swift (Native) |
|---------|---------------|----------------|
| **Startup Time** | ~1-2 seconds | Instant |
| **Bundle Size** | ~50-100 MB | ~5 MB |
| **Dependencies** | Python, pip, rumps | None |
| **macOS Integration** | Good | Excellent |
| **Distribution** | pip install | .app / .dmg |
| **Auto-updates** | Manual | Sparkle (optional) |
| **Code Signing** | Via py2app | Native |

## Troubleshooting

**Menu bar icon doesn't appear:**
- Check Console.app for errors
- Ensure macOS 11.0+ for SF Symbols

**Watcher not renaming:**
- Check System Preferences → Security & Privacy → Privacy → Full Disk Access
- Add ScreenshotRenamer.app if screenshot directory is outside ~/Desktop

**Permission errors:**
- Grant Full Disk Access in System Preferences
- Check screenshot directory is readable/writable

## Contributing

This is a faithful Swift port of the Python version. When adding features:
- Maintain feature parity with Python version
- Add corresponding unit tests
- Update both READMEs
- Follow Swift API design guidelines

## License

MIT License - see [LICENSE](../LICENSE) file for details.

Created by [Chris Tirpak](https://github.com/tpak)

## Acknowledgments

- Swift port of the [Python Screenshot Renamer](../README.md)
- Uses native macOS APIs: FSEvents, NSStatusBar, NSFileManager
