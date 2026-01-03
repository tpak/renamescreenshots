//
//  AppDelegate.swift
//  ScreenshotRenamer
//
//  Application delegate
//

import Cocoa
import os.log

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)

        // Initialize menu bar
        menuBarController = MenuBarController()

        os_log("Screenshot Renamer started", log: .default, type: .info)
    }

    func applicationWillTerminate(_ notification: Notification) {
        os_log("Screenshot Renamer stopping", log: .default, type: .info)
    }

    /// Keep app running when all windows closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
