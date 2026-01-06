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

                // Find available filename (handle duplicates like macOS does)
                let finalFilename = findAvailableFilename(
                    newFilename,
                    in: settings.location,
                    fileManager: fileManager
                )

                // Build final URL
                let newURL = settings.location.appendingPathComponent(finalFilename)

                // Perform rename
                try fileManager.moveItem(at: fileURL, to: newURL)

                os_log("Renamed: %{public}@ -> %{public}@",
                       log: .default, type: .info, filename, finalFilename)
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

    /// Find available filename by appending sequence numbers if needed
    /// Mimics macOS behavior: file.png, file 1.png, file 2.png, etc.
    /// - Parameters:
    ///   - baseFilename: The desired filename (e.g., "screenshot 2026-01-05 at 21.30.45.png")
    ///   - directory: Directory where file will be saved
    ///   - fileManager: FileManager instance
    /// - Returns: Available filename (may have sequence number appended)
    private func findAvailableFilename(
        _ baseFilename: String,
        in directory: URL,
        fileManager: FileManager
    ) -> String {
        // Check if base filename is available
        let baseURL = directory.appendingPathComponent(baseFilename)
        if !fileManager.fileExists(atPath: baseURL.path) {
            return baseFilename
        }

        // Split filename into name and extension (split from the RIGHT to get last extension)
        guard let lastDotIndex = baseFilename.lastIndex(of: ".") else {
            // No extension, just append numbers
            return findSequencedFilename(baseFilename, "", in: directory, fileManager: fileManager)
        }

        let nameWithoutExtension = String(baseFilename[..<lastDotIndex])
        let fileExtension = String(baseFilename[baseFilename.index(after: lastDotIndex)...])

        return findSequencedFilename(nameWithoutExtension, fileExtension, in: directory, fileManager: fileManager)
    }

    /// Find available filename with sequence number
    /// - Parameters:
    ///   - name: Filename without extension
    ///   - fileExtension: File extension (without dot)
    ///   - directory: Directory where file will be saved
    ///   - fileManager: FileManager instance
    /// - Returns: Filename with sequence number (e.g., "file 1.png")
    private func findSequencedFilename(
        _ name: String,
        _ fileExtension: String,
        in directory: URL,
        fileManager: FileManager
    ) -> String {
        // Pre-load directory contents into a Set for O(1) lookup instead of O(n) per iteration
        let existingFiles: Set<String>
        do {
            existingFiles = Set(try fileManager.contentsOfDirectory(atPath: directory.path))
        } catch {
            os_log("Failed to read directory contents: %{public}@",
                   log: .default, type: .error, error.localizedDescription)
            // Fallback to timestamp on error
            let timestamp = Int(Date().timeIntervalSince1970)
            return fileExtension.isEmpty
                ? "\(name) \(timestamp)"
                : "\(name) \(timestamp).\(fileExtension)"
        }

        // Try sequence numbers 1, 2, 3, ... up to 999
        for i in 1...999 {
            let sequencedName = fileExtension.isEmpty
                ? "\(name) \(i)"
                : "\(name) \(i).\(fileExtension)"

            if !existingFiles.contains(sequencedName) {
                os_log("Found available filename with sequence: %{public}@",
                       log: .default, type: .debug, sequencedName)
                return sequencedName
            }
        }

        // Fallback: append timestamp if we somehow have 999+ duplicates
        let timestamp = Int(Date().timeIntervalSince1970)
        let fallbackName = fileExtension.isEmpty
            ? "\(name) \(timestamp)"
            : "\(name) \(timestamp).\(fileExtension)"

        os_log("Using timestamp fallback for filename: %{public}@",
               log: .default, type: .info, fallbackName)
        return fallbackName
    }
}
