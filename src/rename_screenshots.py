#!/usr/bin/env python3
import argparse
import logging
import os
import re
from datetime import datetime
from pathlib import Path
from typing import Tuple, Optional, List

# Create a custom logger for this module
logger = logging.getLogger('screenshot_renamer')

# Default whitelist - None means allow all directories
# Can be overridden via environment variable SCREENSHOT_RENAMER_WHITELIST
DEFAULT_WHITELIST = None


def build_screenshot_pattern(prefix: str = "Screenshot") -> re.Pattern:
    """
    Build a regex pattern for matching screenshot filenames with custom prefix.

    Args:
        prefix: The screenshot prefix to match (e.g., "Screenshot", "MyScreenshot").
                Special regex characters will be escaped automatically.

    Returns:
        re.Pattern: Compiled regex pattern for matching screenshot filenames

    Example:
        >>> pattern = build_screenshot_pattern("Screenshot")
        >>> match = pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.png")
        >>> match is not None
        True
        >>> pattern = build_screenshot_pattern("MyScreenshot")
        >>> pattern.match("MyScreenshot 2024-05-24 at 1.23.45 PM.png") is not None
        True
    """
    # Escape prefix for use in regex (handles special characters like dots)
    escaped_prefix = re.escape(prefix)

    # Build pattern string
    # Format: Prefix YYYY-MM-DD at H.MM.SS AM/PM.ext
    pattern_str = (
        rf"{escaped_prefix} "
        r"(\d{4}-\d{2}-\d{2}) at "
        r"(\d{1,2})\.(\d{2})\.(\d{2})\s*"
        r"([APMapm]{2})\."
        r"(\w+)"
    )

    return re.compile(pattern_str, re.IGNORECASE)


def sanitize_filename(filename: str) -> str:
    """
    Sanitize a filename to prevent path traversal and other security issues.

    Args:
        filename (str): The filename to sanitize

    Returns:
        str: The sanitized filename

    Raises:
        ValueError: If the filename is invalid or contains unsafe characters
    """
    if not filename or not filename.strip():
        raise ValueError("Filename cannot be empty")

    # Check for null bytes
    if '\0' in filename:
        raise ValueError("Filename contains null bytes")

    # Check for path separators (prevent path traversal)
    if os.sep in filename or (os.altsep and os.altsep in filename):
        raise ValueError(f"Filename contains path separators: {filename}")

    # Check for path traversal attempts
    if filename in ('.', '..') or filename.startswith('..') or '/..' in filename or '\\..' in filename:
        raise ValueError(f"Filename contains path traversal attempt: {filename}")

    # Check for control characters
    if any(ord(c) < 32 for c in filename):
        raise ValueError("Filename contains control characters")

    return filename


def validate_directory(directory: str, whitelist: Optional[List[str]] = None) -> str:
    """
    Validate and sanitize the directory path.

    Args:
        directory (str): The directory path to validate
        whitelist (Optional[List[str]]): List of allowed directory paths.
                                        If None, all directories are allowed.
                                        Paths in whitelist should be absolute.

    Returns:
        str: The absolute, normalized path

    Raises:
        ValueError: If the path is invalid or unsafe
        FileNotFoundError: If the directory doesn't exist
        NotADirectoryError: If the path exists but is not a directory
        PermissionError: If directory is not in whitelist or insufficient permissions
    """
    if not directory or not directory.strip():
        raise ValueError("Directory path cannot be empty")

    # Expand user home directory and environment variables
    expanded_path = os.path.expanduser(os.path.expandvars(directory))

    # Convert to absolute path and resolve symlinks
    try:
        absolute_path = os.path.abspath(expanded_path)
        real_path = os.path.realpath(absolute_path)
    except (OSError, ValueError) as e:
        raise ValueError(f"Invalid directory path: {e}")

    # Check if path exists
    if not os.path.exists(real_path):
        raise FileNotFoundError(f"Directory does not exist: {directory}")

    # Check if path is a directory
    if not os.path.isdir(real_path):
        raise NotADirectoryError(f"Path is not a directory: {directory}")

    # Check if we have read and write permissions
    if not os.access(real_path, os.R_OK):
        raise PermissionError(f"No read permission for directory: {directory}")

    if not os.access(real_path, os.W_OK):
        raise PermissionError(f"No write permission for directory: {directory}")

    # Check whitelist if provided
    if whitelist is not None:
        # Normalize whitelist paths
        normalized_whitelist = [os.path.realpath(os.path.expanduser(p)) for p in whitelist]

        # Check if the real_path is in the whitelist or is a subdirectory of a whitelisted path
        is_allowed = any(
            real_path == allowed_path or real_path.startswith(allowed_path + os.sep)
            for allowed_path in normalized_whitelist
        )

        if not is_allowed:
            logger.warning(f"Directory not in whitelist: {real_path}")
            raise PermissionError(
                f"Directory not allowed. Path '{directory}' is not in the whitelist of permitted directories."
            )

        logger.info(f"Directory approved by whitelist: {real_path}")

    logger.info(f"Validated directory: {real_path}")
    return real_path


def validate_file_path(filepath: str, base_directory: str) -> str:
    """
    Validate that a file path is within the base directory.

    Args:
        filepath (str): The file path to validate
        base_directory (str): The base directory that the file must be within

    Returns:
        str: The validated absolute file path

    Raises:
        ValueError: If the file path is outside the base directory
    """
    # Get the real paths (resolve symlinks)
    real_filepath = os.path.realpath(filepath)
    real_base = os.path.realpath(base_directory)

    # Ensure the file path is within the base directory
    # Use os.path.commonpath to check if they share the same base
    try:
        common = os.path.commonpath([real_filepath, real_base])
        if common != real_base:
            raise ValueError(f"File path is outside base directory: {filepath}")
    except ValueError:
        # Different drives on Windows or other path issues
        raise ValueError(f"File path is outside base directory: {filepath}")

    return real_filepath


def rename_screenshots(
    directory: str,
    whitelist: Optional[List[str]] = None,
    prefix: Optional[str] = None
) -> Tuple[int, int]:
    """
    Rename screenshot files in the specified directory to a consistent format.

    Args:
        directory (str): The directory containing the screenshot files.
        whitelist (Optional[List[str]]): Optional list of allowed directories.
                                        If provided, only these directories (and subdirectories)
                                        can be processed. If None, all directories are allowed.
        prefix (Optional[str]): Screenshot filename prefix to match (e.g., "Screenshot", "MyScreenshot").
                               If None, auto-detects from macOS settings.

    Returns:
        Tuple[int, int]: (total matching files, renamed files)

    Raises:
        ValueError: If the directory path is invalid
        FileNotFoundError: If the directory doesn't exist
        NotADirectoryError: If the path is not a directory
        PermissionError: If insufficient permissions or directory not in whitelist
    """
    # Load whitelist from environment if not provided and environment variable is set
    if whitelist is None:
        env_whitelist = os.environ.get('SCREENSHOT_RENAMER_WHITELIST')
        if env_whitelist:
            # Parse colon-separated paths from environment variable
            whitelist = [p.strip() for p in env_whitelist.split(':') if p.strip()]
            logger.info(f"Loaded whitelist from environment: {whitelist}")

    # Auto-detect prefix from macOS settings if not provided
    if prefix is None:
        from .macos_settings import get_screenshot_settings
        settings = get_screenshot_settings()
        prefix = settings.prefix
        logger.info(f"Auto-detected screenshot prefix: {prefix}")

    # Validate the directory first
    validated_dir = validate_directory(directory, whitelist=whitelist)

    total_files = 0
    renamed_files = 0

    # Build pattern for the specified prefix
    pattern = build_screenshot_pattern(prefix)

    for filename in os.listdir(validated_dir):
        total_files += 1  # Count every file in the directory
        match = pattern.match(filename)
        if match:
            try:
                # Sanitize the original filename
                sanitize_filename(filename)

                date, hour, minute, second, period, extension = match.groups()
                hour = int(hour)
                period = period.upper()
                if period == "PM" and hour != 12:
                    hour += 12
                elif period == "AM" and hour == 12:
                    hour = 0

                # Preserve the custom prefix (lowercase)
                prefix_lower = prefix.lower()
                new_filename = (
                    f"{prefix_lower} {date} at {hour:02}.{minute}.{second}.{extension}"
                )

                # Sanitize the new filename
                sanitize_filename(new_filename)

                # Build file paths
                old_filepath = os.path.join(validated_dir, filename)
                new_filepath = os.path.join(validated_dir, new_filename)

                # Validate both paths are within the base directory
                validate_file_path(old_filepath, validated_dir)
                validate_file_path(new_filepath, validated_dir)

                # Check if target file already exists to prevent accidental overwrites
                if os.path.exists(new_filepath):
                    logger.warning(f"Skipping rename: target file already exists: {new_filename}")
                    continue

                # Perform the rename
                logger.info(f"Renaming {filename} to {new_filename}")
                os.rename(old_filepath, new_filepath)
                logger.info(f"Successfully renamed to {new_filename}")
                renamed_files += 1

            except ValueError as e:
                logger.error(f"Validation error for {filename}: {e}")
            except OSError as e:
                logger.error(f"Error renaming {filename}: {e}")

    return total_files, renamed_files


def rename_screenshots_streaming(
    directory: str,
    whitelist: Optional[List[str]] = None,
    prefix: Optional[str] = None
):
    """
    Generator version of rename_screenshots that yields progress events.

    This function performs the same operations as rename_screenshots() but yields
    progress events for each file operation, enabling real-time feedback in the UI.

    Args:
        directory (str): The directory containing the screenshot files.
        whitelist (Optional[List[str]]): Optional list of allowed directories.
        prefix (Optional[str]): Screenshot filename prefix to match (e.g., "Screenshot", "MyScreenshot").
                               If None, auto-detects from macOS settings.

    Yields:
        dict: Progress events with keys:
            - event: Event type ('start', 'rename', 'skip', 'error', 'complete')
            - Additional keys depending on event type

    Raises:
        ValueError: If the directory path is invalid
        FileNotFoundError: If the directory doesn't exist
        NotADirectoryError: If the path is not a directory
        PermissionError: If insufficient permissions or directory not in whitelist
    """
    # Load whitelist from environment if not provided and environment variable is set
    if whitelist is None:
        env_whitelist = os.environ.get('SCREENSHOT_RENAMER_WHITELIST')
        if env_whitelist:
            # Parse colon-separated paths from environment variable
            whitelist = [p.strip() for p in env_whitelist.split(':') if p.strip()]
            logger.info(f"Loaded whitelist from environment: {whitelist}")

    # Auto-detect prefix from macOS settings if not provided
    if prefix is None:
        from .macos_settings import get_screenshot_settings
        settings = get_screenshot_settings()
        prefix = settings.prefix
        logger.info(f"Auto-detected screenshot prefix: {prefix}")

    # Validate the directory first - this will raise exceptions if invalid
    validated_dir = validate_directory(directory, whitelist=whitelist)

    # Yield start event with detected prefix
    yield {
        'event': 'start',
        'directory': validated_dir,
        'prefix': prefix
    }

    total_files = 0
    renamed_files = 0
    skipped_files = 0
    error_count = 0

    # Build pattern for the specified prefix
    pattern = build_screenshot_pattern(prefix)

    for filename in os.listdir(validated_dir):
        total_files += 1
        match = pattern.match(filename)

        if match:
            try:
                # Sanitize the original filename
                sanitize_filename(filename)

                date, hour, minute, second, period, extension = match.groups()
                hour = int(hour)
                period = period.upper()
                if period == "PM" and hour != 12:
                    hour += 12
                elif period == "AM" and hour == 12:
                    hour = 0

                # Preserve the custom prefix (lowercase)
                prefix_lower = prefix.lower()
                new_filename = (
                    f"{prefix_lower} {date} at {hour:02}.{minute}.{second}.{extension}"
                )

                # Sanitize the new filename
                sanitize_filename(new_filename)

                # Build file paths
                old_filepath = os.path.join(validated_dir, filename)
                new_filepath = os.path.join(validated_dir, new_filename)

                # Validate both paths are within the base directory
                validate_file_path(old_filepath, validated_dir)
                validate_file_path(new_filepath, validated_dir)

                # Check if target file already exists to prevent accidental overwrites
                if os.path.exists(new_filepath):
                    logger.warning(f"Skipping rename: target file already exists: {new_filename}")
                    skipped_files += 1
                    yield {
                        'event': 'skip',
                        'filename': filename,
                        'reason': 'target_exists',
                        'message': f'Target file already exists: {new_filename}'
                    }
                    continue

                # Perform the rename
                logger.info(f"Renaming {filename} to {new_filename}")
                os.rename(old_filepath, new_filepath)
                logger.info(f"Successfully renamed to {new_filename}")
                renamed_files += 1

                # Yield success event
                yield {
                    'event': 'rename',
                    'old_name': filename,
                    'new_name': new_filename,
                    'status': 'success'
                }

            except ValueError as e:
                logger.error(f"Validation error for {filename}: {e}")
                error_count += 1
                yield {
                    'event': 'error',
                    'filename': filename,
                    'error': str(e),
                    'type': 'validation'
                }
            except OSError as e:
                logger.error(f"Error renaming {filename}: {e}")
                error_count += 1
                yield {
                    'event': 'error',
                    'filename': filename,
                    'error': str(e),
                    'type': 'os'
                }
        else:
            # File doesn't match the pattern
            skipped_files += 1
            yield {
                'event': 'skip',
                'filename': filename,
                'reason': 'no_match',
                'message': 'Does not match screenshot pattern'
            }

    # Yield complete event with summary
    yield {
        'event': 'complete',
        'total_files': total_files,
        'renamed_files': renamed_files,
        'skipped_files': skipped_files,
        'errors': error_count
    }
