#!/usr/bin/env python3
"""
macOS screenshot settings detection.
Provides utilities to read macOS screenshot configuration using the defaults command.
"""

import subprocess
import logging
import os
from typing import Optional, Tuple, List
from pathlib import Path

logger = logging.getLogger('screenshot_renamer')


class ScreenshotSettings:
    """
    Cached macOS screenshot settings.

    Reads screenshot configuration from macOS defaults (com.apple.screencapture).
    Provides safe fallbacks when settings aren't configured.
    """

    def __init__(self):
        self._location: Optional[str] = None
        self._prefix: Optional[str] = None
        self._loaded = False

    def load_settings(self) -> Tuple[str, str]:
        """
        Load macOS screenshot settings from system defaults.

        Returns:
            Tuple[str, str]: (location, prefix)
                location: Screenshot save directory path
                prefix: Screenshot filename prefix

        Raises:
            No exceptions - always returns valid defaults
        """
        if self._loaded:
            return self._location, self._prefix

        self._location = self._read_location()
        self._prefix = self._read_prefix()
        self._loaded = True

        logger.info(f"Detected screenshot location: {self._location}")
        logger.info(f"Detected screenshot prefix: {self._prefix}")

        return self._location, self._prefix

    def _read_location(self) -> str:
        """
        Read screenshot save location from macOS defaults.

        Returns:
            str: Absolute path to screenshot directory
        """
        try:
            result = subprocess.run(
                ['defaults', 'read', 'com.apple.screencapture', 'location'],
                capture_output=True,
                text=True,
                timeout=5,
                check=False  # Don't raise on non-zero exit
            )

            if result.returncode == 0 and result.stdout.strip():
                location = result.stdout.strip()
                # Expand user path if needed
                location = os.path.expanduser(location)
                # Convert to absolute path
                location = os.path.abspath(location)

                # Verify directory exists
                if os.path.isdir(location):
                    return location
                else:
                    logger.warning(f"Screenshot location does not exist: {location}")

        except (subprocess.TimeoutExpired, subprocess.SubprocessError, OSError) as e:
            logger.debug(f"Failed to read screenshot location: {e}")

        # Default fallback
        default = os.path.expanduser("~/Desktop")
        logger.debug(f"Using default location: {default}")
        return default

    def _read_prefix(self) -> str:
        """
        Read custom screenshot prefix from macOS defaults.

        Returns:
            str: Screenshot filename prefix (default: "Screenshot")
        """
        try:
            result = subprocess.run(
                ['defaults', 'read', 'com.apple.screencapture', 'name'],
                capture_output=True,
                text=True,
                timeout=5,
                check=False  # Don't raise on non-zero exit
            )

            if result.returncode == 0 and result.stdout.strip():
                prefix = result.stdout.strip()
                logger.debug(f"Detected custom prefix: {prefix}")
                return prefix

        except (subprocess.TimeoutExpired, subprocess.SubprocessError, OSError) as e:
            logger.debug(f"No custom prefix set: {e}")

        # Default prefix
        return "Screenshot"

    @property
    def location(self) -> str:
        """
        Get screenshot location (loads settings if not already loaded).

        Returns:
            str: Absolute path to screenshot directory
        """
        if not self._loaded:
            self.load_settings()
        return self._location

    @property
    def prefix(self) -> str:
        """
        Get screenshot prefix (loads settings if not already loaded).

        Returns:
            str: Screenshot filename prefix
        """
        if not self._loaded:
            self.load_settings()
        return self._prefix

    def get_whitelist_for_location(self) -> List[str]:
        """
        Get whitelist that includes the detected screenshot location.

        Useful for auto-whitelisting the screenshot directory for security.

        Returns:
            List[str]: Whitelist containing only the screenshot location
        """
        return [self.location]

    def reload(self):
        """
        Force reload of settings from macOS defaults.

        Useful if settings have changed since initial load.
        """
        self._loaded = False
        self.load_settings()


# Global instance (singleton pattern)
_settings = ScreenshotSettings()


def get_screenshot_settings() -> ScreenshotSettings:
    """
    Get the global screenshot settings instance.

    Returns:
        ScreenshotSettings: Singleton settings instance

    Example:
        >>> settings = get_screenshot_settings()
        >>> location, prefix = settings.load_settings()
        >>> print(f"Screenshots saved to: {location}")
        >>> print(f"Prefix: {prefix}")
    """
    return _settings
