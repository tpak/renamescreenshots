//
//  AppDelegate.swift
//  ScreenshotRenamer
//
//  Application delegate
//

import Cocoa
import os.log

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Screenshot Renamer starting...")
        os_log("Screenshot Renamer starting", log: .default, type: .info)
        let debugStatus = DebugLogger.shared.isEnabled ? "enabled" : "disabled"
        DebugLogger.shared.log("App launching, debug logging \(debugStatus)", category: "App")

        // Initialize menu bar BEFORE setting activation policy
        menuBarController = MenuBarController()
        print("✅ Menu bar controller created")

        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)
        print("✅ Set activation policy to accessory")

        DebugLogger.shared.log("App started", category: "App")
        os_log("Screenshot Renamer started", log: .default, type: .info)
        print("✅ Screenshot Renamer fully initialized")
    }

    func applicationWillTerminate(_ notification: Notification) {
        DebugLogger.shared.log("App shutting down", category: "App")
        os_log("Screenshot Renamer stopping", log: .default, type: .info)
    }

    /// Keep app running when all windows closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
