//
//  DebugLogger.swift
//  ScreenshotRenamer
//
//  Debug logging utility for diagnostics
//

import Foundation

/// Singleton debug logger that writes timestamped entries to a log file
class DebugLogger {
    static let shared = DebugLogger()

    private let queue = DispatchQueue(label: "com.screenshot-renamer.debug-logger", qos: .utility)

    private static let enabledKey = "DebugLoggingEnabled"
    private static let logFileURLKey = "DebugLogFileURL"

    /// Whether debug logging is enabled. No-ops when disabled.
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }

    /// Custom log file location. Falls back to default if not set.
    var logFileURL: URL {
        get {
            if let path = UserDefaults.standard.string(forKey: Self.logFileURLKey) {
                return URL(fileURLWithPath: path)
            }
            return Self.defaultLogFileURL
        }
        set {
            UserDefaults.standard.set(newValue.path, forKey: Self.logFileURLKey)
        }
    }

    /// Default log location: ~/Library/Logs/ScreenshotRenamer/debug.log
    static var defaultLogFileURL: URL {
        let logsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/ScreenshotRenamer")
        return logsDir.appendingPathComponent("debug.log")
    }

    private init() {}

    /// Log a message with a category tag
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Category tag (e.g. "PatternMatcher", "Renamer")
    func log(_ message: String, category: String) {
        guard isEnabled else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = "[\(timestamp)] [\(category)] \(message)\n"

        queue.async { [weak self] in
            guard let self = self else { return }
            let url = self.logFileURL

            // Ensure parent directory exists
            let dir = url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

            if FileManager.default.fileExists(atPath: url.path) {
                // Append to existing file
                if let handle = try? FileHandle(forWritingTo: url) {
                    handle.seekToEndOfFile()
                    if let data = entry.data(using: .utf8) {
                        handle.write(data)
                    }
                    handle.closeFile()
                }
            } else {
                // Create new file
                try? entry.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    /// Remove the log file
    func clear() {
        queue.async { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.logFileURL)
        }
    }

    /// Flush pending writes (blocks until queue drains). Useful for tests.
    func flush() {
        queue.sync {}
    }
}
