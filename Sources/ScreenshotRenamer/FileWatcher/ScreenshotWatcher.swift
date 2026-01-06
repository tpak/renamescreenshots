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
            { (streamRef, contextInfo, numEvents, eventPaths, eventFlags, eventIds) in
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

        // Wait for any pending operations in the processing queue to complete
        // This prevents race conditions where old tasks process with stale settings
        processingQueue.sync {
            // Barrier: ensures all previously queued async tasks complete
        }

        os_log("Stopped watching", log: .default, type: .info)
    }

    /// Handle file system events
    /// - Parameter paths: Paths of changed files
    private func handleFileEvents(_ paths: [String]) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }

            for path in paths {
                let url = URL(fileURLWithPath: path)
                let filename = url.lastPathComponent

                // Skip hidden files (macOS creates .Screenshot first)
                guard !filename.hasPrefix(".") else {
                    continue
                }

                // Check if it matches screenshot pattern
                guard self.matcher.match(filename) != nil else {
                    continue
                }

                os_log("Detected screenshot: %{public}@",
                       log: .default, type: .info, filename)

                // Small delay to ensure file is fully written
                // macOS creates .Screenshot then renames to Screenshot
                // Use Task.sleep instead of Thread.sleep to avoid blocking
                Task {
                    try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds

                    do {
                        let result = try self.renamer.renameScreenshots()
                        if result.renamedFiles > 0 {
                            os_log("Auto-renamed: %d files",
                                   log: .default, type: .info, result.renamedFiles)
                        }
                    } catch {
                        os_log("Error processing %{public}@: %{public}@",
                               log: .default, type: .error, filename, error.localizedDescription)
                    }
                }
            }
        }
    }

    deinit {
        stopWatching()
    }
}
