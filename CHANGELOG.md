# Changelog

All notable changes to Screenshot Renamer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.0] - 2026-02-21

### Added
- **Auto-update toggle** in Settings — "Automatically check for updates" checkbox (defaults to on)
- Auto-update status shown in menu bar options summary

### Fixed
- App crash on launch due to missing `@loader_path/../Frameworks` rpath for embedded Sparkle.framework
- Tests now properly restore all user preferences after `testResetToDefaultsResetsLocationAndPrefix` (previously only restored location/prefix, leaving other settings at defaults)

## [1.3.0] - 2026-02-21

### Added
- **Auto-Update via Sparkle** — "Check for Updates..." menu item checks for new versions and installs them in-place
- Automatic background update checks on app launch
- EdDSA-signed updates for secure delivery via GitHub Releases
- Appcast deployment to GitHub Pages for update discovery
- Sparkle 2.x framework embedded in app bundle

## [1.2.0] - 2026-02-21

### Added
- **Capture Delay** setting in Settings dialog — set a timer (None, 5 Seconds, 10 Seconds) before screenshot capture, matching macOS Screenshot utility's Timer option
- Capture delay shown in menu bar options summary when enabled (e.g., "5s Delay")
- `writeIntDefaults()` utility for integer macOS defaults values

## [1.1.2] - 2026-02-11

### Fixed
- **Watcher race condition** — FSEvents could trigger multiple concurrent directory scans, causing "file doesn't exist" errors when two scans tried to rename the same file (#13)
- Replaced per-file `Task {}` with debounced `DispatchWorkItem` that coalesces rapid events into a single rename operation

## [1.1.1] - 2026-02-08

### Fixed
- **Reset to Defaults** now properly resets screenshot location to Desktop and prefix to "Screenshot"

### Changed
- Default debug log renamed from `debug.log` to `screenshotrenamer-debug.log` to distinguish from other logs in `~/Library/Logs/`

## [1.1.0] - 2026-02-07

### Added
- **Unified Settings Dialog** — all preferences now in one window:
  - Editable save location field (type path directly or use folder picker)
  - All screenshot options with checkboxes
  - Launch at login toggle
  - Debug logging section with Set Location, Open, and Clear buttons
  - Reset to Defaults button
- **App Icon** — camera icon now displays in Finder and Applications folder
- **About Dialog Icon** — camera icon shown in About dialog
- **Menu Quick-Reference** — current settings displayed as info items in menu:
  - Location, Prefix, Format
  - Options summary (Thumb, Cursor, Shadow, Date, Auto-start)
  - Debug status
- **Single Instance Prevention** — app detects and prevents duplicate instances
- **Semantic Versioning Scripts**:
  - `./Scripts/bump-version.sh [major|minor|patch]` for manual version control
  - `./Scripts/build-app.sh --bump` flag for auto-increment on build
- **Icon Generation Script** — `Scripts/generate-icon.swift` creates AppIcon.icns from SF Symbol

### Changed
- Settings menu reorganized: separate items replaced with unified "Settings..." dialog
- Debug submenu moved from menu bar into Settings dialog
- Launch at Login moved from menu bar into Settings dialog
- Window title changed from "Screenshot Settings" to "Settings"
- Settings dialog now 550x480px to accommodate all options

### Fixed
- Version not displaying correctly in About dialog (build script now copies Info.plist before restoring original)
- Tests now restore user's screenshot location after running (previously reset to Desktop)

## [1.0.0] - 2026-01-05

### Added
- Native macOS menu bar app for automatic screenshot renaming
- Converts 12-hour format to 24-hour format for chronological sorting
- Support for 24-hour timestamps (lowercases prefix only)
- Support for parenthesized sequence numbers like `(2)`
- FSEvents-based file watching for real-time monitoring
- Quick rename feature for batch processing existing screenshots
- System screenshot location changer with folder picker
- Comprehensive screenshot settings control:
  - Show/hide thumbnail preview toggle
  - Include/exclude mouse pointer toggle
  - Enable/disable window shadow toggle
  - Include date in filename toggle
  - Screenshot format selector (PNG, JPG, PDF, TIFF)
  - Reset to defaults option
- Duplicate filename handling with sequence numbers
- Menu bar integration with SF Symbol camera icon
- UserNotifications framework for status updates
- Auto-detect screenshot location and prefix from system
- Whitelist security for directory access
- Debug logging with configurable file location
- Launch at Login support (SMAppService on macOS 13+, LaunchAgent on older)
- 74 comprehensive unit tests
- Build automation with version injection
- Ad-hoc code signing for local builds
- Support for macOS 11.0 (Big Sur) and later

### Security
- Path validation to prevent directory traversal
- Filename sanitization to block unsafe characters
- Whitelist support for directory restrictions
- Sandbox-ready architecture

[Unreleased]: https://github.com/tpak/renamescreenshots/compare/v1.4.0...HEAD
[1.4.0]: https://github.com/tpak/renamescreenshots/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/tpak/renamescreenshots/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/tpak/renamescreenshots/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/tpak/renamescreenshots/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/tpak/renamescreenshots/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/tpak/renamescreenshots/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/tpak/renamescreenshots/releases/tag/v1.0.0
