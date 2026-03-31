//
//  ScreenshotWatcherTests.swift
//  ScreenshotRenamerTests
//
//  Created by Gemini on 2024-03-31.
//
//  Integration tests for the ScreenshotWatcher component.
//

import XCTest
@testable import ScreenshotRenamer

class ScreenshotWatcherTests: XCTestCase {
    var testDir: URL!
    var watcher: ScreenshotWatcher!

    override func setUp() {
        super.setUp()
        testDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("watcher-test-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        
        let settings = ScreenshotSettings(location: testDir, prefix: "Screenshot")
        watcher = ScreenshotWatcher(settings: settings)
    }

    override func tearDown() {
        watcher.stopWatching()
        try? FileManager.default.removeItem(at: testDir)
        super.tearDown()
    }

    func test_detectsNewScreenshotAndRenamesIt() {
        let expectation = XCTestExpectation(description: "Rename operation should complete")
        
        watcher.startWatching()
        
        let originalFile = testDir.appendingPathComponent("Screenshot 2026-03-31 at 10.15.30 AM.png")
        try! "test data".write(to: originalFile, atomically: true, encoding: .utf8)
        
        // Poll for the renamed file's existence after the debounce delay.
        // A 0.5s delay should be sufficient for the 0.3s debounce.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let expectedFile = self.testDir.appendingPathComponent("screenshot 2026-03-31 at 10.15.30.png")
            XCTAssertTrue(FileManager.default.fileExists(atPath: expectedFile.path), "Renamed file should exist")
            XCTAssertFalse(FileManager.default.fileExists(atPath: originalFile.path), "Original file should not exist")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func test_ignoresNonScreenshotFiles() {
        let expectation = XCTestExpectation(description: "Wait period to ensure no rename occurs")
        
        watcher.startWatching()
        
        let nonScreenshotFile = testDir.appendingPathComponent("just-a-file.txt")
        try! "some data".write(to: nonScreenshotFile, atomically: true, encoding: .utf8)
        
        // Wait for longer than the debounce time.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Check that the file has NOT been renamed.
            let contents = try! FileManager.default.contentsOfDirectory(atPath: self.testDir.path)
            XCTAssertEqual(contents.count, 1)
            XCTAssertEqual(contents.first, "just-a-file.txt")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }

    func test_debouncesMultipleRapidEvents() {
        let expectation = XCTestExpectation(description: "All files should be renamed after debounce")
        
        watcher.startWatching()
        
        // Create 5 files in quick succession, much faster than the debounce delay.
        for i in 0..<5 {
            let fileName = "Screenshot 2026-03-31 at 11.30.0\(i) AM.png"
            let fileURL = testDir.appendingPathComponent(fileName)
            try! "test\(i)".write(to: fileURL, atomically: true, encoding: .utf8)
            // No sleep, create them as fast as possible.
        }
        
        // After one debounce period, one rename operation should have run and processed all files.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let contents = try! FileManager.default.contentsOfDirectory(atPath: self.testDir.path)
            let renamedFiles = contents.filter { $0.starts(with: "screenshot") }
            XCTAssertEqual(renamedFiles.count, 5, "All 5 screenshots should have been renamed")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
}
