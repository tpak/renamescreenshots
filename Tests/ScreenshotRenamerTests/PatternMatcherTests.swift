//
//  PatternMatcherTests.swift
//  ScreenshotRenamerTests
//
//  Unit tests for pattern matching
//  Swift port of tests/test_pattern_builder.py
//

import XCTest
@testable import ScreenshotRenamer

class PatternMatcherTests: XCTestCase {
    func testDefaultPattern() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.png"))
        XCTAssertNotNil(matcher.match("Screenshot 2024-12-31 at 11.59.59 PM.jpg"))
        XCTAssertNotNil(matcher.match("Screenshot 2024-01-01 at 12.00.00 AM.png"))
    }

    func testCustomPrefix() {
        let matcher = PatternMatcher(prefix: "MyScreenshot")

        XCTAssertNotNil(matcher.match("MyScreenshot 2024-05-24 at 1.23.45 PM.png"))
        XCTAssertNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.png"))
    }

    func testSpecialCharactersInPrefix() {
        let matcher = PatternMatcher(prefix: "My.Screenshot")

        XCTAssertNotNil(matcher.match("My.Screenshot 2024-05-24 at 1.23.45 PM.png"))
    }

    func testCaseInsensitive() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.png"))
        XCTAssertNotNil(matcher.match("screenshot 2024-05-24 at 1.23.45 PM.png"))
        XCTAssertNotNil(matcher.match("SCREENSHOT 2024-05-24 at 1.23.45 PM.png"))
    }

    func testSequentialScreenshots() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        let match1 = matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.png")
        XCTAssertNil(match1?.sequenceNumber)

        let match2 = matcher.match("Screenshot 2024-05-24 at 1.23.45 PM 1.png")
        XCTAssertEqual(match2?.sequenceNumber, "1")

        let match3 = matcher.match("Screenshot 2024-05-24 at 1.23.45 PM 2.png")
        XCTAssertEqual(match3?.sequenceNumber, "2")
    }

    func test24HourConversion() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        // 1 PM = 13:00
        let match1 = matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.png")!
        XCTAssertEqual(match1.to24Hour(), 13)

        // 12 AM = 00:00
        let match2 = matcher.match("Screenshot 2024-05-24 at 12.00.00 AM.png")!
        XCTAssertEqual(match2.to24Hour(), 0)

        // 12 PM = 12:00
        let match3 = matcher.match("Screenshot 2024-05-24 at 12.00.00 PM.png")!
        XCTAssertEqual(match3.to24Hour(), 12)

        // 11 PM = 23:00
        let match4 = matcher.match("Screenshot 2024-05-24 at 11.59.59 PM.png")!
        XCTAssertEqual(match4.to24Hour(), 23)
    }

    func testBuildNewFilename() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        let match = matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.png")!
        let newFilename = match.buildNewFilename(prefix: "Screenshot")

        XCTAssertEqual(newFilename, "screenshot 2024-05-24 at 13.23.45.png")
    }

    func testBuildNewFilenameWithSequence() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        let match = matcher.match("Screenshot 2024-05-24 at 1.23.45 PM 2.png")!
        let newFilename = match.buildNewFilename(prefix: "Screenshot")

        XCTAssertEqual(newFilename, "screenshot 2024-05-24 at 13.23.45 2.png")
    }

    func testPreservesCustomPrefix() {
        let matcher = PatternMatcher(prefix: "MyScreenshot")

        let match = matcher.match("MyScreenshot 2024-05-24 at 1.23.45 PM.png")!
        let newFilename = match.buildNewFilename(prefix: "MyScreenshot")

        XCTAssertEqual(newFilename, "myscreenshot 2024-05-24 at 13.23.45.png")
    }

    func testDoesNotMatchInvalidFormat() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        XCTAssertNil(matcher.match("NotAScreenshot.png"))
        XCTAssertNil(matcher.match("Screenshot.png"))
        XCTAssertNil(matcher.match("Screenshot 2024-05-24.png"))
    }

    func testMatchesVariousExtensions() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.png"))
        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.jpg"))
        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.jpeg"))
        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.gif"))
    }

    func testMatchesSingleAndDoubleDigitHours() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.png"))
        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 12.23.45 PM.png"))
    }

    func testMatchesAMPMVariations() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 AM.png"))
        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 PM.png"))
        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 am.png"))
        XCTAssertNotNil(matcher.match("Screenshot 2024-05-24 at 1.23.45 pm.png"))
    }
}
