//
//  ScreenshotRenamer.swift
//  ScreenshotRenamer
//
//  Core screenshot renaming logic
//  Swift port of src/rename_screenshots.py rename_screenshots()
//

import Foundation
import os.log

/// Renames screenshot files from 12-hour to 24-hour format
class ScreenshotRenamer {
    private let settings: ScreenshotSettings
    private let validator: FileValidator
    private let matcher: PatternMatcher

    /// Initialize renamer with settings
    /// - Parameters:
    ///   - settings: Screenshot settings (location and prefix)
    ///   - whitelist: Optional whitelist of allowed directories
    init(settings: ScreenshotSettings, whitelist: [URL]? = nil) {
        self.settings = settings
        self.validator = FileValidator(whitelist: whitelist)
        self.matcher = PatternMatcher(prefix: settings.prefix)
    }

    /// Rename all screenshots in the configured directory
    /// - Returns: RenameResult with statistics
    /// - Throws: ScreenshotError if directory validation fails
    func renameScreenshots() throws -> RenameResult {
        // Validate directory
        try validator.validateDirectory(settings.location)

        let fileManager = FileManager.default

        // Get directory contents (skip hidden files)
        let contents = try fileManager.contentsOfDirectory(
            at: settings.location,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var totalFiles = 0
        var renamedFiles = 0
        var errors: [String] = []

        for fileURL in contents {
            totalFiles += 1
            let filename = fileURL.lastPathComponent

            // Check if matches screenshot pattern
            guard let match = matcher.match(filename) else {
                continue
            }

            do {
                // Sanitize original filename
                try validator.sanitizeFilename(filename)

                // Build new filename
                let newFilename = match.buildNewFilename(prefix: settings.prefix)

                // Sanitize new filename
                try validator.sanitizeFilename(newFilename)

                // Build new URL
                let newURL = settings.location.appendingPathComponent(newFilename)

                // Check if target already exists
                if fileManager.fileExists(atPath: newURL.path) {
                    os_log("Skipping: target exists - %{public}@",
                           log: .default, type: .info, newFilename)
                    errors.append("Target exists: \(newFilename)")
                    continue
                }

                // Perform rename
                try fileManager.moveItem(at: fileURL, to: newURL)

                os_log("Renamed: %{public}@ -> %{public}@",
                       log: .default, type: .info, filename, newFilename)
                renamedFiles += 1

            } catch {
                os_log("Error renaming %{public}@: %{public}@",
                       log: .default, type: .error, filename, error.localizedDescription)
                errors.append("\(filename): \(error.localizedDescription)")
            }
        }

        return RenameResult(
            totalFiles: totalFiles,
            renamedFiles: renamedFiles,
            errors: errors
        )
    }

    /// Async version of renameScreenshots for UI updates
    /// - Returns: RenameResult with statistics
    /// - Throws: ScreenshotError if operation fails
    func renameScreenshotsAsync() async throws -> RenameResult {
        return try await Task.detached(priority: .userInitiated) {
            try self.renameScreenshots()
        }.value
    }
}
