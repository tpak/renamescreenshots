//
//  ScreenshotPreferences.swift
//  ScreenshotRenamer
//
//  Advanced screenshot preferences from macOS system
//

import Foundation

/// Format for screenshot files
enum ScreenshotFormat: String {
    case png
    case jpg
    case pdf
    case tiff
}

/// Advanced screenshot preferences
struct ScreenshotPreferences {
    let showThumbnail: Bool
    let includeCursor: Bool
    let disableShadow: Bool
    let format: ScreenshotFormat

    init(
        showThumbnail: Bool = true,
        includeCursor: Bool = false,
        disableShadow: Bool = false,
        format: ScreenshotFormat = .png
    ) {
        self.showThumbnail = showThumbnail
        self.includeCursor = includeCursor
        self.disableShadow = disableShadow
        self.format = format
    }

    /// Default macOS screenshot preferences
    static var defaults: ScreenshotPreferences {
        return ScreenshotPreferences(
            showThumbnail: true,
            includeCursor: false,
            disableShadow: false,
            format: .png
        )
    }
}
