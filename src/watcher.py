#!/usr/bin/env python3
"""
Background file watcher for automatic screenshot renaming.
Monitors a directory and renames screenshots as they appear.
"""

import logging
import re
import time
from pathlib import Path
from typing import Optional, List

from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

from .rename_screenshots import rename_screenshots

logger = logging.getLogger('screenshot_renamer')


class ScreenshotHandler(FileSystemEventHandler):
    """Handles file system events for screenshot renaming."""

    def __init__(self, directory: str, whitelist: Optional[List[str]] = None):
        """
        Initialize the screenshot handler.

        Args:
            directory: Directory being watched
            whitelist: Optional list of allowed directories
        """
        self.directory = directory
        self.whitelist = whitelist
        self.pattern = re.compile(
            r"Screenshot (\d{4}-\d{2}-\d{2}) at (\d{1,2})\.(\d{2})\.(\d{2})\s*([APMapm]{2})\.(\w+)",
            re.IGNORECASE
        )

    def on_created(self, event):
        """
        Handle file creation events.

        Args:
            event: FileSystemEvent containing information about the created file
        """
        if event.is_directory:
            return

        # Get filename from path
        filepath = Path(event.src_path)
        filename = filepath.name

        # Check if it matches screenshot pattern
        if self.pattern.match(filename):
            # Small delay to ensure file is fully written
            time.sleep(0.1)

            try:
                # Process just this file's directory
                logger.info(f"Detected new screenshot: {filename}")
                total, renamed = rename_screenshots(
                    str(filepath.parent),
                    whitelist=self.whitelist
                )
                if renamed > 0:
                    logger.info(f"Auto-renamed screenshot")
            except Exception as e:
                logger.error(f"Error processing {filename}: {e}")


def watch_directory(directory: str, whitelist: Optional[List[str]] = None):
    """
    Watch a directory for new screenshots and rename them automatically.

    Args:
        directory: Directory to watch
        whitelist: Optional list of allowed directories

    Runs indefinitely until interrupted (Ctrl+C).

    Raises:
        ValueError: If the directory path is invalid
        FileNotFoundError: If the directory doesn't exist
        NotADirectoryError: If the path is not a directory
        PermissionError: If insufficient permissions or directory not in whitelist
    """
    from .rename_screenshots import validate_directory

    # Validate directory before starting watcher
    validated_dir = validate_directory(directory, whitelist=whitelist)

    logger.info(f"Starting screenshot watcher on: {validated_dir}")
    logger.info("Press Ctrl+C to stop")

    # Create event handler and observer
    event_handler = ScreenshotHandler(validated_dir, whitelist=whitelist)
    observer = Observer()
    observer.schedule(event_handler, validated_dir, recursive=False)

    # Start observer
    observer.start()

    try:
        # Keep running until interrupted
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        logger.info("Stopping screenshot watcher...")
        observer.stop()

    observer.join()
    logger.info("Watcher stopped")
