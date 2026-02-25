//
//  SettingsSnapshot.swift
//  ScreenshotRenamer
//
//  Persists screenshot settings to app UserDefaults so they can be
//  restored if macOS resets them (e.g., after a Sparkle update).
//

import Foundation
import os.log

enum SettingsSnapshot {
    private static let key = "knownGoodSettings"

    /// Save current com.apple.screencapture settings to app UserDefaults.
    /// Call this on every deliberate settings change and before Sparkle updates.
    static func save() {
        let detector = ScreenshotDetector()
        let settings = detector.detectSettings()
        let prefs = detector.detectPreferences()

        let snapshot: [String: Any] = [
            "location": settings.location.path,
            "prefix": settings.prefix,
            "format": prefs.format.rawValue,
            "showThumbnail": prefs.showThumbnail,
            "includeCursor": prefs.includeCursor,
            "disableShadow": prefs.disableShadow,
            "includeDate": prefs.includeDate,
            "captureDelay": prefs.captureDelay
        ]

        UserDefaults.standard.set(snapshot, forKey: key)
        UserDefaults.standard.synchronize()

        DebugLogger.shared.log(
            "Saved settings snapshot: location=\(settings.location.path) prefix=\(settings.prefix)",
            category: "Snapshot"
        )
        os_log("Saved settings snapshot: location=%{public}@ prefix=%{public}@",
               log: .default, type: .info,
               settings.location.path, settings.prefix)
    }

    /// Restore settings from snapshot if the current system settings appear
    /// to have been reset (location reverted to ~/Desktop when we know better).
    /// Returns true if settings were restored.
    @discardableResult
    static func restoreIfNeeded(detector: ScreenshotDetector) -> Bool {
        guard let snapshot = UserDefaults.standard.dictionary(forKey: key) else {
            DebugLogger.shared.log("No settings snapshot found, nothing to restore", category: "Snapshot")
            os_log("No settings snapshot found", log: .default, type: .debug)
            return false
        }

        let currentSettings = detector.detectSettings()
        let defaultDesktop = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
        let savedPath = snapshot["location"] as? String ?? defaultDesktop.path

        DebugLogger.shared.log(
            "Checking settings: current=\(currentSettings.location.path) saved=\(savedPath)",
            category: "Snapshot"
        )

        // Determine if settings were reset: current location is default but saved was different
        let currentIsDefault = currentSettings.location.standardizedFileURL == defaultDesktop.standardizedFileURL
        let savedIsCustom = URL(fileURLWithPath: savedPath).standardizedFileURL != defaultDesktop.standardizedFileURL

        guard currentIsDefault && savedIsCustom else {
            DebugLogger.shared.log("Settings look correct, no restore needed", category: "Snapshot")
            os_log("Settings match snapshot, no restore needed", log: .default, type: .debug)
            return false
        }

        // Verify saved directory still exists before restoring
        let savedURL = URL(fileURLWithPath: savedPath)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: savedPath, isDirectory: &isDir),
              isDir.boolValue else {
            DebugLogger.shared.log(
                "Saved location no longer exists: \(savedPath), skipping restore",
                category: "Snapshot"
            )
            os_log("Saved location no longer exists: %{public}@", log: .default, type: .error, savedPath)
            return false
        }

        // Restore all settings
        DebugLogger.shared.log("Restoring settings from snapshot", category: "Snapshot")
        os_log("Restoring settings: location=%{public}@ prefix=%{public}@",
               log: .default, type: .info,
               savedPath, snapshot["prefix"] as? String ?? "Screenshot")

        _ = detector.setSystemLocation(savedURL)

        if let prefix = snapshot["prefix"] as? String, !prefix.isEmpty {
            _ = detector.setPrefix(prefix)
        }
        if let fmt = snapshot["format"] as? String, let format = ScreenshotFormat(rawValue: fmt) {
            _ = detector.setFormat(format)
        }
        if let val = snapshot["showThumbnail"] as? Bool { _ = detector.setShowThumbnail(val) }
        if let val = snapshot["includeCursor"] as? Bool { _ = detector.setIncludeCursor(val) }
        if let val = snapshot["disableShadow"] as? Bool { _ = detector.setDisableShadow(val) }
        if let val = snapshot["includeDate"] as? Bool { _ = detector.setIncludeDate(val) }
        if let val = snapshot["captureDelay"] as? Int { _ = detector.setCaptureDelay(val) }

        _ = ShellExecutor.restartSystemUIServer()

        DebugLogger.shared.log("Settings restored successfully", category: "Snapshot")
        os_log("Settings restored from snapshot", log: .default, type: .info)
        return true
    }
}
