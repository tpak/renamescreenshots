//
//  ScreenshotDetectorTests.swift
//  ScreenshotRenamerTests
//
//  Unit tests for screenshot settings detection
//

// swiftlint:disable force_try
import XCTest
@testable import ScreenshotRenamer

class ScreenshotDetectorTests: XCTestCase {
    func testDetectSettings() {
        let detector = ScreenshotDetector()
        let settings = detector.detectSettings()

        // Verify we got settings
        XCTAssertNotNil(settings.location, "Location should not be nil")
        XCTAssertNotNil(settings.prefix, "Prefix should not be nil")
        XCTAssertFalse(settings.prefix.isEmpty, "Prefix should not be empty")

        // Location should be a valid directory
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: settings.location.path,
            isDirectory: &isDirectory
        )

        XCTAssertTrue(exists, "Location should exist")
        XCTAssertTrue(isDirectory.boolValue, "Location should be a directory")
    }

    func testSetSystemLocation() {
        let detector = ScreenshotDetector()

        // Create a temporary directory for testing
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("screenshot-test-\(UUID().uuidString)")

        try! FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )

        // Store original location to restore later
        let originalLocation = detector.detectSettings().location

        // Set new system location
        let success = detector.setSystemLocation(tempDir)
        XCTAssertTrue(success, "Setting system location should succeed")

        // Verify it was set by reading it back
        let newSettings = detector.detectSettings()
        XCTAssertEqual(
            newSettings.location.path,
            tempDir.path,
            "Location should be updated to new path"
        )

        // Restore original location
        _ = detector.setSystemLocation(originalLocation)

        // Cleanup
        try? FileManager.default.removeItem(at: tempDir)
    }

    func testSetSystemLocationInvalidPath() {
        let detector = ScreenshotDetector()

        // Store original location to restore later
        let originalLocation = detector.detectSettings().location
        defer {
            _ = detector.setSystemLocation(originalLocation)
        }

        // Try to set a non-existent path
        let invalidPath = URL(fileURLWithPath: "/nonexistent/path/\(UUID().uuidString)")

        // This should still succeed (defaults write doesn't validate the path)
        // The validation happens when detecting/watching
        let success = detector.setSystemLocation(invalidPath)
        XCTAssertTrue(success, "Writing to defaults should succeed even with invalid path")

        // But when we detect settings, it should fall back to a valid location
        let settings = detector.detectSettings()

        // Should not be the invalid path (should fall back to default)
        XCTAssertNotEqual(
            settings.location.path,
            invalidPath.path,
            "Should fall back to valid location"
        )
    }

    // MARK: - Advanced Preferences Tests

    func testDetectPreferences() {
        let detector = ScreenshotDetector()
        let prefs = detector.detectPreferences()

        // Verify we got preferences
        XCTAssertNotNil(prefs, "Preferences should not be nil")

        // Format should be one of the valid values
        let validFormats: [ScreenshotFormat] = [.png, .jpg, .pdf, .tiff]
        XCTAssertTrue(
            validFormats.contains(prefs.format),
            "Format should be one of: png, jpg, pdf, tiff"
        )
    }

    func testSetShowThumbnail() {
        let detector = ScreenshotDetector()

        // Store original value
        let originalPrefs = detector.detectPreferences()

        // Toggle to opposite value
        let newValue = !originalPrefs.showThumbnail
        let success = detector.setShowThumbnail(newValue)
        XCTAssertTrue(success, "Setting show thumbnail should succeed")

        // Read back and verify
        let updatedPrefs = detector.detectPreferences()
        XCTAssertEqual(
            updatedPrefs.showThumbnail,
            newValue,
            "Show thumbnail should be updated"
        )

        // Restore original value
        _ = detector.setShowThumbnail(originalPrefs.showThumbnail)
    }

    func testSetIncludeCursor() {
        let detector = ScreenshotDetector()

        // Store original value
        let originalPrefs = detector.detectPreferences()

        // Toggle to opposite value
        let newValue = !originalPrefs.includeCursor
        let success = detector.setIncludeCursor(newValue)
        XCTAssertTrue(success, "Setting include cursor should succeed")

        // Read back and verify
        let updatedPrefs = detector.detectPreferences()
        XCTAssertEqual(
            updatedPrefs.includeCursor,
            newValue,
            "Include cursor should be updated"
        )

        // Restore original value
        _ = detector.setIncludeCursor(originalPrefs.includeCursor)
    }

    func testSetDisableShadow() {
        let detector = ScreenshotDetector()

        // Store original value
        let originalPrefs = detector.detectPreferences()

        // Toggle to opposite value
        let newValue = !originalPrefs.disableShadow
        let success = detector.setDisableShadow(newValue)
        XCTAssertTrue(success, "Setting disable shadow should succeed")

        // Read back and verify
        let updatedPrefs = detector.detectPreferences()
        XCTAssertEqual(
            updatedPrefs.disableShadow,
            newValue,
            "Disable shadow should be updated"
        )

        // Restore original value
        _ = detector.setDisableShadow(originalPrefs.disableShadow)
    }

    func testSetFormat() {
        let detector = ScreenshotDetector()

        // Store original format
        let originalPrefs = detector.detectPreferences()

        // Try each format
        let testFormats: [ScreenshotFormat] = [.jpg, .pdf, .tiff, .png]

        for format in testFormats {
            let success = detector.setFormat(format)
            XCTAssertTrue(success, "Setting format to \(format.rawValue) should succeed")

            // Read back and verify
            let updatedPrefs = detector.detectPreferences()
            XCTAssertEqual(
                updatedPrefs.format,
                format,
                "Format should be updated to \(format.rawValue)"
            )
        }

        // Restore original format
        _ = detector.setFormat(originalPrefs.format)
    }

    func testSetIncludeDate() {
        let detector = ScreenshotDetector()

        // Store original value
        let originalPrefs = detector.detectPreferences()

        // Toggle to opposite value
        let newValue = !originalPrefs.includeDate
        let success = detector.setIncludeDate(newValue)
        XCTAssertTrue(success, "Setting include date should succeed")

        // Read back and verify
        let updatedPrefs = detector.detectPreferences()
        XCTAssertEqual(
            updatedPrefs.includeDate,
            newValue,
            "Include date should be updated"
        )

        // Restore original value
        _ = detector.setIncludeDate(originalPrefs.includeDate)
    }

    func testSetCaptureDelay() {
        let detector = ScreenshotDetector()

        // Store original value
        let originalPrefs = detector.detectPreferences()

        // Try each valid delay value
        let testDelays = [5, 10, 0]

        for delay in testDelays {
            let success = detector.setCaptureDelay(delay)
            XCTAssertTrue(success, "Setting capture delay to \(delay) should succeed")

            // Read back and verify
            let updatedPrefs = detector.detectPreferences()
            XCTAssertEqual(
                updatedPrefs.captureDelay,
                delay,
                "Capture delay should be updated to \(delay)"
            )
        }

        // Restore original value
        _ = detector.setCaptureDelay(originalPrefs.captureDelay)
    }

    func testSetPrefix() {
        let detector = ScreenshotDetector()

        // Store original prefix
        let originalSettings = detector.detectSettings()

        // Set a custom prefix
        let success = detector.setPrefix("TestPrefix")
        XCTAssertTrue(success, "Setting prefix should succeed")

        // Read back and verify
        let updatedSettings = detector.detectSettings()
        XCTAssertEqual(
            updatedSettings.prefix,
            "TestPrefix",
            "Prefix should be updated to TestPrefix"
        )

        // Restore original prefix
        _ = detector.setPrefix(originalSettings.prefix)
    }

    func testResetToDefaultsResetsLocationAndPrefix() {
        let detector = ScreenshotDetector()
        let originalSettings = detector.detectSettings()
        let originalPrefs = detector.detectPreferences()
        let defaultLocation = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")

        // Create temp dir and change location/prefix
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("reset-test-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        _ = detector.setSystemLocation(tempDir)
        _ = detector.setPrefix("TestPrefix")

        // Verify changes applied
        let changed = detector.detectSettings()
        XCTAssertEqual(changed.location.standardizedFileURL, tempDir.standardizedFileURL)
        XCTAssertEqual(changed.prefix, "TestPrefix")

        // Reset and verify location/prefix
        XCTAssertTrue(detector.resetToDefaults(), "Reset should succeed")
        let reset = detector.detectSettings()
        XCTAssertEqual(reset.location.standardizedFileURL, defaultLocation.standardizedFileURL, "Location → Desktop")
        XCTAssertEqual(reset.prefix, "Screenshot", "Prefix → Screenshot")

        // Restore all originals (resetToDefaults resets everything)
        _ = detector.setSystemLocation(originalSettings.location)
        _ = detector.setPrefix(originalSettings.prefix)
        _ = detector.setShowThumbnail(originalPrefs.showThumbnail)
        _ = detector.setIncludeCursor(originalPrefs.includeCursor)
        _ = detector.setDisableShadow(originalPrefs.disableShadow)
        _ = detector.setFormat(originalPrefs.format)
        _ = detector.setIncludeDate(originalPrefs.includeDate)
        _ = detector.setCaptureDelay(originalPrefs.captureDelay)
    }

    func testResetToDefaultsResetsPreferences() {
        let detector = ScreenshotDetector()
        let originalPrefs = detector.detectPreferences()

        // Change all preferences to non-default values
        _ = detector.setShowThumbnail(false)
        _ = detector.setIncludeCursor(true)
        _ = detector.setDisableShadow(true)
        _ = detector.setFormat(.jpg)
        _ = detector.setIncludeDate(false)
        _ = detector.setCaptureDelay(10)

        // Verify changes applied
        let changed = detector.detectPreferences()
        XCTAssertFalse(changed.showThumbnail)
        XCTAssertTrue(changed.includeCursor)
        XCTAssertTrue(changed.disableShadow)
        XCTAssertEqual(changed.format, .jpg)
        XCTAssertFalse(changed.includeDate)
        XCTAssertEqual(changed.captureDelay, 10)

        // Reset and verify preferences
        XCTAssertTrue(detector.resetToDefaults(), "Reset should succeed")
        let reset = detector.detectPreferences()
        let defaults = ScreenshotPreferences.defaults

        XCTAssertEqual(reset.showThumbnail, defaults.showThumbnail, "Show thumbnail → true")
        XCTAssertEqual(reset.includeCursor, defaults.includeCursor, "Include cursor → false")
        XCTAssertEqual(reset.disableShadow, defaults.disableShadow, "Disable shadow → false")
        XCTAssertEqual(reset.format, defaults.format, "Format → png")
        XCTAssertEqual(reset.includeDate, defaults.includeDate, "Include date → true")
        XCTAssertEqual(reset.captureDelay, defaults.captureDelay, "Capture delay → 0")

        // Restore original
        _ = detector.setShowThumbnail(originalPrefs.showThumbnail)
        _ = detector.setIncludeCursor(originalPrefs.includeCursor)
        _ = detector.setDisableShadow(originalPrefs.disableShadow)
        _ = detector.setFormat(originalPrefs.format)
        _ = detector.setIncludeDate(originalPrefs.includeDate)
        _ = detector.setCaptureDelay(originalPrefs.captureDelay)
    }

    func testPreferencesPersistence() {
        let detector = ScreenshotDetector()

        // Store original
        let originalPrefs = detector.detectPreferences()

        // Set specific values
        _ = detector.setShowThumbnail(false)
        _ = detector.setIncludeCursor(true)
        _ = detector.setIncludeDate(false)
        _ = detector.setCaptureDelay(5)

        // Create new detector instance (simulates app restart)
        let detector2 = ScreenshotDetector()
        let persistedPrefs = detector2.detectPreferences()

        // Verify values persisted
        XCTAssertFalse(
            persistedPrefs.showThumbnail,
            "Show thumbnail should persist across detector instances"
        )
        XCTAssertTrue(
            persistedPrefs.includeCursor,
            "Include cursor should persist across detector instances"
        )
        XCTAssertFalse(
            persistedPrefs.includeDate,
            "Include date should persist across detector instances"
        )
        XCTAssertEqual(
            persistedPrefs.captureDelay,
            5,
            "Capture delay should persist across detector instances"
        )

        // Restore original
        _ = detector.setShowThumbnail(originalPrefs.showThumbnail)
        _ = detector.setIncludeCursor(originalPrefs.includeCursor)
        _ = detector.setIncludeDate(originalPrefs.includeDate)
        _ = detector.setCaptureDelay(originalPrefs.captureDelay)
    }

    func testSettingsSnapshotSaveAndRestore() {
        let detector = ScreenshotDetector()
        let originalSettings = detector.detectSettings()
        let snapshotKey = "knownGoodSettings"

        // Save current settings via SettingsSnapshot
        SettingsSnapshot.save()
        defer { UserDefaults.standard.removeObject(forKey: snapshotKey) }

        // Verify snapshot was written with all expected keys
        guard let snapshot = UserDefaults.standard.dictionary(forKey: snapshotKey) else {
            XCTFail("SettingsSnapshot.save() should write to UserDefaults")
            return
        }

        XCTAssertEqual(snapshot["location"] as? String, originalSettings.location.path)
        XCTAssertEqual(snapshot["prefix"] as? String, originalSettings.prefix)
        XCTAssertNotNil(snapshot["format"] as? String)
        XCTAssertNotNil(snapshot["showThumbnail"] as? Bool)
        XCTAssertNotNil(snapshot["includeCursor"] as? Bool)
        XCTAssertNotNil(snapshot["disableShadow"] as? Bool)
        XCTAssertNotNil(snapshot["includeDate"] as? Bool)
        XCTAssertNotNil(snapshot["captureDelay"] as? Int)
    }
}
