//
//  PatternMatcher.swift
//  ScreenshotRenamer
//
//  Pattern matching for screenshot filenames
//  Swift port of src/rename_screenshots.py build_screenshot_pattern()
//

import Foundation

/// Matches screenshot filenames with regex pattern
class PatternMatcher {
    private let prefix: String
    private let regex: NSRegularExpression

    /// Initialize with screenshot prefix
    /// - Parameter prefix: Screenshot filename prefix (e.g., "Screenshot", "MyScreenshot")
    init(prefix: String) {
        self.prefix = prefix
        self.regex = Self.buildPattern(prefix: prefix)
    }

    /// Build regex pattern for screenshot filenames
    /// Pattern: Prefix YYYY-MM-DD at H.MM.SS[ AM/PM][ N|(N)].ext
    /// - Parameter prefix: Screenshot prefix to match
    /// - Returns: Compiled regex pattern
    private static func buildPattern(prefix: String) -> NSRegularExpression {
        // Escape special regex characters in prefix
        let escapedPrefix = NSRegularExpression.escapedPattern(for: prefix)

        // Build pattern string
        // Group 1: date (YYYY-MM-DD)
        // Group 2: hour (1-23)
        // Group 3: minute (MM)
        // Group 4: second (SS)
        // Group 5: period (AM/PM, optional — absent for 24-hour format)
        // Group 6: bare sequence number (optional, e.g. " 2")
        // Group 7: parenthesized sequence number (optional, e.g. " (2)")
        // Group 8: extension (png, jpg, etc.)
        let patternString = """
        \(escapedPrefix) \
        (\\d{4}-\\d{2}-\\d{2}) at \
        (\\d{1,2})\\.(\\d{2})\\.(\\d{2})\
        (?:\\s+([APMapm]{2}))?\
        (?:\\s+(?:(\\d+)|\\((\\d+)\\)))?\
        \\.\
        (\\w+)
        """

        // Create regex with case-insensitive flag
        do {
            return try NSRegularExpression(
                pattern: patternString,
                options: [.caseInsensitive]
            )
        } catch {
            // Should never happen with our hardcoded pattern
            fatalError("Invalid regex pattern: \(error)")
        }
    }

    /// Match a filename against the screenshot pattern
    /// - Parameter filename: Filename to match
    /// - Returns: ScreenshotMatch if matched, nil otherwise
    func match(_ filename: String) -> ScreenshotMatch? {
        let nsString = filename as NSString
        let range = NSRange(location: 0, length: nsString.length)

        guard let match = regex.firstMatch(in: filename, range: range) else {
            DebugLogger.shared.log("No match for: \(filename)", category: "PatternMatcher")
            return nil
        }

        // Extract captured groups
        let date = nsString.substring(with: match.range(at: 1))
        let hourString = nsString.substring(with: match.range(at: 2))
        let minute = nsString.substring(with: match.range(at: 3))
        let second = nsString.substring(with: match.range(at: 4))

        // Period is optional (group 5) — nil for 24-hour format
        let period: String? = match.range(at: 5).location != NSNotFound
            ? nsString.substring(with: match.range(at: 5)).uppercased()
            : nil

        // Sequence number: bare (group 6) or parenthesized (group 7)
        let sequenceNum: String?
        if match.range(at: 6).location != NSNotFound {
            sequenceNum = nsString.substring(with: match.range(at: 6))
        } else if match.range(at: 7).location != NSNotFound {
            sequenceNum = nsString.substring(with: match.range(at: 7))
        } else {
            sequenceNum = nil
        }

        let ext = nsString.substring(with: match.range(at: 8))

        // Convert hour to integer
        guard let hour = Int(hourString) else {
            return nil
        }

        DebugLogger.shared.log(
            "Matched: \(filename) -> date=\(date) hour=\(hour) min=\(minute) sec=\(second) period=\(period ?? "nil") seq=\(sequenceNum ?? "nil") ext=\(ext)",
            category: "PatternMatcher"
        )

        return ScreenshotMatch(
            date: date,
            hour: hour,
            minute: minute,
            second: second,
            period: period,
            sequenceNumber: sequenceNum,
            fileExtension: ext
        )
    }
}
