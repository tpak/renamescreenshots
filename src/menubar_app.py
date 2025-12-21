#!/usr/bin/env python3
"""
macOS Menu Bar Application for Screenshot Renamer.

Primary interface for the tool - provides easy access to:
- Built-in background watcher (start/stop from menu bar)
- Web interface launcher
- Quick rename function
- Settings display

Uses rumps (Ridiculously Uncomplicated macOS Python Statusbar apps)
Licensed under BSD-3-Clause: https://github.com/jaredks/rumps

Includes workarounds for known rumps issues:
- #221, #225: Window/dialog visibility (activation policy switching)
- #222: window.icon freeze (avoid setting custom icons)
- #216: Memory leaks with menu updates (update in-place)
- #213: CLI crash (use safe wrappers)
- #220: Enable/disable menu items (PyObjC direct access)
- #219: Python 3.12+ compatibility (requires rumps >= 0.4.0)
"""

import logging
import threading
import webbrowser
import sys
from typing import Optional

# Check if running on macOS
if sys.platform != 'darwin':
    print("Error: This application only works on macOS")
    sys.exit(1)

try:
    import rumps
except ImportError:
    print("Error: rumps not installed. Install with: pip install 'rumps>=0.4.0'")
    sys.exit(1)

from watchdog.observers import Observer

from .macos_settings import get_screenshot_settings
from .watcher import ScreenshotHandler
from .rename_screenshots import rename_screenshots

logger = logging.getLogger('screenshot_renamer')


class ScreenshotRenamerApp(rumps.App):
    """macOS Menu Bar Application for Screenshot Renamer."""

    def __init__(self):
        """Initialize the menu bar app."""
        # Load macOS screenshot settings
        self.settings = get_screenshot_settings()

        # Initialize app with title (shows in menu bar)
        super().__init__(
            name="Screenshot Renamer",
            icon=None,  # Issue #222: Avoid custom icons to prevent freeze
            quit_button=None  # We'll add our own quit button
        )

        # Threading state
        self.watcher_thread = None
        self.watcher_observer = None
        self.watcher_running = False
        self.watcher_lock = threading.Lock()

        self.flask_thread = None
        self.flask_running = False
        self.flask_lock = threading.Lock()

        # Build menu structure
        self._build_menu()

        # Auto-start Flask in background
        self._start_flask()

    def _build_menu(self):
        """Build the menu bar menu structure."""
        # Menu items (keep references to avoid issue #216 memory leaks)
        self.open_web_item = rumps.MenuItem(
            "Open Web Interface",
            callback=self.open_web_ui
        )

        self.watcher_item = rumps.MenuItem(
            "Start Watcher",
            callback=self.toggle_watcher
        )

        self.quick_rename_item = rumps.MenuItem(
            "Quick Rename...",
            callback=self.quick_rename
        )

        # Info items (non-clickable, just display)
        self.location_item = rumps.MenuItem(
            f"Location: {self._shorten_path(self.settings.location)}",
            callback=None
        )

        self.prefix_item = rumps.MenuItem(
            f"Prefix: {self.settings.prefix}",
            callback=None
        )

        # Quit button
        self.quit_item = rumps.MenuItem(
            "Quit",
            callback=self.quit_app
        )

        # Build menu
        self.menu = [
            self.open_web_item,
            self.watcher_item,
            self.quick_rename_item,
            rumps.separator,
            self.location_item,
            self.prefix_item,
            rumps.separator,
            self.quit_item
        ]

    def _shorten_path(self, path: str, max_len: int = 40) -> str:
        """Shorten a path for display in menu."""
        if len(path) <= max_len:
            return path

        # Replace home directory with ~
        import os
        home = os.path.expanduser("~")
        if path.startswith(home):
            path = "~" + path[len(home):]

        # Still too long? Truncate middle
        if len(path) > max_len:
            # Keep first 15 and last 20 chars
            path = path[:15] + "..." + path[-20:]

        return path

    def _start_flask(self):
        """Start Flask web server in background thread."""
        with self.flask_lock:
            if self.flask_running:
                return

            def run_flask():
                """Run Flask in daemon thread."""
                from . import web_app
                # Suppress Flask startup messages
                import logging as flask_logging
                log = flask_logging.getLogger('werkzeug')
                log.setLevel(flask_logging.ERROR)

                # Run Flask
                web_app.app.run(
                    debug=False,
                    host='127.0.0.1',
                    port=5001,
                    use_reloader=False  # Critical: disable reloader in thread
                )

            self.flask_thread = threading.Thread(
                target=run_flask,
                daemon=True,
                name="FlaskThread"
            )
            self.flask_thread.start()
            self.flask_running = True
            logger.info("Flask web server started on http://localhost:5001")

    def open_web_ui(self, _):
        """Open web interface in default browser."""
        webbrowser.open('http://localhost:5001')
        logger.info("Opened web interface in browser")

    def toggle_watcher(self, sender):
        """Start or stop the background watcher."""
        with self.watcher_lock:
            if self.watcher_running:
                self._stop_watcher()
                # Update menu item
                sender.title = "Start Watcher"
                sender.state = 0  # Remove checkmark

                # Show notification (use safe wrapper for issue #213)
                self._show_notification_safe(
                    "Watcher Stopped",
                    "Screenshot watcher has been stopped"
                )
            else:
                self._start_watcher()
                # Update menu item
                sender.title = "Stop Watcher"
                sender.state = 1  # Add checkmark

                # Show notification
                self._show_notification_safe(
                    "Watcher Started",
                    f"Watching: {self._shorten_path(self.settings.location)}"
                )

    def _start_watcher(self):
        """Start the background file watcher."""
        if self.watcher_running:
            return

        # Create event handler and observer
        event_handler = ScreenshotHandler(
            self.settings.location,
            whitelist=self.settings.get_whitelist_for_location(),
            prefix=self.settings.prefix
        )

        self.watcher_observer = Observer()
        self.watcher_observer.schedule(
            event_handler,
            self.settings.location,
            recursive=False
        )

        # Start observer
        self.watcher_observer.start()
        self.watcher_running = True

        logger.info(f"Watcher started on: {self.settings.location}")
        logger.info(f"Watching for prefix: {self.settings.prefix}")

    def _stop_watcher(self):
        """Stop the background file watcher."""
        if not self.watcher_running:
            return

        if self.watcher_observer:
            self.watcher_observer.stop()
            self.watcher_observer.join(timeout=2)
            self.watcher_observer = None

        self.watcher_running = False
        logger.info("Watcher stopped")

    def quick_rename(self, _):
        """Run quick rename on the screenshot directory."""
        try:
            # Run rename
            total, renamed = rename_screenshots(
                self.settings.location,
                whitelist=self.settings.get_whitelist_for_location(),
                prefix=self.settings.prefix
            )

            # Show results using safe alert (workaround for issues #221, #225)
            message = f"Scanned {total} files\nRenamed {renamed} screenshots"
            self._show_alert_safe("Quick Rename Complete", message)

        except Exception as e:
            logger.error(f"Quick rename failed: {e}")
            self._show_alert_safe("Quick Rename Failed", str(e))

    def _show_notification_safe(self, title: str, message: str):
        """
        Show macOS notification with workaround for rumps issues.

        Workaround for issue #213: rumps.notification can crash when called from CLI.
        This wrapper ensures we're in the right context.
        """
        try:
            rumps.notification(
                title=title,
                subtitle="",
                message=message,
                sound=False
            )
        except Exception as e:
            logger.debug(f"Notification failed (non-critical): {e}")

    def _show_alert_safe(self, title: str, message: str):
        """
        Display alert dialog with workarounds for rumps issues #221, #225.

        Issues:
        - #221: Windows appear behind active windows
        - #225: Dialogs can't accept keyboard input, appear behind windows

        Workaround: Temporarily switch activation policy to bring window to front.
        Source: https://github.com/jaredks/rumps/issues/225
        """
        try:
            from AppKit import (
                NSApp,
                NSApplicationActivationPolicyRegular,
                NSApplicationActivationPolicyAccessory,
            )

            # Save current activation policy
            was_accessory = True

            try:
                # Switch to regular app to make window appear in front
                NSApp.setActivationPolicy_(NSApplicationActivationPolicyRegular)
                NSApp.activateIgnoringOtherApps_(True)

                # Show alert
                response = rumps.alert(
                    title=title,
                    message=message,
                    ok="OK"
                )

                return response

            finally:
                # Restore accessory mode (menu bar app)
                if was_accessory:
                    NSApp.setActivationPolicy_(NSApplicationActivationPolicyAccessory)

        except Exception as e:
            logger.error(f"Alert dialog failed: {e}")
            # Fallback to notification
            self._show_notification_safe(title, message)

    def quit_app(self, _):
        """Quit the application cleanly."""
        # Stop watcher if running
        with self.watcher_lock:
            if self.watcher_running:
                self._stop_watcher()

        # Flask will stop when daemon thread exits
        logger.info("Quitting Screenshot Renamer")
        rumps.quit_application()


def main():
    """Run the menu bar application."""
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(levelname)s:%(name)s: %(message)s'
    )

    logger.info("Starting Screenshot Renamer Menu Bar App")

    # Create and run app
    app = ScreenshotRenamerApp()
    app.run()


if __name__ == '__main__':
    main()
