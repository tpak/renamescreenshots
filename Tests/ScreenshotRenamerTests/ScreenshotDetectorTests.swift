//
//  ScreenshotDetectorTests.swift
//  ScreenshotRenamerTests
//
//  Unit tests for screenshot settings detection
//

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
}
