//
//  UpdateManager.swift
//  ScreenshotRenamer
//
//  Sparkle auto-update integration
//

import Foundation
import Sparkle

/// Manages app updates via Sparkle framework
class UpdateManager {
    let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }
}
