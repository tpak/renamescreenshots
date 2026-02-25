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
        os_log("Sparkle willInstallUpdate: %{public}@", log: .default, type: .info,
               item.displayVersionString)
        DebugLogger.shared.log("Sparkle willInstallUpdate: \(item.displayVersionString)",
                               category: "Update")
        SettingsSnapshot.save()
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
