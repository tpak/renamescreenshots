//
//  ShellExecutor.swift
//  ScreenshotRenamer
//
//  Safe shell command execution
//  Swift port of Python subprocess.run()
//

import Foundation
import os.log

/// Utility for safely executing shell commands
class ShellExecutor {

    /// Execute `defaults read` command to read macOS preferences
    /// - Parameters:
    ///   - domain: The defaults domain (e.g., "com.apple.screencapture")
    ///   - key: The preference key (e.g., "location")
    /// - Returns: The output string, or nil if command failed
    static func readDefaults(domain: String, key: String) -> String? {
        do {
            let output = try runCommand(
                executable: "/usr/bin/defaults",
                arguments: ["read", domain, key],
                timeout: 5.0
            )
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            os_log("Failed to read defaults %{public}@.%{public}@: %{public}@",
                   log: .default, type: .debug,
                   domain, key, error.localizedDescription)
            return nil
        }
    }

    /// Execute `defaults write` command to write macOS preferences
    /// - Parameters:
    ///   - domain: The defaults domain (e.g., "com.apple.screencapture")
    ///   - key: The preference key (e.g., "location")
    ///   - value: The value to write
    /// - Returns: True if write succeeded, false otherwise
    static func writeDefaults(domain: String, key: String, value: String) -> Bool {
        do {
            _ = try runCommand(
                executable: "/usr/bin/defaults",
                arguments: ["write", domain, key, value],
                timeout: 5.0
            )
            os_log("Successfully wrote defaults %{public}@.%{public}@ = %{public}@",
                   log: .default, type: .info,
                   domain, key, value)
            return true
        } catch {
            os_log("Failed to write defaults %{public}@.%{public}@: %{public}@",
                   log: .default, type: .error,
                   domain, key, error.localizedDescription)
            return false
        }
    }

    /// Execute `defaults write` command for boolean values
    /// - Parameters:
    ///   - domain: The defaults domain (e.g., "com.apple.screencapture")
    ///   - key: The preference key (e.g., "show-thumbnail")
    ///   - value: Boolean value to write
    /// - Returns: True if write succeeded, false otherwise
    static func writeBoolDefaults(domain: String, key: String, value: Bool) -> Bool {
        do {
            _ = try runCommand(
                executable: "/usr/bin/defaults",
                arguments: ["write", domain, key, "-bool", value ? "true" : "false"],
                timeout: 5.0
            )
            os_log("Successfully wrote bool defaults %{public}@.%{public}@ = %{public}@",
                   log: .default, type: .info,
                   domain, key, value ? "true" : "false")
            return true
        } catch {
            os_log("Failed to write bool defaults %{public}@.%{public}@: %{public}@",
                   log: .default, type: .error,
                   domain, key, error.localizedDescription)
            return false
        }
    }

    /// Restart SystemUIServer to apply screenshot location changes
    /// - Returns: True if restart succeeded, false otherwise
    static func restartSystemUIServer() -> Bool {
        do {
            _ = try runCommand(
                executable: "/usr/bin/killall",
                arguments: ["SystemUIServer"],
                timeout: 5.0
            )
            os_log("Successfully restarted SystemUIServer",
                   log: .default, type: .info)
            return true
        } catch {
            os_log("Failed to restart SystemUIServer: %{public}@",
                   log: .default, type: .debug,
                   error.localizedDescription)
            return false
        }
    }

    /// Run a shell command with timeout
    /// - Parameters:
    ///   - executable: Path to the executable
    ///   - arguments: Command arguments
    ///   - timeout: Timeout in seconds (default 5.0)
    /// - Returns: Standard output as string
    /// - Throws: ScreenshotError.commandFailed if command fails or times out
    private static func runCommand(executable: String, arguments: [String], timeout: TimeInterval = 5.0) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // Use semaphore for timeout instead of polling
        let semaphore = DispatchSemaphore(value: 0)

        process.terminationHandler = { _ in
            semaphore.signal()
        }

        try process.run()

        // Wait for completion with timeout
        let result = semaphore.wait(timeout: .now() + timeout)

        // Check if timed out
        if result == .timedOut {
            process.terminate()
            throw ScreenshotError.commandFailed
        }

        // Check exit status
        guard process.terminationStatus == 0 else {
            throw ScreenshotError.commandFailed
        }

        // Read output
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: outputData, encoding: .utf8) else {
            throw ScreenshotError.commandFailed
        }

        return output
    }
}
