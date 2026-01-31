//
//  ScreenshotMatch.swift
//  ScreenshotRenamer
//
//  Represents a matched screenshot filename with parsed components
//

import Foundation

/// Parsed components of a screenshot filename
struct ScreenshotMatch {
    let date: String            // YYYY-MM-DD
    let hour: Int               // 1-12 (12h) or 0-23 (24h)
    let minute: String          // MM
    let second: String          // SS
    let period: String?         // AM/PM or nil for 24-hour format
    let sequenceNumber: String? // Optional sequence (1, 2, 3...)
    let fileExtension: String   // png, jpg, etc.

    /// Convert to 24-hour format
    /// If period is nil, hour is already in 24-hour format
    func to24Hour() -> Int {
        guard let period = period else {
            return hour
        }

        var hour24 = hour

        if period == "PM" && hour != 12 {
            hour24 += 12
        } else if period == "AM" && hour == 12 {
            hour24 = 0
        }

        return hour24
    }

    /// Build new filename in 24-hour format
    /// Preserves custom prefix in lowercase
    func buildNewFilename(prefix: String) -> String {
        let hour24 = to24Hour()
        let lowercasePrefix = prefix.lowercased()

        let hourFormatted = String(format: "%02d", hour24)
        let timestamp = "\(hourFormatted).\(minute).\(second)"

        if let seq = sequenceNumber {
            return "\(lowercasePrefix) \(date) at \(timestamp) \(seq).\(fileExtension)"
        } else {
            return "\(lowercasePrefix) \(date) at \(timestamp).\(fileExtension)"
        }
    }
}
