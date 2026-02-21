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
    let includeDate: Bool
    let captureDelay: Int

    init(
        showThumbnail: Bool = true,
        includeCursor: Bool = false,
        disableShadow: Bool = false,
        format: ScreenshotFormat = .png,
        includeDate: Bool = true,
        captureDelay: Int = 0
    ) {
        self.showThumbnail = showThumbnail
        self.includeCursor = includeCursor
        self.disableShadow = disableShadow
        self.format = format
        self.includeDate = includeDate
        self.captureDelay = captureDelay
    }

    /// Default macOS screenshot preferences
    static var defaults: ScreenshotPreferences {
        return ScreenshotPreferences(
            showThumbnail: true,
            includeCursor: false,
            disableShadow: false,
            format: .png,
            includeDate: true,
            captureDelay: 0
        )
    }
}
