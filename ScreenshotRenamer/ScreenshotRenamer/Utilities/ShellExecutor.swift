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

        try process.run()

        // Wait for completion with timeout
        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.1)
        }

        // Force terminate if still running
        if process.isRunning {
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
