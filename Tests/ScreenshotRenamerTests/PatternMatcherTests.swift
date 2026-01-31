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

    // MARK: - 24-hour format tests

    func test24HourFormatMatching() {
        let matcher = PatternMatcher(prefix: "screenshot")

        let match = matcher.match("screenshot 2025-10-22 at 11.12.37.png")
        XCTAssertNotNil(match, "24-hour format without AM/PM should match")
        XCTAssertEqual(match?.hour, 11)
        XCTAssertEqual(match?.minute, "12")
        XCTAssertEqual(match?.second, "37")
        XCTAssertNil(match?.period, "Period should be nil for 24-hour format")
        XCTAssertNil(match?.sequenceNumber)
        XCTAssertEqual(match?.fileExtension, "png")
    }

    func test24HourFormatHighHour() {
        let matcher = PatternMatcher(prefix: "screenshot")

        let match = matcher.match("screenshot 2025-10-22 at 17.25.30.png")
        XCTAssertNotNil(match, "Hour 17 (24-hour) should match")
        XCTAssertEqual(match?.hour, 17)
        XCTAssertNil(match?.period)
    }

    func test24HourTo24HourConversion() {
        let matcher = PatternMatcher(prefix: "screenshot")

        let match = matcher.match("screenshot 2026-01-22 at 14.10.07.png")!
        XCTAssertNil(match.period)
        XCTAssertEqual(match.to24Hour(), 14, "to24Hour() should return hour directly when period is nil")
    }

    func testBuildNewFilename24Hour() {
        let matcher = PatternMatcher(prefix: "screenshot")

        let match = matcher.match("screenshot 2026-01-22 at 14.10.07.png")!
        let newFilename = match.buildNewFilename(prefix: "screenshot")

        XCTAssertEqual(newFilename, "screenshot 2026-01-22 at 14.10.07.png",
                       "Already-correct 24-hour file should produce identical filename")
    }

    func test24HourWithSequenceNumber() {
        let matcher = PatternMatcher(prefix: "screenshot")

        let match = matcher.match("screenshot 2026-01-22 at 14.10.07 1.png")
        XCTAssertNotNil(match, "24-hour with bare sequence should match")
        XCTAssertEqual(match?.hour, 14)
        XCTAssertNil(match?.period)
        XCTAssertEqual(match?.sequenceNumber, "1")
    }

    // MARK: - Parenthesized sequence number tests

    func testParenthesizedSequenceNumber() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        let match = matcher.match("Screenshot 2026-01-08 at 9.20.55 am (2).png")
        XCTAssertNotNil(match, "Parenthesized sequence should match")
        XCTAssertEqual(match?.sequenceNumber, "2")
        XCTAssertEqual(match?.period, "AM")
        XCTAssertEqual(match?.hour, 9)
    }

    func testBuildNewFilenameParenSequence() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        let match = matcher.match("Screenshot 2026-01-08 at 9.20.55 am (2).png")!
        let newFilename = match.buildNewFilename(prefix: "Screenshot")

        XCTAssertEqual(newFilename, "screenshot 2026-01-08 at 09.20.55 2.png",
                       "Parenthesized sequence should be normalized to bare number")
    }

    // MARK: - Uppercase prefix with 24-hour

    func testRenames24HourWithUpperPrefix() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        let match = matcher.match("Screenshot 2025-10-22 at 17.25.30.png")
        XCTAssertNotNil(match, "Uppercase prefix with 24-hour time should match")
        XCTAssertEqual(match?.hour, 17)
        XCTAssertNil(match?.period)

        let newFilename = match!.buildNewFilename(prefix: "Screenshot")
        XCTAssertEqual(newFilename, "screenshot 2025-10-22 at 17.25.30.png")
    }

    // MARK: - Real-world filenames from user

    func testRealWorldFilenames() {
        let matcher = PatternMatcher(prefix: "Screenshot")

        let testCases: [(filename: String, shouldMatch: Bool, expectedHour: Int?, expectedSeq: String?)] = [
            ("screenshot 2025-10-22 at 11.12.37.png", true, 11, nil),
            ("screenshot 2026-01-22 at 14.10.07 1.png", true, 14, "1"),
            ("Screenshot 2026-01-08 at 9.20.55 am (2).png", true, 9, "2"),
            ("Screenshot 2026-01-19 at 10.03.12 am (2).png", true, 10, "2"),
            ("Screenshot 2026-01-21 at 9.35.21 am (2).png", true, 9, "2"),
            ("Screenshot 2026-01-21 at 9.35.33 am (2).png", true, 9, "2"),
            ("Screenshot 2026-01-21 at 9.35.50 am (2).png", true, 9, "2"),
            ("screenshot 2026-01-22 at 14.10.07.png", true, 14, nil),
            ("screenshot 2025-10-22 at 17.25.30.png", true, 17, nil),
            ("screenshot 2025-12-23 at 06.02.10.png", true, 6, nil),
        ]

        for tc in testCases {
            let match = matcher.match(tc.filename)
            if tc.shouldMatch {
                XCTAssertNotNil(match, "Should match: \(tc.filename)")
                XCTAssertEqual(match?.hour, tc.expectedHour, "Hour mismatch for: \(tc.filename)")
                XCTAssertEqual(match?.sequenceNumber, tc.expectedSeq, "Sequence mismatch for: \(tc.filename)")
            } else {
                XCTAssertNil(match, "Should not match: \(tc.filename)")
            }
        }
    }
}
