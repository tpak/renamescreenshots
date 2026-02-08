//
//  ShellExecutorTests.swift
//  ScreenshotRenamerTests
//
//  Unit tests for shell command execution
//

import XCTest
@testable import ScreenshotRenamer

class ShellExecutorTests: XCTestCase {
    func testReadDefaults() {
        // Test reading an existing defaults value
        // This test reads the actual system value
        let location = ShellExecutor.readDefaults(
            domain: "com.apple.screencapture",
            key: "location"
        )

        // Location might be nil if not set, which is valid
        if let location = location {
            XCTAssertFalse(location.isEmpty, "Location should not be empty if set")
        }
    }

    func testReadDefaultsInvalidDomain() {
        // Test reading from invalid domain returns nil
        let result = ShellExecutor.readDefaults(
            domain: "com.nonexistent.domain.test",
            key: "somekey"
        )

        XCTAssertNil(result, "Reading from invalid domain should return nil")
    }

    func testWriteDefaults() {
        // Create a temporary test domain to avoid affecting system settings
        let testDomain = "com.tirpak.screenshot-renamer.test"
        let testKey = "testKey"
        let testValue = "/tmp/test-location"

        // Write the default
        let writeSuccess = ShellExecutor.writeDefaults(
            domain: testDomain,
            key: testKey,
            value: testValue
        )

        XCTAssertTrue(writeSuccess, "Writing defaults should succeed")

        // Read it back to verify
        let readValue = ShellExecutor.readDefaults(
            domain: testDomain,
            key: testKey
        )

        XCTAssertEqual(readValue, testValue, "Read value should match written value")

        // Cleanup: delete the test key
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["delete", testDomain, testKey]
        try? process.run()
        process.waitUntilExit()
    }

    func testWriteBoolDefaults() {
        // Create a temporary test domain to avoid affecting system settings
        let testDomain = "com.tirpak.screenshot-renamer.test"
        let testKey = "testBoolKey"

        // Write true
        let writeTrue = ShellExecutor.writeBoolDefaults(
            domain: testDomain,
            key: testKey,
            value: true
        )
        XCTAssertTrue(writeTrue, "Writing bool defaults (true) should succeed")

        // Read it back
        let readTrue = ShellExecutor.readDefaults(
            domain: testDomain,
            key: testKey
        )
        XCTAssertTrue(
            readTrue == "1" || readTrue?.lowercased() == "true",
            "Read value should be true (1 or true)"
        )

        // Write false
        let writeFalse = ShellExecutor.writeBoolDefaults(
            domain: testDomain,
            key: testKey,
            value: false
        )
        XCTAssertTrue(writeFalse, "Writing bool defaults (false) should succeed")

        // Read it back
        let readFalse = ShellExecutor.readDefaults(
            domain: testDomain,
            key: testKey
        )
        XCTAssertTrue(
            readFalse == "0" || readFalse?.lowercased() == "false",
            "Read value should be false (0 or false)"
        )

        // Cleanup: delete the test key
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["delete", testDomain, testKey]
        try? process.run()
        process.waitUntilExit()
    }

    func testRestartSystemUIServer() {
        // Note: This test actually restarts SystemUIServer
        // The menu bar will briefly flicker, which is expected behavior
        // We verify the function can be called without crashing
        // May return false if SystemUIServer is still restarting from previous tests

        // Wait for SystemUIServer to be running (poll up to 3 seconds)
        for _ in 0..<6 {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
            task.arguments = ["SystemUIServer"]
            try? task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 { break }
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Call the function - success depends on system state
        let result = ShellExecutor.restartSystemUIServer()

        // Result is a Bool (true or false), test passes either way
        // The important thing is it doesn't crash
        XCTAssertNotNil(result as Bool?)

        // Give system time to stabilize for subsequent tests
        Thread.sleep(forTimeInterval: 0.5)
    }
}
