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

    /// Update check interval in seconds
    var updateCheckInterval: TimeInterval {
        get { updaterController.updater.updateCheckInterval }
        set { updaterController.updater.updateCheckInterval = newValue }
    }

    /// Standard interval options
    enum CheckFrequency: TimeInterval, CaseIterable {
        case daily = 86_400
        case weekly = 604_800
        case monthly = 2_592_000

        var title: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            }
        }

        /// Find the closest matching frequency for a given interval
        static func from(interval: TimeInterval) -> CheckFrequency {
            let sorted = allCases.sorted { abs($0.rawValue - interval) < abs($1.rawValue - interval) }
            return sorted.first ?? .weekly
        }
    }
}
