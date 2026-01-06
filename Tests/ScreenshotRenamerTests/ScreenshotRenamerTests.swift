//
//  ScreenshotRenamerTests.swift
//  ScreenshotRenamerTests
//
//  Unit tests for screenshot renaming with duplicate handling
//

// swiftlint:disable force_try
import XCTest
@testable import ScreenshotRenamer

class ScreenshotRenamerTests: XCTestCase {
    var testDir: URL!

    override func setUp() {
        super.setUp()
        // Create temp directory for tests
        testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("screenshot-renamer-test-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        // Clean up test directory
        try? FileManager.default.removeItem(at: testDir)
        super.tearDown()
    }

    func testRenamesSingleScreenshot() throws {
        // Create test screenshot
        let testFile = testDir.appendingPathComponent("Screenshot 2026-01-05 at 1.23.45 PM.png")
        try "test".write(to: testFile, atomically: true, encoding: .utf8)

        // Run renamer
        let settings = ScreenshotSettings(location: testDir, prefix: "Screenshot")
        let renamer = ScreenshotRenamer(settings: settings, whitelist: [testDir])
        let result = try renamer.renameScreenshots()

        // Verify results
        XCTAssertEqual(result.renamedFiles, 1, "Should rename 1 file")
        XCTAssertEqual(result.errors.count, 0, "Should have no errors")

        // Verify renamed file exists
        let expectedFile = testDir.appendingPathComponent("screenshot 2026-01-05 at 13.23.45.png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedFile.path), "Renamed file should exist")
        XCTAssertFalse(FileManager.default.fileExists(atPath: testFile.path), "Original file should not exist")
    }

    func testHandlesDuplicateFilenames() throws {
        // Create first screenshot and rename it
        let testFile1 = testDir.appendingPathComponent("Screenshot 2026-01-05 at 1.23.45 PM.png")
        try "test1".write(to: testFile1, atomically: true, encoding: .utf8)

        let settings = ScreenshotSettings(location: testDir, prefix: "Screenshot")
        let renamer = ScreenshotRenamer(settings: settings, whitelist: [testDir])

        // Rename first file
        let result1 = try renamer.renameScreenshots()
        XCTAssertEqual(result1.renamedFiles, 1, "Should rename first file")

        // Create second screenshot with same timestamp
        let testFile2 = testDir.appendingPathComponent("Screenshot 2026-01-05 at 1.23.45 PM.png")
        try "test2".write(to: testFile2, atomically: true, encoding: .utf8)

        // Rename second file - should append " 1"
        let result2 = try renamer.renameScreenshots()
        XCTAssertEqual(result2.renamedFiles, 1, "Should rename second file")
        XCTAssertEqual(result2.errors.count, 0, "Should have no errors")

        // Verify both files exist with correct names
        let file1 = testDir.appendingPathComponent("screenshot 2026-01-05 at 13.23.45.png")
        let file2 = testDir.appendingPathComponent("screenshot 2026-01-05 at 13.23.45 1.png")

        XCTAssertTrue(FileManager.default.fileExists(atPath: file1.path), "First file should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: file2.path), "Second file with sequence should exist")

        // Verify content is different
        let content1 = try String(contentsOf: file1, encoding: .utf8)
        let content2 = try String(contentsOf: file2, encoding: .utf8)
        XCTAssertEqual(content1, "test1", "First file should have original content")
        XCTAssertEqual(content2, "test2", "Second file should have different content")
    }

    func testHandlesMultipleDuplicates() throws {
        let settings = ScreenshotSettings(location: testDir, prefix: "Screenshot")
        let renamer = ScreenshotRenamer(settings: settings, whitelist: [testDir])

        // Create 5 screenshots with same timestamp
        for i in 1...5 {
            let testFile = testDir.appendingPathComponent("Screenshot 2026-01-05 at 2.30.00 PM.png")
            try "test\(i)".write(to: testFile, atomically: true, encoding: .utf8)

            let result = try renamer.renameScreenshots()
            XCTAssertEqual(result.renamedFiles, 1, "Should rename file \(i)")
            XCTAssertEqual(result.errors.count, 0, "Should have no errors for file \(i)")
        }

        // Verify all files exist
        let expectedFiles = [
            "screenshot 2026-01-05 at 14.30.00.png",
            "screenshot 2026-01-05 at 14.30.00 1.png",
            "screenshot 2026-01-05 at 14.30.00 2.png",
            "screenshot 2026-01-05 at 14.30.00 3.png",
            "screenshot 2026-01-05 at 14.30.00 4.png"
        ]

        for (index, filename) in expectedFiles.enumerated() {
            let file = testDir.appendingPathComponent(filename)
            XCTAssertTrue(
                FileManager.default.fileExists(atPath: file.path),
                "File \(index + 1) should exist: \(filename)"
            )
        }
    }

    func testHandlesDifferentExtensions() throws {
        let settings = ScreenshotSettings(location: testDir, prefix: "Screenshot")
        let renamer = ScreenshotRenamer(settings: settings, whitelist: [testDir])

        // Create and rename first .jpg
        let testFile1 = testDir.appendingPathComponent("Screenshot 2026-01-05 at 3.00.00 PM.jpg")
        try "jpg1".write(to: testFile1, atomically: true, encoding: .utf8)
        _ = try renamer.renameScreenshots()

        // Create and rename second .jpg with same timestamp
        let testFile2 = testDir.appendingPathComponent("Screenshot 2026-01-05 at 3.00.00 PM.jpg")
        try "jpg2".write(to: testFile2, atomically: true, encoding: .utf8)
        _ = try renamer.renameScreenshots()

        // Verify both exist with .jpg extension preserved
        let file1 = testDir.appendingPathComponent("screenshot 2026-01-05 at 15.00.00.jpg")
        let file2 = testDir.appendingPathComponent("screenshot 2026-01-05 at 15.00.00 1.jpg")

        XCTAssertTrue(FileManager.default.fileExists(atPath: file1.path), "First .jpg should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: file2.path), "Second .jpg with sequence should exist")
    }

    func testIgnoresAlreadyRenamedFiles() throws {
        // Create already-renamed file
        let renamedFile = testDir.appendingPathComponent("screenshot 2026-01-05 at 13.00.00.png")
        try "already renamed".write(to: renamedFile, atomically: true, encoding: .utf8)

        let settings = ScreenshotSettings(location: testDir, prefix: "Screenshot")
        let renamer = ScreenshotRenamer(settings: settings, whitelist: [testDir])

        let result = try renamer.renameScreenshots()

        // Should not rename already-renamed file
        XCTAssertEqual(result.renamedFiles, 0, "Should not rename already-renamed files")
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: renamedFile.path),
            "Already-renamed file should still exist"
        )
    }
}
