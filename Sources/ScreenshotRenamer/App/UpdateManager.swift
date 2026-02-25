//
//  UpdateManager.swift
//  ScreenshotRenamer
//
//  Sparkle auto-update integration
//

import Foundation
import Sparkle
import os.log

/// Handles Sparkle updater delegate callbacks
private class UpdateDelegate: NSObject, SPUUpdaterDelegate {
    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
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

        UserDefaults.standard.set(snapshot, forKey: "preUpdateSettings")
        os_log("Saved settings snapshot before update", log: .default, type: .info)
    }
}

/// Manages app updates via Sparkle framework
class UpdateManager {
    let updaterController: SPUStandardUpdaterController
    private let delegate = UpdateDelegate()

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: delegate,
            userDriverDelegate: nil
        )
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }
}
