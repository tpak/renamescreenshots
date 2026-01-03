//
//  ScreenshotDetector.swift
//  ScreenshotRenamer
//
//  Detects macOS screenshot settings
//  Swift port of src/macos_settings.py
//

import Foundation
import os.log

/// Detects macOS screenshot location and filename prefix
class ScreenshotDetector {

    /// Detect current screenshot settings from macOS
    /// - Returns: ScreenshotSettings with location and prefix
    func detectSettings() -> ScreenshotSettings {
        let location = detectLocation()
        let prefix = detectPrefix()

        os_log("Detected settings - Location: %{public}@, Prefix: %{public}@",
               log: .default, type: .info,
               location.path, prefix)

        return ScreenshotSettings(location: location, prefix: prefix)
    }

    /// Detect screenshot save location
    /// Reads from: defaults read com.apple.screencapture location
    /// Falls back to ~/Desktop if not set or invalid
    private func detectLocation() -> URL {
        guard let output = ShellExecutor.readDefaults(
            domain: "com.apple.screencapture",
            key: "location"
        ) else {
            return defaultLocation()
        }

        // Expand tilde and resolve path
        let expandedPath = (output as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        // Verify directory exists and is readable
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(
            atPath: url.path,
            isDirectory: &isDirectory
        )

        guard exists && isDirectory.boolValue else {
            os_log("Screenshot location invalid or not a directory: %{public}@",
                   log: .default, type: .debug, url.path)
            return defaultLocation()
        }

        return url
    }

    /// Detect screenshot filename prefix
    /// Reads from: defaults read com.apple.screencapture name
    /// Falls back to "Screenshot" if not set
    private func detectPrefix() -> String {
        guard let output = ShellExecutor.readDefaults(
            domain: "com.apple.screencapture",
            key: "name"
        ), !output.isEmpty else {
            return "Screenshot"
        }

        return output
    }

    /// Default screenshot location (~/Desktop)
    private func defaultLocation() -> URL {
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
    }
}
