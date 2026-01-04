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
    /// Pattern: Prefix YYYY-MM-DD at H.MM.SS AM/PM[ N].ext
    /// - Parameter prefix: Screenshot prefix to match
    /// - Returns: Compiled regex pattern
    private static func buildPattern(prefix: String) -> NSRegularExpression {
        // Escape special regex characters in prefix
        let escapedPrefix = NSRegularExpression.escapedPattern(for: prefix)

        // Build pattern string matching Python version
        // Group 1: date (YYYY-MM-DD)
        // Group 2: hour (1-12)
        // Group 3: minute (MM)
        // Group 4: second (SS)
        // Group 5: period (AM/PM)
        // Group 6: sequence number (optional, for rapid screenshots)
        // Group 7: extension (png, jpg, etc.)
        let patternString = """
        \(escapedPrefix) \
        (\\d{4}-\\d{2}-\\d{2}) at \
        (\\d{1,2})\\.(\\d{2})\\.(\\d{2})\\s*\
        ([APMapm]{2})\
        (?: (\\d+))?\
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
            return nil
        }

        // Extract captured groups
        let date = nsString.substring(with: match.range(at: 1))
        let hourString = nsString.substring(with: match.range(at: 2))
        let minute = nsString.substring(with: match.range(at: 3))
        let second = nsString.substring(with: match.range(at: 4))
        let period = nsString.substring(with: match.range(at: 5)).uppercased()

        // Sequence number is optional (group 6)
        let sequenceNum: String? = match.range(at: 6).location != NSNotFound
            ? nsString.substring(with: match.range(at: 6))
            : nil

        let ext = nsString.substring(with: match.range(at: 7))

        // Convert hour to integer
        guard let hour = Int(hourString) else {
            return nil
        }

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
