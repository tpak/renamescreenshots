//
//  MenuBarController.swift
//  ScreenshotRenamer
//
//  Menu bar application controller
//  Swift port of src/menubar_app.py
//

import Cocoa
import UserNotifications
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
    private var launchAtLoginMenuItem: NSMenuItem!
    private var locationMenuItem: NSMenuItem!
    private var prefixMenuItem: NSMenuItem!

    // Settings submenu items
    private var showThumbnailMenuItem: NSMenuItem!
    private var includeCursorMenuItem: NSMenuItem!
    private var disableShadowMenuItem: NSMenuItem!
    private var formatMenuItems: [ScreenshotFormat: NSMenuItem] = [:]

    override init() {
        super.init()
        print("📋 MenuBarController initializing...")

        // Initialize detector first (needed by buildMenu)
        detector = ScreenshotDetector()

        setupMenuBar()
        requestNotificationPermissions()
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

        // Screenshot Settings submenu
        let settingsSubmenu = buildSettingsSubmenu()
        let settingsMenuItem = NSMenuItem(
            title: "Screenshot Settings",
            action: nil,
            keyEquivalent: ""
        )
        settingsMenuItem.submenu = settingsSubmenu
        menu.addItem(settingsMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Launch at Login toggle
        launchAtLoginMenuItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginMenuItem.target = self
        launchAtLoginMenuItem.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        menu.addItem(launchAtLoginMenuItem)

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

    /// Build the screenshot settings submenu
    private func buildSettingsSubmenu() -> NSMenu {
        let submenu = NSMenu()

        // Detect current preferences
        let prefs = detector.detectPreferences()

        // Show Thumbnail Preview toggle
        showThumbnailMenuItem = NSMenuItem(
            title: "Show Thumbnail Preview",
            action: #selector(toggleShowThumbnail),
            keyEquivalent: ""
        )
        showThumbnailMenuItem.target = self
        showThumbnailMenuItem.state = prefs.showThumbnail ? .on : .off
        submenu.addItem(showThumbnailMenuItem)

        // Include Mouse Pointer toggle
        includeCursorMenuItem = NSMenuItem(
            title: "Include Mouse Pointer",
            action: #selector(toggleIncludeCursor),
            keyEquivalent: ""
        )
        includeCursorMenuItem.target = self
        includeCursorMenuItem.state = prefs.includeCursor ? .on : .off
        submenu.addItem(includeCursorMenuItem)

        // Disable Window Shadow toggle
        disableShadowMenuItem = NSMenuItem(
            title: "Disable Window Shadow",
            action: #selector(toggleDisableShadow),
            keyEquivalent: ""
        )
        disableShadowMenuItem.target = self
        disableShadowMenuItem.state = prefs.disableShadow ? .on : .off
        submenu.addItem(disableShadowMenuItem)

        submenu.addItem(NSMenuItem.separator())

        // Screenshot Format submenu
        let formatSubmenu = NSMenu()
        let formats: [ScreenshotFormat] = [.png, .jpg, .pdf, .tiff]

        for format in formats {
            let formatItem = NSMenuItem(
                title: format.rawValue.uppercased(),
                action: #selector(setScreenshotFormat(_:)),
                keyEquivalent: ""
            )
            formatItem.target = self
            formatItem.representedObject = format
            formatItem.state = (format == prefs.format) ? .on : .off
            formatSubmenu.addItem(formatItem)
            formatMenuItems[format] = formatItem
        }

        let formatMenuItem = NSMenuItem(
            title: "Screenshot Format",
            action: nil,
            keyEquivalent: ""
        )
        formatMenuItem.submenu = formatSubmenu
        submenu.addItem(formatMenuItem)

        submenu.addItem(NSMenuItem.separator())

        // Reset to Defaults
        let resetItem = NSMenuItem(
            title: "Reset to Defaults",
            action: #selector(resetScreenshotSettings),
            keyEquivalent: ""
        )
        resetItem.target = self
        submenu.addItem(resetItem)

        return submenu
    }

    /// Load screenshot settings from macOS
    private func loadSettings() {
        print("⚙️  Loading settings...")
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
            panel.message = "Select where system screenshots (⌘⇧4) will be saved"
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
                // Change system screenshot location
                guard detector.setSystemLocation(selectedURL) else {
                    showAlert(
                        title: "Error",
                        message: "Failed to change system screenshot location. Please check permissions."
                    )
                    return
                }

                // Restart SystemUIServer to apply changes
                _ = ShellExecutor.restartSystemUIServer()

                // Stop watcher before reloading settings
                let wasRunning = isWatcherRunning
                if wasRunning {
                    stopWatcher()
                }

                // Reload settings (will now read from updated system location)
                loadSettings()

                // Restart watcher with new location
                if wasRunning {
                    do {
                        try startWatcher()
                        showNotification(
                            title: "System Location Changed",
                            message: "Screenshots will now save to: \(shortenPath(selectedURL.path))"
                        )
                    } catch {
                        showAlert(
                            title: "Error",
                            message: "Failed to restart watcher: \(error.localizedDescription)"
                        )
                    }
                } else {
                    showAlert(
                        title: "System Location Changed",
                        message: "System screenshot location updated to:\n\(selectedURL.path)\n\nNew screenshots (⌘⇧4) will save here.\n\nStart the watcher to begin monitoring."
                    )
                }

                os_log("System screenshot location changed to: %{public}@",
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

    /// Toggle launch at login
    @objc private func toggleLaunchAtLogin() {
        let result = LaunchAtLoginManager.shared.toggle()

        switch result {
        case .success(let isEnabled):
            launchAtLoginMenuItem.state = isEnabled ? .on : .off
            showNotification(
                title: "Launch at Login \(isEnabled ? "Enabled" : "Disabled")",
                message: isEnabled
                    ? "Screenshot Renamer will launch automatically when you log in"
                    : "Screenshot Renamer will not launch automatically"
            )
            os_log("Launch at login %{public}@",
                   log: .default, type: .info, isEnabled ? "enabled" : "disabled")

        case .failure(let error):
            Task { @MainActor in
                showAlert(
                    title: "Launch at Login Error",
                    message: error.localizedDescription
                )
            }
            os_log("Failed to toggle launch at login: %{public}@",
                   log: .default, type: .error, error.localizedDescription)
        }
    }

    // MARK: - Screenshot Settings Actions

    /// Toggle show thumbnail preview
    @objc private func toggleShowThumbnail() {
        let currentState = showThumbnailMenuItem.state == .on
        let newState = !currentState

        guard detector.setShowThumbnail(newState) else {
            Task { @MainActor in
                showAlert(
                    title: "Error",
                    message: "Failed to change thumbnail preview setting"
                )
            }
            return
        }

        showThumbnailMenuItem.state = newState ? .on : .off
        _ = ShellExecutor.restartSystemUIServer()

        showNotification(
            title: "Thumbnail Preview \(newState ? "Enabled" : "Disabled")",
            message: newState
                ? "Screenshots will show preview thumbnail"
                : "Screenshots will save immediately"
        )
    }

    /// Toggle include cursor in screenshots
    @objc private func toggleIncludeCursor() {
        let currentState = includeCursorMenuItem.state == .on
        let newState = !currentState

        guard detector.setIncludeCursor(newState) else {
            Task { @MainActor in
                showAlert(
                    title: "Error",
                    message: "Failed to change cursor setting"
                )
            }
            return
        }

        includeCursorMenuItem.state = newState ? .on : .off
        _ = ShellExecutor.restartSystemUIServer()

        showNotification(
            title: "Mouse Pointer \(newState ? "Enabled" : "Disabled")",
            message: newState
                ? "Screenshots will include the mouse pointer"
                : "Screenshots will not include the mouse pointer"
        )
    }

    /// Toggle disable shadow on window screenshots
    @objc private func toggleDisableShadow() {
        let currentState = disableShadowMenuItem.state == .on
        let newState = !currentState

        guard detector.setDisableShadow(newState) else {
            Task { @MainActor in
                showAlert(
                    title: "Error",
                    message: "Failed to change shadow setting"
                )
            }
            return
        }

        disableShadowMenuItem.state = newState ? .on : .off
        _ = ShellExecutor.restartSystemUIServer()

        showNotification(
            title: "Window Shadow \(newState ? "Disabled" : "Enabled")",
            message: newState
                ? "Window screenshots will not have drop shadow"
                : "Window screenshots will have drop shadow"
        )
    }

    /// Set screenshot format
    @objc private func setScreenshotFormat(_ sender: NSMenuItem) {
        guard let format = sender.representedObject as? ScreenshotFormat else {
            return
        }

        guard detector.setFormat(format) else {
            Task { @MainActor in
                showAlert(
                    title: "Error",
                    message: "Failed to change screenshot format"
                )
            }
            return
        }

        // Update checkmarks
        for (formatKey, menuItem) in formatMenuItems {
            menuItem.state = (formatKey == format) ? .on : .off
        }

        _ = ShellExecutor.restartSystemUIServer()

        showNotification(
            title: "Format Changed",
            message: "Screenshots will now save as \(format.rawValue.uppercased())"
        )
    }

    /// Reset all screenshot settings to macOS defaults
    @objc private func resetScreenshotSettings() {
        Task { @MainActor in
            let alert = NSAlert()
            alert.messageText = "Reset Screenshot Settings?"
            alert.informativeText = "This will reset all screenshot preferences to macOS defaults:\n• Show thumbnail preview: ON\n• Include mouse pointer: OFF\n• Window shadow: ON\n• Format: PNG"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Reset")
            alert.addButton(withTitle: "Cancel")

            NSApp.activate(ignoringOtherApps: true)
            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                guard detector.resetToDefaults() else {
                    showAlert(
                        title: "Error",
                        message: "Failed to reset screenshot settings"
                    )
                    return
                }

                // Update menu items to reflect defaults
                let defaults = ScreenshotPreferences.defaults
                showThumbnailMenuItem.state = defaults.showThumbnail ? .on : .off
                includeCursorMenuItem.state = defaults.includeCursor ? .on : .off
                disableShadowMenuItem.state = defaults.disableShadow ? .on : .off

                for (formatKey, menuItem) in formatMenuItems {
                    menuItem.state = (formatKey == defaults.format) ? .on : .off
                }

                showNotification(
                    title: "Settings Reset",
                    message: "All screenshot preferences restored to defaults"
                )
            }
        }
    }

    // MARK: - User Notifications

    /// Request notification permissions
    private func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                os_log("Notification permission error: %{public}@",
                       log: .default, type: .debug, error.localizedDescription)
            }
        }
    }

    /// Show macOS notification using modern UserNotifications framework
    private func showNotification(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = nil

        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                os_log("Failed to show notification: %{public}@",
                       log: .default, type: .debug, error.localizedDescription)
            }
        }
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
