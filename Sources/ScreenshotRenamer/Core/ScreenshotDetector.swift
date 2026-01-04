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

    /// UserDefaults key for custom screenshot location
    static let customLocationKey = "customScreenshotLocation"

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

    /// Set custom screenshot location
    /// - Parameter location: URL of the custom location
    func setCustomLocation(_ location: URL) {
        UserDefaults.standard.set(location.path, forKey: Self.customLocationKey)
        os_log("Custom screenshot location set: %{public}@",
               log: .default, type: .info, location.path)
    }

    /// Clear custom screenshot location (revert to macOS defaults)
    func clearCustomLocation() {
        UserDefaults.standard.removeObject(forKey: Self.customLocationKey)
        os_log("Custom screenshot location cleared",
               log: .default, type: .info)
    }

    /// Detect screenshot save location
    /// Priority: 1. Custom location (UserDefaults), 2. macOS defaults, 3. ~/Desktop
    private func detectLocation() -> URL {
        // Check for custom location first
        if let customPath = UserDefaults.standard.string(forKey: Self.customLocationKey) {
            let url = URL(fileURLWithPath: customPath)
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(
                atPath: url.path,
                isDirectory: &isDirectory
            )

            if exists && isDirectory.boolValue {
                os_log("Using custom screenshot location: %{public}@",
                       log: .default, type: .debug, url.path)
                return url
            } else {
                os_log("Custom location invalid, falling back to macOS defaults",
                       log: .default, type: .debug)
                // Clear invalid custom location
                clearCustomLocation()
            }
        }

        // Fall back to macOS defaults
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
