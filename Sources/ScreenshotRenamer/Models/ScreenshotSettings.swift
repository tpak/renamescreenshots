//
//  ScreenshotSettings.swift
//  ScreenshotRenamer
//
//  Swift port of Python screenshot renamer
//  Original: src/macos_settings.py
//

import Foundation

/// Settings for screenshot location and prefix
struct ScreenshotSettings {
    let location: URL
    let prefix: String

    init(location: URL, prefix: String) {
        self.location = location
        self.prefix = prefix
    }

    /// Get whitelist containing just the screenshot location
    func getWhitelist() -> [URL] {
        return [location]
    }
}
