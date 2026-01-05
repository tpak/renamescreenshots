# Changelog

All notable changes to Screenshot Renamer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-01-05

### Added
- Native macOS menu bar app for automatic screenshot renaming
- Converts 12-hour format to 24-hour format for chronological sorting
- FSEvents-based file watching for real-time monitoring
- Quick rename feature for batch processing existing screenshots
- System screenshot location changer with folder picker
- Comprehensive screenshot settings control:
  - Show/hide thumbnail preview toggle
  - Include/exclude mouse pointer toggle
  - Enable/disable window shadow toggle
  - Screenshot format selector (PNG, JPG, PDF, TIFF)
  - Reset to defaults option
- Duplicate filename handling with sequence numbers
- Menu bar integration with SF Symbol camera icon
- UserNotifications framework for status updates
- Auto-detect screenshot location and prefix from system
- Whitelist security for directory access
- 45 comprehensive unit tests covering all functionality
- Build automation with version injection
- Ad-hoc code signing for local builds
- Support for macOS 11.0 (Big Sur) and later

### Security
- Path validation to prevent directory traversal
- Filename sanitization to block unsafe characters
- Whitelist support for directory restrictions
- Sandbox-ready architecture

[Unreleased]: https://github.com/tpak/renamescreenshots/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/tpak/renamescreenshots/releases/tag/v1.0.0
