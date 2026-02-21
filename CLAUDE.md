# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands
- **Build:** `swift build`
- **Test all:** `swift test` (75+ tests, ~5 seconds)
- **Test single:** `swift test --filter ScreenshotRenamerTests.PatternMatcherTests/testDefaultPattern`
- **Build app bundle:** `./Scripts/build-app.sh`
- **Lint:** SwiftLint runs automatically via pre-commit hook; manually: `swiftlint lint --strict`

## Versioning Workflow
When making any code change (feature, fix, refactor):
1. Create a feature branch from main
2. Make code changes and add/update tests
3. Bump version: `./Scripts/bump-version.sh [major|minor|patch]`
   - `fix:` commits → patch
   - `feat:` commits → minor
   - Breaking changes → major
4. Update CHANGELOG.md with a new version section (Keep a Changelog format)
5. Commit, push, and create PR
6. After merge, GitHub Actions auto-creates the git tag and release

## Commit Convention
Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`

## Architecture

Native macOS menu bar app (no dock icon) that renames screenshots from 12-hour to 24-hour format. No external dependencies — pure Swift + macOS frameworks.

**Component flow:**
```
main.swift → AppDelegate → MenuBarController (orchestrator)
                              ├─ ScreenshotWatcher (FSEvents, debounced 300ms)
                              │   └─ ScreenshotRenamer → PatternMatcher + FileValidator
                              ├─ ScreenshotDetector (reads/writes com.apple.screencapture defaults)
                              │   └─ ShellExecutor (defaults read/write, killall SystemUIServer)
                              └─ SettingsWindowController (unified settings dialog)
```

- **PatternMatcher** — regex extracts date, time, AM/PM (optional), sequence number from screenshot filenames; `ScreenshotMatch.to24Hour()` converts 12h→24h
- **FileValidator** — whitelist-based directory security, path traversal prevention; uses `.standardizedFileURL` for URL comparisons (avoids trailing slash mismatches)
- **ScreenshotWatcher** — FSEvents with debounced `DispatchWorkItem` on a serial queue; coalesces rapid events into a single rename scan
- **DebugLogger** — singleton (`DebugLogger.shared`), writes to `~/Library/Logs/ScreenshotRenamer/screenshotrenamer-debug.log`

## Key Constraints

- **SwiftLint function body limit: 60 lines** — split long test functions rather than removing assertions
- **`testRestartSystemUIServer` is flaky** — use lenient assertions (just check it doesn't crash)
- **URL comparisons** — always use `.standardizedFileURL` to avoid trailing slash mismatches
- **Custom SwiftLint rule `no_nslog`** — use `os_log()` instead of `NSLog()`
- **VERSION file** is the single source of truth for version; `Info.plist` version is injected at build time by `Scripts/inject-version.sh`

## CI/CD

- `auto-tag.yml`: watches VERSION file on main → creates v* tag → dispatches release workflow
- `release-tag.yml`: builds app, creates GitHub Release with ZIP/DMG (triggered by v* tags or workflow_dispatch)
- `release-main.yml`: creates `latest` pre-release on every push to main
- **GITHUB_TOKEN limitation**: tags created by Actions don't trigger other workflows; solved with `workflow_dispatch`
