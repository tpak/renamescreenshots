//
//  MenuBarController.swift
//  ScreenshotRenamer
//
//  Menu bar application controller
//  Swift port of src/menubar_app.py
//

import Cocoa
import os.log

/// Controls the menu bar icon and menu
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var watcher: ScreenshotWatcher?
    private var settings: ScreenshotSettings!
    private var detector: ScreenshotDetector!
    private var isWatcherRunning = false

    // Menu items (strong references)
    private var watcherMenuItem: NSMenuItem!
    private var quickRenameMenuItem: NSMenuItem!
    private var locationMenuItem: NSMenuItem!
    private var prefixMenuItem: NSMenuItem!

    override init() {
        super.init()
        print("📋 MenuBarController initializing...")
        setupMenuBar()
        loadSettings()
        autoStartWatcher()
        print("📋 MenuBarController initialized")
    }

    /// Setup menu bar status item
    private func setupMenuBar() {
        print("🔧 Setting up menu bar...")

        // Create status item
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength
        )
        print("✅ Status item created: \(statusItem != nil)")

        if let button = statusItem.button {
            print("✅ Status item button exists")

            // Use SF Symbol camera icon (macOS 11+)
            if #available(macOS 11.0, *) {
                let config = NSImage.SymbolConfiguration(
                    pointSize: 0,
                    weight: .regular
                )
                button.image = NSImage(
                    systemSymbolName: "camera.fill",
                    accessibilityDescription: "Screenshot Renamer"
                )?.withSymbolConfiguration(config)
                button.image?.isTemplate = true
                print("✅ SF Symbol icon set")
            } else {
                // Fallback for older macOS
                button.title = "📷"
                print("✅ Emoji icon set")
            }
        } else {
            print("❌ ERROR: Status item button is nil!")
        }

        buildMenu()
        print("✅ Menu built and attached")
    }

    /// Build the menu
    private func buildMenu() {
        let menu = NSMenu()

        // Watcher toggle
        watcherMenuItem = NSMenuItem(
            title: "Stop Watcher",
            action: #selector(toggleWatcher),
            keyEquivalent: ""
        )
        watcherMenuItem.target = self
        watcherMenuItem.state = .on // Auto-starts, so initially on
        menu.addItem(watcherMenuItem)

        // Quick rename
        quickRenameMenuItem = NSMenuItem(
            title: "Quick Rename...",
            action: #selector(quickRename),
            keyEquivalent: "r"
        )
        quickRenameMenuItem.target = self
        menu.addItem(quickRenameMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Change location
        let changeLocationItem = NSMenuItem(
            title: "Change Location...",
            action: #selector(changeLocation),
            keyEquivalent: "l"
        )
        changeLocationItem.target = self
        menu.addItem(changeLocationItem)

        menu.addItem(NSMenuItem.separator())

        // Info items (non-clickable)
        locationMenuItem = NSMenuItem(
            title: "Location: ...",
            action: nil,
            keyEquivalent: ""
        )
        menu.addItem(locationMenuItem)

        prefixMenuItem = NSMenuItem(
            title: "Prefix: ...",
            action: nil,
            keyEquivalent: ""
        )
        menu.addItem(prefixMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Screenshot Renamer",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    /// Load screenshot settings from macOS
    private func loadSettings() {
        print("⚙️  Loading settings...")
        detector = ScreenshotDetector()
        settings = detector.detectSettings()
        print("✅ Settings loaded: \(settings.location.path)")
        print("✅ Prefix: \(settings.prefix)")
        updateInfoMenuItems()
    }

    /// Update informational menu items
    private func updateInfoMenuItems() {
        locationMenuItem.title = "Location: \(shortenPath(settings.location.path))"
        prefixMenuItem.title = "Prefix: \(settings.prefix)"
    }

    /// Shorten path for display
    private func shortenPath(_ path: String, maxLength: Int = 40) -> String {
        guard path.count > maxLength else { return path }

        // Replace home directory with ~
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        var shortened = path.replacingOccurrences(of: homeDir, with: "~")

        // Still too long? Truncate middle
        if shortened.count > maxLength {
            let prefix = shortened.prefix(15)
            let suffix = shortened.suffix(20)
            shortened = "\(prefix)...\(suffix)"
        }

        return shortened
    }

    /// Auto-start watcher on launch
    private func autoStartWatcher() {
        do {
            try startWatcher()
            os_log("Auto-started watcher", log: .default, type: .info)
        } catch {
            os_log("Failed to auto-start watcher: %{public}@",
                   log: .default, type: .error, error.localizedDescription)
            Task { @MainActor in
                showAlert(
                    title: "Watcher Error",
                    message: "Failed to start watcher: \(error.localizedDescription)"
                )
            }
        }
    }

    /// Toggle watcher on/off
    @objc private func toggleWatcher() {
        if isWatcherRunning {
            stopWatcher()
            watcherMenuItem.title = "Start Watcher"
            watcherMenuItem.state = .off
            showNotification(
                title: "Watcher Stopped",
                message: "Screenshot watcher has been stopped"
            )
        } else {
            do {
                try startWatcher()
                watcherMenuItem.title = "Stop Watcher"
                watcherMenuItem.state = .on
                showNotification(
                    title: "Watcher Started",
                    message: "Watching: \(shortenPath(settings.location.path))"
                )
            } catch {
                Task { @MainActor in
                    showAlert(
                        title: "Error",
                        message: "Failed to start watcher: \(error.localizedDescription)"
                    )
                }
            }
        }
    }

    /// Start the file watcher
    private func startWatcher() throws {
        guard !isWatcherRunning else { return }

        watcher = ScreenshotWatcher(settings: settings)
        watcher?.startWatching()
        isWatcherRunning = true
    }

    /// Stop the file watcher
    private func stopWatcher() {
        guard isWatcherRunning else { return }

        watcher?.stopWatching()
        watcher = nil
        isWatcherRunning = false
    }

    /// Quick rename existing screenshots
    @objc private func quickRename() {
        Task { @MainActor in
            do {
                let renamer = ScreenshotRenamer(
                    settings: settings,
                    whitelist: [settings.location]
                )

                let result = try await renamer.renameScreenshotsAsync()

                showAlert(
                    title: "Quick Rename Complete",
                    message: result.detailedSummary
                )
            } catch {
                showAlert(
                    title: "Quick Rename Failed",
                    message: error.localizedDescription
                )
            }
        }
    }

    /// Change screenshot location
    @objc private func changeLocation() {
        Task { @MainActor in
            let panel = NSOpenPanel()
            panel.title = "Choose Screenshot Folder"
            panel.message = "Select a folder where screenshots will be saved"
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.canCreateDirectories = true
            panel.allowsMultipleSelection = false
            panel.directoryURL = settings.location // Start at current location

            // Show "Reset to Default" button
            panel.showsResizeIndicator = true
            panel.showsHiddenFiles = false

            let response = panel.runModal()

            if response == .OK, let selectedURL = panel.url {
                // Save custom location
                detector.setCustomLocation(selectedURL)

                // Reload settings
                let wasRunning = isWatcherRunning
                if wasRunning {
                    stopWatcher()
                }

                loadSettings()

                if wasRunning {
                    do {
                        try startWatcher()
                        showNotification(
                            title: "Location Changed",
                            message: "Now watching: \(shortenPath(selectedURL.path))"
                        )
                    } catch {
                        showAlert(
                            title: "Error",
                            message: "Failed to restart watcher: \(error.localizedDescription)"
                        )
                    }
                } else {
                    showAlert(
                        title: "Location Changed",
                        message: "Screenshot location updated to:\n\(selectedURL.path)\n\nStart the watcher to begin monitoring."
                    )
                }

                os_log("Screenshot location changed to: %{public}@",
                       log: .default, type: .info, selectedURL.path)
            }
        }
    }

    /// Quit the application
    @objc private func quit() {
        if isWatcherRunning {
            stopWatcher()
        }
        NSApplication.shared.terminate(self)
    }

    // MARK: - User Notifications

    /// Show macOS notification
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }

    /// Show alert dialog
    @MainActor
    private func showAlert(title: String, message: String) {
        // Activate app to bring alert to front
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
