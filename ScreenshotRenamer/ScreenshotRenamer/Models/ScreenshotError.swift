//
//  ScreenshotError.swift
//  ScreenshotRenamer
//
//  Error types for screenshot renaming operations
//

import Foundation

/// Errors that can occur during screenshot operations
enum ScreenshotError: LocalizedError {
    case directoryNotFound(String)
    case notADirectory(String)
    case noReadPermission(String)
    case noWritePermission(String)
    case notInWhitelist(String)
    case emptyFilename
    case invalidFilename(String)
    case commandFailed
    case fileAlreadyExists(String)

    var errorDescription: String? {
        switch self {
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        case .notADirectory(let path):
            return "Not a directory: \(path)"
        case .noReadPermission(let path):
            return "No read permission: \(path)"
        case .noWritePermission(let path):
            return "No write permission: \(path)"
        case .notInWhitelist(let path):
            return "Directory not in whitelist: \(path)"
        case .emptyFilename:
            return "Filename cannot be empty"
        case .invalidFilename(let reason):
            return "Invalid filename: \(reason)"
        case .commandFailed:
            return "Shell command failed"
        case .fileAlreadyExists(let name):
            return "File already exists: \(name)"
        }
    }
}
