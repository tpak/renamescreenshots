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

    func testResetToDefaults() {
        let detector = ScreenshotDetector()

        // Store original preferences
        let originalPrefs = detector.detectPreferences()

        // Change all settings to non-default values
        _ = detector.setShowThumbnail(false)
        _ = detector.setIncludeCursor(true)
        _ = detector.setDisableShadow(true)
        _ = detector.setFormat(.jpg)
        _ = detector.setIncludeDate(false)

        // Verify they were changed
        let changedPrefs = detector.detectPreferences()
        XCTAssertFalse(changedPrefs.showThumbnail)
        XCTAssertTrue(changedPrefs.includeCursor)
        XCTAssertTrue(changedPrefs.disableShadow)
        XCTAssertEqual(changedPrefs.format, .jpg)
        XCTAssertFalse(changedPrefs.includeDate)

        // Reset to defaults
        let success = detector.resetToDefaults()
        XCTAssertTrue(success, "Reset to defaults should succeed")

        // Verify defaults
        let resetPrefs = detector.detectPreferences()
        let expectedDefaults = ScreenshotPreferences.defaults

        XCTAssertEqual(
            resetPrefs.showThumbnail,
            expectedDefaults.showThumbnail,
            "Show thumbnail should be reset to default (true)"
        )
        XCTAssertEqual(
            resetPrefs.includeCursor,
            expectedDefaults.includeCursor,
            "Include cursor should be reset to default (false)"
        )
        XCTAssertEqual(
            resetPrefs.disableShadow,
            expectedDefaults.disableShadow,
            "Disable shadow should be reset to default (false)"
        )
        XCTAssertEqual(
            resetPrefs.format,
            expectedDefaults.format,
            "Format should be reset to default (png)"
        )
        XCTAssertEqual(
            resetPrefs.includeDate,
            expectedDefaults.includeDate,
            "Include date should be reset to default (true)"
        )

        // Restore original preferences
        _ = detector.setShowThumbnail(originalPrefs.showThumbnail)
        _ = detector.setIncludeCursor(originalPrefs.includeCursor)
        _ = detector.setDisableShadow(originalPrefs.disableShadow)
        _ = detector.setFormat(originalPrefs.format)
        _ = detector.setIncludeDate(originalPrefs.includeDate)
    }

    func testPreferencesPersistence() {
        let detector = ScreenshotDetector()

        // Store original
        let originalPrefs = detector.detectPreferences()

        // Set specific values
        _ = detector.setShowThumbnail(false)
        _ = detector.setIncludeCursor(true)
        _ = detector.setIncludeDate(false)

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

        // Restore original
        _ = detector.setShowThumbnail(originalPrefs.showThumbnail)
        _ = detector.setIncludeCursor(originalPrefs.includeCursor)
        _ = detector.setIncludeDate(originalPrefs.includeDate)
    }
}
