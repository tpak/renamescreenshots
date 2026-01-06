//
//  FileValidator.swift
//  ScreenshotRenamer
//
//  Security validation for files and directories
//  Swift port of src/rename_screenshots.py validation functions
//

import Foundation
import os.log

/// Validates file paths and filenames for security
class FileValidator {
    private let whitelist: [URL]?

    /// Initialize validator
    /// - Parameter whitelist: Optional list of allowed directories
    init(whitelist: [URL]? = nil) {
        self.whitelist = whitelist
    }

    /// Validate that directory exists, is readable, writable, and in whitelist
    /// - Parameter url: Directory URL to validate
    /// - Throws: ScreenshotError if validation fails
    func validateDirectory(_ url: URL) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        // Check existence
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw ScreenshotError.directoryNotFound(url.path)
        }

        guard isDirectory.boolValue else {
            throw ScreenshotError.notADirectory(url.path)
        }

        // Check read permission
        guard fileManager.isReadableFile(atPath: url.path) else {
            throw ScreenshotError.noReadPermission(url.path)
        }

        // Check write permission
        guard fileManager.isWritableFile(atPath: url.path) else {
            throw ScreenshotError.noWritePermission(url.path)
        }

        // Resolve symlinks
        let resolvedURL = url.resolvingSymlinksInPath()

        // Check whitelist if configured
        if let whitelist = whitelist {
            let normalizedWhitelist = whitelist.map { $0.resolvingSymlinksInPath().standardized }
            let isAllowed = normalizedWhitelist.contains { allowed in
                let resolvedPath = resolvedURL.standardized.path
                let allowedPath = allowed.path

                // Allow exact match or subdirectory
                // Ensure trailing slash is properly handled to prevent false matches
                let allowedWithSlash = allowedPath.hasSuffix("/") ? allowedPath : allowedPath + "/"
                return resolvedPath == allowedPath ||
                       resolvedPath.hasPrefix(allowedWithSlash)
            }

            guard isAllowed else {
                throw ScreenshotError.notInWhitelist(url.path)
            }
        }
    }

    /// Sanitize and validate filename for security
    /// - Parameter filename: Filename to validate
    /// - Throws: ScreenshotError if filename is invalid
    func sanitizeFilename(_ filename: String) throws {
        // Check for empty filename
        guard !filename.isEmpty else {
            throw ScreenshotError.emptyFilename
        }

        // Check for whitespace-only
        guard !filename.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ScreenshotError.emptyFilename
        }

        // Check for null bytes
        guard !filename.contains("\0") else {
            throw ScreenshotError.invalidFilename("Contains null bytes")
        }

        // Check for path separators
        guard !filename.contains("/") && !filename.contains("\\") else {
            throw ScreenshotError.invalidFilename("Contains path separators")
        }

        // Check for path traversal attempts
        // Note: Path separators are already blocked above, but check for edge cases
        let trimmed = filename.trimmingCharacters(in: .whitespaces)
        if trimmed == "." || trimmed == ".." ||
           trimmed.hasPrefix("..") ||
           filename.contains("/..") ||
           filename.contains("..\\") {
            throw ScreenshotError.invalidFilename("Path traversal attempt")
        }

        // Additional check for multiple dots that could be confusing
        if trimmed.range(of: #"\.{3,}"#, options: .regularExpression) != nil {
            throw ScreenshotError.invalidFilename("Invalid dot sequence")
        }

        // Check for control characters (ASCII < 32)
        for char in filename.unicodeScalars {
            if char.value < 32 {
                throw ScreenshotError.invalidFilename("Contains control characters")
            }
        }
    }

    /// Validate that file path is within the given directory
    /// - Parameters:
    ///   - filePath: File path to validate
    ///   - directory: Directory that should contain the file
    /// - Throws: ScreenshotError if file is outside directory
    func validateFilePath(_ filePath: URL, withinDirectory directory: URL) throws {
        let resolvedFile = filePath.resolvingSymlinksInPath().standardized
        let resolvedDir = directory.resolvingSymlinksInPath().standardized

        guard resolvedFile.path.hasPrefix(resolvedDir.path + "/") ||
              resolvedFile.path == resolvedDir.path else {
            throw ScreenshotError.notInWhitelist(filePath.path)
        }
    }
}
