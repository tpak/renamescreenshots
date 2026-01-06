# Screenshot Renamer - Future Improvements

This document tracks non-critical issues and enhancements identified during code review.
All CRITICAL and HIGH severity issues have been resolved. These items are for future releases.

---

## MEDIUM Priority Issues

### 1. Forced Unwrapping in FSEvents Callback
**File:** `ScreenshotWatcher.swift:65`
**Issue:** Uses forced cast `as!` which could crash if FSEvents API changes

```swift
// Current (risky):
let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]

// Safer approach:
guard let pathsArray = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else {
    os_log("Invalid paths format in FSEvents callback", log: .default, type: .error)
    return
}
```

**Priority:** MEDIUM
**Effort:** 15 minutes
**Risk:** Low (API unlikely to change)

---

### 2. Main Thread Blocking in changeLocation
**File:** `MenuBarController.swift:376-390`
**Issue:** UI becomes unresponsive during settings reload with large directories

```swift
// Current: Synchronous operations block UI
loadSettings()  // Blocks if directory has many files
try startWatcher()  // Blocks during initialization

// Better: Defer to async context
Task.detached(priority: .userInitiated) { [weak self] in
    await self?.performLocationChange(selectedURL)
}
```

**Priority:** MEDIUM
**Effort:** 1-2 hours (needs async refactoring)
**Risk:** Medium (changes control flow)

---

### 3. FSEvents Stream Creation Timeout
**File:** `ScreenshotWatcher.swift:57-73`
**Issue:** No timeout if directory is inaccessible, app could hang on startup

```swift
// Add timeout wrapper:
let semaphore = DispatchSemaphore(value: 0)
DispatchQueue.global().async {
    self.streamRef = FSEventStreamCreate(...)
    semaphore.signal()
}

let result = semaphore.wait(timeout: .now() + 5.0)
if result == .timedOut {
    throw ScreenshotError.watcherTimeout
}
```

**Priority:** MEDIUM
**Effort:** 30 minutes
**Risk:** Low

---

### 4. Regex Initialization Uses fatalError
**File:** `PatternMatcher.swift:56-57`
**Issue:** Crashes entire app if regex compilation fails (unlikely but poor defensive programming)

```swift
// Current:
fatalError("Invalid regex pattern: \(error)")

// Better:
os_log("Failed to compile regex pattern: %{public}@",
       log: .default, type: .error, error.localizedDescription)
return try NSRegularExpression(pattern: "(?!.*)", options: [])  // Matches nothing
```

**Priority:** MEDIUM
**Effort:** 10 minutes
**Risk:** Very low

---

### 5. File Disappeared Race Condition
**File:** `ScreenshotRenamer.swift:31-42`
**Issue:** Files may be deleted between directory read and rename operation

```swift
// Add existence check before rename:
for fileURL in contents {
    totalFiles += 1

    guard fileManager.fileExists(atPath: fileURL.path) else {
        os_log("File disappeared: %{public}@",
               log: .default, type: .debug, fileURL.lastPathComponent)
        continue
    }
    // ... rest of processing
}
```

**Priority:** MEDIUM
**Effort:** 15 minutes
**Risk:** Low

---

### 6. Bundle Path Fallback Returns Invalid Plist
**File:** `LaunchAtLoginManager.swift:176-177`
**Issue:** Returns empty string if Bundle.main fails, creating invalid plist

```swift
// Current:
guard let bundlePath = Bundle.main.bundlePath as String? else {
    return ""  // Invalid plist!
}

// Better:
let bundlePath = Bundle.main.bundlePath
let executablePath = "\(bundlePath)/Contents/MacOS/ScreenshotRenamer"

guard FileManager.default.fileExists(atPath: executablePath) else {
    throw LaunchAtLoginError.legacyEnableFailed(
        NSError(domain: "Bundle", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Executable not found"])
    )
}
```

**Priority:** MEDIUM
**Effort:** 15 minutes
**Risk:** Very low (bundle path almost never fails)

---

### 7. Screenshot Prefix Length Not Validated
**File:** `ScreenshotDetector.swift:212-219`
**Issue:** Malicious user could set extremely long prefix causing filesystem errors

```swift
private func detectPrefix() -> String {
    guard let output = ShellExecutor.readDefaults(
        domain: "com.apple.screencapture",
        key: "name"
    ), !output.isEmpty else {
        return "Screenshot"
    }

    // Validate prefix
    let maxLength = 100  // Reasonable limit
    let truncated = String(output.prefix(maxLength))

    // Ensure no problematic characters
    guard !truncated.contains("/") && !truncated.contains("\0") else {
        return "Screenshot"
    }

    return truncated
}
```

**Priority:** MEDIUM
**Effort:** 20 minutes
**Risk:** Low

---

## LOW Priority Issues

### 8. Non-Unique Notification IDs
**File:** `MenuBarController.swift:649-653`
**Issue:** Each notification uses random UUID, accumulating in Notification Center

```swift
// Current:
identifier: UUID().uuidString  // Always unique

// Better:
identifier: "ScreenshotRenamer"  // Replaces previous notification
```

**Priority:** LOW
**Effort:** 5 minutes
**Risk:** None

---

### 9. Debug Print Statements in Production
**Files:** `AppDelegate.swift`, `MenuBarController.swift`, etc.
**Issue:** Print statements with emojis clutter console output

```swift
// Remove these:
print("🚀 Screenshot Renamer starting...")
print("✅ Menu bar controller created")

// Already have os_log throughout, these are redundant
```

**Priority:** LOW
**Effort:** 10 minutes
**Risk:** None

---

### 10. Magic Numbers Without Constants
**File:** `ScreenshotWatcher.swift:71, 130`
**Issue:** Hardcoded delays make tuning difficult

```swift
// Define constants:
private static let fsEventLatency: TimeInterval = 0.1  // macOS creates .Screenshot then renames
private static let fileWriteDelay: UInt64 = 150_000_000  // nanoseconds

// Use constants:
try? await Task.sleep(nanoseconds: Self.fileWriteDelay)
```

**Priority:** LOW
**Effort:** 10 minutes
**Risk:** None

---

### 11. Silent Fallback for Preferences
**File:** `ScreenshotDetector.swift:138-176`
**Issue:** Preference detection falls back to defaults without logging why

```swift
guard let output = ShellExecutor.readDefaults(...) else {
    os_log("Failed to read show-thumbnail preference, using default (true)",
           log: .default, type: .debug)
    return true
}
```

**Priority:** LOW
**Effort:** 20 minutes (add to all preference methods)
**Risk:** None

---

### 12. Incomplete Error Logging
**File:** `ScreenshotRenamer.swift:84-88`
**Issue:** File rename errors don't log attempted new filename for debugging

```swift
} catch {
    let newFilename = match.buildNewFilename(prefix: settings.prefix)
    os_log("Error renaming %{public}@ to %{public}@: %{public}@",
           log: .default, type: .error, filename, newFilename,
           error.localizedDescription)
    errors.append("\(filename): \(error.localizedDescription)")
}
```

**Priority:** LOW
**Effort:** 10 minutes
**Risk:** None

---

### 13. Missing Explicit Deinit
**File:** `MenuBarController.swift`
**Issue:** Cleanup is implicit, could be more explicit for defensive programming

```swift
deinit {
    stopWatcher()  // Ensure watcher is cleaned up
    os_log("MenuBarController deallocated", log: .default, type: .debug)
}
```

**Priority:** LOW
**Effort:** 5 minutes
**Risk:** None

---

## Architecture Improvements (Future Releases)

### Refactor to Dependency Injection
**Current:** MenuBarController directly creates all dependencies
**Better:** Inject dependencies through initializer

```swift
class MenuBarController {
    init(
        detector: ScreenshotDetectorProtocol = ScreenshotDetector(),
        watcherFactory: ScreenshotWatcherFactory = DefaultWatcherFactory(),
        launchManager: LaunchAtLoginManagerProtocol = LaunchAtLoginManager.shared
    ) {
        self.detector = detector
        // ...
    }
}
```

**Benefits:**
- Better testability
- Easier to mock for unit tests
- More flexible architecture

**Effort:** 4-8 hours
**Risk:** Medium (significant refactoring)

---

### Protocol-Based Design
**Current:** Concrete types used throughout
**Better:** Define protocols for all major components

```swift
protocol ScreenshotDetectorProtocol {
    func detectSettings() -> ScreenshotSettings
    func detectPreferences() -> ScreenshotPreferences
    func setSystemLocation(_ location: URL) -> Bool
}

protocol ScreenshotWatcherProtocol {
    func startWatching()
    func stopWatching()
}
```

**Benefits:**
- Mockable for testing
- Easier to swap implementations
- Better API contracts

**Effort:** 2-4 hours
**Risk:** Low (mostly additive)

---

### Comprehensive Unit Testing
**Current:** 55 tests covering core logic
**Missing:**
- MenuBarController tests (UI interactions)
- Integration tests (full workflow)
- Edge case coverage

**Effort:** 8-16 hours for complete coverage
**Risk:** None

---

### Consistent Async/Await Patterns
**Current:** Mix of callbacks, Task wrappers, and async/await
**Better:** Use async/await consistently throughout

**Benefits:**
- More readable code
- Better error propagation
- Easier to reason about concurrency

**Effort:** 4-6 hours
**Risk:** Medium (changes control flow)

---

### SwiftUI Migration (Future Major Release)
**Current:** AppKit with NSMenu, NSAlert, etc.
**Future:** Consider SwiftUI for macOS 13+ for better maintainability

**Benefits:**
- Modern declarative UI
- Better state management
- Automatic view updates

**Effort:** 16-24 hours
**Risk:** High (complete UI rewrite)

---

## Testing Recommendations

### Unit Tests to Add
1. MenuBarController toggle methods
2. ScreenshotWatcher state transitions
3. LaunchAtLoginManager edge cases
4. Error recovery scenarios
5. Concurrent screenshot processing

### Integration Tests
1. End-to-end screenshot rename workflow
2. Settings changes while processing
3. Watcher restart scenarios
4. Launch at login installation

### Performance Tests
1. Large directory handling (1000+ screenshots)
2. Rapid screenshot creation
3. Memory usage over time
4. File descriptor usage

---

## Documentation Improvements

### Code Documentation
- Add DocC documentation comments to public APIs
- Document thread safety guarantees
- Add usage examples for complex APIs

### User Documentation
- Add troubleshooting section to README
- Document common error messages
- Create FAQ for common issues

### Developer Documentation
- Architecture decision records (ADRs)
- Contribution guidelines expansion
- Development environment setup

---

## Monitoring & Observability (Future)

### Logging
- Structured logging with OSLog categories
- Log levels for different components
- Performance metrics logging

### Error Reporting (Optional)
- Consider telemetry for crash reporting
- Privacy-preserving usage analytics
- Opt-in error reporting

---

## Security Enhancements (Future)

### Code Signing
- Implement proper code signing with Developer ID
- Apple notarization for Gatekeeper
- Hardened runtime entitlements

### Sandboxing
- Evaluate App Sandbox compatibility
- Document required entitlements
- Test with sandbox enabled

### Privacy
- Privacy manifest (macOS 14+)
- Document file access requirements
- Minimize permissions requested

---

## Performance Optimizations

### Identified Opportunities
1. Batch process multiple screenshots
2. Use lazy evaluation for directory contents
3. Cache screenshot format detection
4. Debounce rapid FSEvents

### Profiling Needed
1. Instruments time profiler for hotspots
2. Memory allocations analysis
3. File I/O optimization
4. Main thread blocking analysis

---

## Release Checklist

Before each release:
- [ ] All CRITICAL and HIGH issues resolved
- [ ] All tests passing (55+)
- [ ] Manual testing on macOS 11, 12, 13, 14
- [ ] README updated with new features
- [ ] CHANGELOG.md updated
- [ ] Version bumped in VERSION file
- [ ] Code signing verified
- [ ] GitHub Actions CI passing
- [ ] Manual smoke test of .app bundle
- [ ] Test installation from DMG

---

## Version Planning

### v1.1.0 (Next Minor Release)
- Fix MEDIUM priority issues (#1-7)
- Add structured logging
- Improve error messages
- Performance profiling

### v1.2.0 (Future)
- Protocol-based architecture
- Comprehensive test coverage
- Async/await migration
- Code signing & notarization

### v2.0.0 (Major - Future)
- Dependency injection refactor
- SwiftUI migration (macOS 13+)
- Sandboxing support
- Advanced preferences UI

---

**Last Updated:** 2026-01-06
**Next Review:** After v1.1.0 release

For questions or to prioritize any of these items, create a GitHub issue.
