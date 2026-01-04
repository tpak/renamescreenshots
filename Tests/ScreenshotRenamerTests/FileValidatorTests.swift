//
//  FileValidatorTests.swift
//  ScreenshotRenamerTests
//
//  Unit tests for file validation
//  Swift port of tests/test_security.py
//

import XCTest
@testable import ScreenshotRenamer

class FileValidatorTests: XCTestCase {

    func testValidatesExistingDirectory() throws {
        let validator = FileValidator()
        let tempDir = FileManager.default.temporaryDirectory

        XCTAssertNoThrow(try validator.validateDirectory(tempDir))
    }

    func testRejectsNonexistentDirectory() {
        let validator = FileValidator()
        let fakeDir = URL(fileURLWithPath: "/nonexistent/directory/that/does/not/exist")

        XCTAssertThrowsError(try validator.validateDirectory(fakeDir)) { error in
            XCTAssertTrue(error is ScreenshotError)
        }
    }

    func testRejectsFile() throws {
        let validator = FileValidator()
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test.txt")

        // Create temp file
        try "test".write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        XCTAssertThrowsError(try validator.validateDirectory(tempFile)) { error in
            XCTAssertTrue(error is ScreenshotError)
        }
    }

    func testSanitizesValidFilename() throws {
        let validator = FileValidator()

        XCTAssertNoThrow(try validator.sanitizeFilename("valid.png"))
        XCTAssertNoThrow(try validator.sanitizeFilename("screenshot 2024-05-24 at 13.23.45.png"))
    }

    func testRejectsEmptyFilename() {
        let validator = FileValidator()

        XCTAssertThrowsError(try validator.sanitizeFilename(""))
        XCTAssertThrowsError(try validator.sanitizeFilename("   "))
    }

    func testRejectsNullBytes() {
        let validator = FileValidator()

        XCTAssertThrowsError(try validator.sanitizeFilename("file\0name.png"))
    }

    func testRejectsPathSeparators() {
        let validator = FileValidator()

        XCTAssertThrowsError(try validator.sanitizeFilename("../etc/passwd"))
        XCTAssertThrowsError(try validator.sanitizeFilename("dir/file.png"))
        XCTAssertThrowsError(try validator.sanitizeFilename("dir\\file.png"))
    }

    func testRejectsPathTraversal() {
        let validator = FileValidator()

        XCTAssertThrowsError(try validator.sanitizeFilename(".."))
        XCTAssertThrowsError(try validator.sanitizeFilename("."))
        XCTAssertThrowsError(try validator.sanitizeFilename("../file.png"))
    }

    func testRejectsControlCharacters() {
        let validator = FileValidator()

        let filenameWithControl = "file\u{0001}name.png"
        XCTAssertThrowsError(try validator.sanitizeFilename(filenameWithControl))
    }

    func testWhitelistAllowsDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let validator = FileValidator(whitelist: [tempDir])

        XCTAssertNoThrow(try validator.validateDirectory(tempDir))
    }

    func testWhitelistRejectsDirectory() {
        let whitelistedDir = FileManager.default.temporaryDirectory
        let otherDir = FileManager.default.homeDirectoryForCurrentUser

        let validator = FileValidator(whitelist: [whitelistedDir])

        XCTAssertThrowsError(try validator.validateDirectory(otherDir)) { error in
            if case ScreenshotError.notInWhitelist = error {
                // Expected error
            } else {
                XCTFail("Expected notInWhitelist error")
            }
        }
    }

    func testWhitelistAllowsSubdirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let subDir = tempDir.appendingPathComponent("subdir")

        // Create subdirectory
        try FileManager.default.createDirectory(
            at: subDir,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: subDir) }

        let validator = FileValidator(whitelist: [tempDir])

        XCTAssertNoThrow(try validator.validateDirectory(subDir))
    }
}
