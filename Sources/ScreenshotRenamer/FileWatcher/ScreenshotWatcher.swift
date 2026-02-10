//
//  ScreenshotWatcher.swift
//  ScreenshotRenamer
//
//  Watches for new screenshots and automatically renames them
//  Swift port of src/watcher.py using FSEvents
//

import Foundation
import CoreServices
import os.log

/// Watches screenshot directory and automatically renames new screenshots
class ScreenshotWatcher {
    private var streamRef: FSEventStreamRef?
    private let settings: ScreenshotSettings
    private let renamer: ScreenshotRenamer
    private let matcher: PatternMatcher

    private(set) var isRunning = false
    private let processingQueue = DispatchQueue(
        label: "com.screenshot-renamer.processing",
        qos: .utility
    )
    private var debounceWorkItem: DispatchWorkItem?

    /// Initialize watcher with settings
    /// - Parameter settings: Screenshot settings
    init(settings: ScreenshotSettings) {
        self.settings = settings
        self.renamer = ScreenshotRenamer(
            settings: settings,
            whitelist: [settings.location]
        )
        self.matcher = PatternMatcher(prefix: settings.prefix)
    }

    /// Start watching for screenshot changes
    func startWatching() {
        guard !isRunning else { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let paths = [settings.location.path] as CFArray

        // Flags for file-level events
        let flags = UInt32(
            kFSEventStreamCreateFlagUseCFTypes |
            kFSEventStreamCreateFlagFileEvents
        )

        // Create FSEvents stream
        streamRef = FSEventStreamCreate(
            kCFAllocatorDefault,
            { _, contextInfo, _, eventPaths, _, _ in
                let watcher = Unmanaged<ScreenshotWatcher>
                    .fromOpaque(contextInfo!)
                    .takeUnretainedValue()

                // Safety check: only process if watcher is still running
                // Prevents use-after-free if callback fires after stopWatching()
                guard watcher.isRunning else {
                    os_log("FSEvents callback fired after watcher stopped, ignoring",
                           log: .default, type: .debug)
                    return
                }

                // swiftlint:disable:next force_cast
                let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]
                watcher.handleFileEvents(paths)
            },
            &context,
            paths,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.1, // 100ms latency
            flags
        )

        // Schedule on main run loop
        FSEventStreamScheduleWithRunLoop(
            streamRef!,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )

        // Start the stream
        FSEventStreamStart(streamRef!)
        isRunning = true

        DebugLogger.shared.log("Started watching: \(settings.location.path)", category: "Watcher")
        os_log("Started watching: %{public}@",
               log: .default, type: .info, settings.location.path)
    }

    /// Stop watching for changes
    func stopWatching() {
        guard isRunning, let stream = streamRef else { return }

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
        isRunning = false

        // Cancel any pending debounced rename and wait for in-flight operations
        processingQueue.sync {
            self.debounceWorkItem?.cancel()
            self.debounceWorkItem = nil
        }

        DebugLogger.shared.log("Stopped watching", category: "Watcher")
        os_log("Stopped watching", log: .default, type: .info)
    }

    /// Handle file system events with debouncing
    ///
    /// Rapid FSEvents (temp files, multiple screenshots) are coalesced into a single
    /// rename operation. Each event resets a 300ms timer; when it fires, one full scan
    /// runs. This prevents concurrent scans from racing on the same files.
    /// - Parameter paths: Paths of changed files
    private func handleFileEvents(_ paths: [String]) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }

            var hasMatch = false
            for path in paths {
                let url = URL(fileURLWithPath: path)
                let filename = url.lastPathComponent

                // Skip hidden files (macOS creates .Screenshot first)
                guard !filename.hasPrefix(".") else {
                    DebugLogger.shared.log("Skipped hidden file: \(filename)", category: "Watcher")
                    continue
                }

                // Check if it matches screenshot pattern
                guard self.matcher.match(filename) != nil else {
                    continue
                }

                DebugLogger.shared.log("Detected screenshot: \(filename)", category: "Watcher")
                os_log("Detected screenshot: %{public}@",
                       log: .default, type: .info, filename)
                hasMatch = true
            }

            guard hasMatch else { return }

            // Cancel any previously scheduled rename — we'll reschedule with a fresh delay
            self.debounceWorkItem?.cancel()

            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                do {
                    let result = try self.renamer.renameScreenshots()
                    if result.renamedFiles > 0 {
                        DebugLogger.shared.log(
                            "Auto-renamed \(result.renamedFiles) file(s)",
                            category: "Watcher"
                        )
                        os_log("Auto-renamed: %d files",
                               log: .default, type: .info, result.renamedFiles)
                    }
                } catch {
                    os_log("Error renaming screenshots: %{public}@",
                           log: .default, type: .error, error.localizedDescription)
                }
            }

            self.debounceWorkItem = workItem
            // 300ms delay: lets macOS finish writing the file and coalesces rapid events
            self.processingQueue.asyncAfter(
                deadline: .now() + 0.3,
                execute: workItem
            )
        }
    }

    deinit {
        stopWatching()
    }
}
