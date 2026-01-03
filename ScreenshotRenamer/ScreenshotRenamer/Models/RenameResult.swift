//
//  RenameResult.swift
//  ScreenshotRenamer
//
//  Result of a rename operation
//

import Foundation

/// Result of a screenshot rename operation
struct RenameResult {
    let totalFiles: Int
    let renamedFiles: Int
    let errors: [String]

    var hasErrors: Bool {
        return !errors.isEmpty
    }

    var summary: String {
        return "Scanned \(totalFiles) files, renamed \(renamedFiles) screenshots"
    }

    var detailedSummary: String {
        var result = summary
        if hasErrors {
            result += "\n\nErrors:\n" + errors.joined(separator: "\n")
        }
        return result
    }
}
