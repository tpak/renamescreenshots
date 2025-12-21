"""
Tests for the file watcher functionality.
Tests ScreenshotHandler event handling and watch_directory integration.
"""
import os
import time
import tempfile
import pytest
from pathlib import Path

from src.watcher import ScreenshotHandler, watch_directory


def create_file(path):
    """Helper to create a test file."""
    with open(path, 'w') as f:
        f.write("test screenshot content")


class TestScreenshotHandler:
    """Tests for ScreenshotHandler class."""

    def test_handler_renames_screenshot_on_creation(self):
        """Handler should rename screenshots when they're created."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create handler
            handler = ScreenshotHandler(tmpdir)

            # Create a screenshot file
            test_file = "Screenshot 2024-05-24 at 1.23.45 PM.png"
            filepath = os.path.join(tmpdir, test_file)
            create_file(filepath)

            # Trigger event
            from watchdog.events import FileCreatedEvent
            event = FileCreatedEvent(filepath)
            handler.on_created(event)

            # Check file was renamed
            expected = "screenshot 2024-05-24 at 13.23.45.png"
            assert os.path.exists(os.path.join(tmpdir, expected))
            assert not os.path.exists(filepath)

    def test_handler_ignores_non_screenshots(self):
        """Handler should ignore files that don't match screenshot pattern."""
        with tempfile.TemporaryDirectory() as tmpdir:
            handler = ScreenshotHandler(tmpdir)

            # Create non-screenshot file
            test_file = "regular_file.txt"
            filepath = os.path.join(tmpdir, test_file)
            create_file(filepath)

            # Trigger event
            from watchdog.events import FileCreatedEvent
            event = FileCreatedEvent(filepath)
            handler.on_created(event)

            # File should remain unchanged
            assert os.path.exists(filepath)

    def test_handler_ignores_directories(self):
        """Handler should ignore directory creation events."""
        with tempfile.TemporaryDirectory() as tmpdir:
            handler = ScreenshotHandler(tmpdir)

            # Create directory
            test_dir = os.path.join(tmpdir, "Screenshot 2024-05-24 at 1.23.45 PM")
            os.makedirs(test_dir)

            # Trigger event for directory
            from watchdog.events import DirCreatedEvent
            event = DirCreatedEvent(test_dir)
            handler.on_created(event)

            # Directory should still exist
            assert os.path.exists(test_dir)

    def test_handler_respects_whitelist(self):
        """Handler should enforce whitelist restrictions."""
        with tempfile.TemporaryDirectory() as allowed_dir:
            with tempfile.TemporaryDirectory() as denied_dir:
                # Create handler with whitelist pointing to different directory
                handler = ScreenshotHandler(denied_dir, whitelist=[allowed_dir])

                # Create screenshot in denied directory
                test_file = "Screenshot 2024-05-24 at 1.23.45 PM.png"
                filepath = os.path.join(denied_dir, test_file)
                create_file(filepath)

                # Trigger event
                from watchdog.events import FileCreatedEvent
                event = FileCreatedEvent(filepath)
                handler.on_created(event)

                # File should not be renamed due to whitelist violation
                # (error is caught and logged, file remains unchanged)
                assert os.path.exists(filepath)

    def test_handler_processes_multiple_screenshots(self):
        """Handler should process multiple screenshot files."""
        with tempfile.TemporaryDirectory() as tmpdir:
            handler = ScreenshotHandler(tmpdir)

            screenshots = [
                "Screenshot 2024-05-24 at 1.23.45 PM.png",
                "Screenshot 2024-05-24 at 2.30.15 AM.jpg",
            ]

            from watchdog.events import FileCreatedEvent

            for screenshot in screenshots:
                filepath = os.path.join(tmpdir, screenshot)
                create_file(filepath)
                event = FileCreatedEvent(filepath)
                handler.on_created(event)

            # Check both files were renamed
            assert os.path.exists(os.path.join(tmpdir, "screenshot 2024-05-24 at 13.23.45.png"))
            assert os.path.exists(os.path.join(tmpdir, "screenshot 2024-05-24 at 02.30.15.jpg"))


class TestWatchDirectory:
    """Tests for watch_directory function."""

    def test_watch_directory_validates_path(self):
        """watch_directory should validate directory before starting."""
        with pytest.raises(FileNotFoundError):
            watch_directory("/nonexistent/path")

    def test_watch_directory_validates_not_a_directory(self):
        """watch_directory should raise error if path is not a directory."""
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            try:
                with pytest.raises(NotADirectoryError):
                    watch_directory(tmp.name)
            finally:
                os.unlink(tmp.name)

    def test_watch_directory_accepts_valid_directory(self):
        """watch_directory should accept valid directory."""
        # This test can't run indefinitely, so we just test that it doesn't
        # raise an error during setup. We'll use a background thread to stop it.
        import threading

        with tempfile.TemporaryDirectory() as tmpdir:
            stop_event = threading.Event()

            def run_watcher():
                try:
                    watch_directory(tmpdir)
                except KeyboardInterrupt:
                    pass

            watcher_thread = threading.Thread(target=run_watcher, daemon=True)
            watcher_thread.start()

            # Give it a moment to start
            time.sleep(0.5)

            # Thread should be running
            assert watcher_thread.is_alive()

            # Clean up: we can't easily send KeyboardInterrupt to thread,
            # but daemon thread will be killed when test ends
