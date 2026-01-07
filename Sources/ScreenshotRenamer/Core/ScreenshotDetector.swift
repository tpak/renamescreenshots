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

    /// Set system screenshot location
    /// Changes the macOS system setting where screenshots are saved
    /// - Parameter location: URL of the new location
    /// - Returns: True if successful, false otherwise
    func setSystemLocation(_ location: URL) -> Bool {
        let success = ShellExecutor.writeDefaults(
            domain: "com.apple.screencapture",
            key: "location",
            value: location.path
        )

        if success {
            os_log("System screenshot location changed to: %{public}@",
                   log: .default, type: .info, location.path)
        } else {
            os_log("Failed to change system screenshot location",
                   log: .default, type: .error)
        }

        return success
    }

    // MARK: - Advanced Preferences

    /// Detect advanced screenshot preferences
    /// - Returns: ScreenshotPreferences with all advanced settings
    func detectPreferences() -> ScreenshotPreferences {
        let showThumbnail = detectShowThumbnail()
        let includeCursor = detectIncludeCursor()
        let disableShadow = detectDisableShadow()
        let format = detectFormat()
        let includeDate = detectIncludeDate()

        return ScreenshotPreferences(
            showThumbnail: showThumbnail,
            includeCursor: includeCursor,
            disableShadow: disableShadow,
            format: format,
            includeDate: includeDate
        )
    }

    /// Set show thumbnail preference
    /// - Parameter enabled: True to show thumbnail preview, false for immediate save
    /// - Returns: True if successful
    func setShowThumbnail(_ enabled: Bool) -> Bool {
        return ShellExecutor.writeBoolDefaults(
            domain: "com.apple.screencapture",
            key: "show-thumbnail",
            value: enabled
        )
    }

    /// Set include cursor preference
    /// - Parameter enabled: True to include mouse pointer in screenshots
    /// - Returns: True if successful
    func setIncludeCursor(_ enabled: Bool) -> Bool {
        return ShellExecutor.writeBoolDefaults(
            domain: "com.apple.screencapture",
            key: "show-cursor",
            value: enabled
        )
    }

    /// Set disable shadow preference
    /// - Parameter disabled: True to disable drop shadow on window screenshots
    /// - Returns: True if successful
    func setDisableShadow(_ disabled: Bool) -> Bool {
        return ShellExecutor.writeBoolDefaults(
            domain: "com.apple.screencapture",
            key: "disable-shadow",
            value: disabled
        )
    }

    /// Set screenshot format
    /// - Parameter format: Format for screenshots (png, jpg, pdf, tiff)
    /// - Returns: True if successful
    func setFormat(_ format: ScreenshotFormat) -> Bool {
        return ShellExecutor.writeDefaults(
            domain: "com.apple.screencapture",
            key: "type",
            value: format.rawValue
        )
    }

    /// Set include date in filename preference
    /// - Parameter enabled: True to include date/time in filename, false for sequential numbering
    /// - Returns: True if successful
    func setIncludeDate(_ enabled: Bool) -> Bool {
        return ShellExecutor.writeBoolDefaults(
            domain: "com.apple.screencapture",
            key: "include-date",
            value: enabled
        )
    }

    /// Reset all screenshot preferences to macOS defaults
    /// - Returns: True if all resets successful
    func resetToDefaults() -> Bool {
        let defaults = ScreenshotPreferences.defaults

        let results = [
            setShowThumbnail(defaults.showThumbnail),
            setIncludeCursor(defaults.includeCursor),
            setDisableShadow(defaults.disableShadow),
            setFormat(defaults.format),
            setIncludeDate(defaults.includeDate)
        ]

        let success = results.allSatisfy { $0 }

        if success {
            // Restart SystemUIServer to apply all changes
            _ = ShellExecutor.restartSystemUIServer()
            os_log("Reset all screenshot preferences to defaults",
                   log: .default, type: .info)
        }

        return success
    }

    // MARK: - Advanced Preference Detection

    private func detectShowThumbnail() -> Bool {
        guard let output = ShellExecutor.readDefaults(
            domain: "com.apple.screencapture",
            key: "show-thumbnail"
        ) else {
            return true // Default is true
        }
        return output == "1" || output.lowercased() == "true"
    }

    private func detectIncludeCursor() -> Bool {
        guard let output = ShellExecutor.readDefaults(
            domain: "com.apple.screencapture",
            key: "show-cursor"
        ) else {
            return false // Default is false
        }
        return output == "1" || output.lowercased() == "true"
    }

    private func detectDisableShadow() -> Bool {
        guard let output = ShellExecutor.readDefaults(
            domain: "com.apple.screencapture",
            key: "disable-shadow"
        ) else {
            return false // Default is false (shadows enabled)
        }
        return output == "1" || output.lowercased() == "true"
    }

    private func detectFormat() -> ScreenshotFormat {
        guard let output = ShellExecutor.readDefaults(
            domain: "com.apple.screencapture",
            key: "type"
        ) else {
            return .png // Default is PNG
        }
        return ScreenshotFormat(rawValue: output.lowercased()) ?? .png
    }

    private func detectIncludeDate() -> Bool {
        guard let output = ShellExecutor.readDefaults(
            domain: "com.apple.screencapture",
            key: "include-date"
        ) else {
            return true // Default is true
        }
        return output == "1" || output.lowercased() == "true"
    }

    /// Detect screenshot save location
    /// Reads from macOS system defaults, falls back to ~/Desktop
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
