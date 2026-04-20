# Privacy Review: Screenshot Renamer

This privacy review was conducted by Gemini CLI on Monday, 20 April 2026.

## 1. Networking & External Communication
*   **No `URLSession` Usage:** The codebase contains no direct network calls using `URLSession` or any other networking library.
*   **Sparkle Updates:** The only external communication is through the **Sparkle 2** update framework. It connects only to the developer's GitHub Pages site (`https://tpak.github.io/ScreenshotRenamer/appcast.xml`) to check for new versions.
*   **No "Phone Home" Logic:** There are no hidden background tasks or `curl`/`wget` commands that transmit data to external servers.

## 2. Telemetry & Analytics
*   **Zero Analytics SDKs:** Verified via `Package.swift` and source code; no instances of Firebase, Google Analytics, AppCenter, or other telemetry frameworks are present.
*   **Anonymity:** The app does not collect or transmit any usage statistics or crash reports.

## 3. Data Logging & Privacy
*   **Local-Only Debugging:** The `DebugLogger` utility is **disabled by default**. Even when enabled by the user, logs are stored strictly on the local machine at `~/Library/Logs/ScreenshotRenamer/`.
*   **Log Contents:** While logs may contain file paths (which often include the system username), these logs are never uploaded. Users have full control to clear these logs or change their storage location via the Settings menu.
*   **System Logs:** Uses `os_log` for basic operational status (e.g., "App started", "Renamed file"), which is the standard, secure way to log on macOS.

## 4. System Integration & Permissions
*   **Restricted Shell Commands:** The app only executes `/usr/bin/defaults` and `/usr/bin/killall` to manage macOS-native screenshot preferences. It does not touch other system files or user data.
*   **Launch at Login:** Handled locally by creating a standard Launch Agent `.plist` in the user's home directory.
*   **Notifications:** Standard user permission for notifications to alert when a rename is successful.

## 5. User Control
*   **Settings Persistence:** All settings are stored locally in the application's container or standard macOS preference domains.
*   **Opt-Out Options:** Users can disable automatic update checks and debug logging at any time.

## Conclusion
The application is **privacy-respecting and contains no tracking parts**. It operates as a local utility with the sole exception of the optional (and user-configurable) Sparkle update check.

---
*Conducted by Gemini CLI on April 20, 2026*
