#!/usr/bin/env python3
import argparse
import logging
import os
import re
from datetime import datetime
from pathlib import Path
from typing import Tuple

# Create a custom logger for this module
logger = logging.getLogger('screenshot_renamer')


def validate_directory(directory: str) -> str:
    """
    Validate and sanitize the directory path.

    Args:
        directory (str): The directory path to validate

    Returns:
        str: The absolute, normalized path

    Raises:
        ValueError: If the path is invalid or unsafe
        FileNotFoundError: If the directory doesn't exist
        NotADirectoryError: If the path exists but is not a directory
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

    logger.info(f"Validated directory: {real_path}")
    return real_path


def rename_screenshots(directory: str) -> Tuple[int, int]:
    """
    Rename screenshot files in the specified directory to a consistent format.

    Args:
        directory (str): The directory containing the screenshot files.

    Returns:
        Tuple[int, int]: (total matching files, renamed files)

    Raises:
        ValueError: If the directory path is invalid
        FileNotFoundError: If the directory doesn't exist
        NotADirectoryError: If the path is not a directory
        PermissionError: If insufficient permissions
    """
    # Validate the directory first
    validated_dir = validate_directory(directory)

    total_files = 0
    renamed_files = 0

    pattern = re.compile(
        r"Screenshot (\d{4}-\d{2}-\d{2}) at (\d{1,2})\.(\d{2})\.(\d{2})\s*([APMapm]{2})\.(\w+)",
        re.IGNORECASE,
    )

    for filename in os.listdir(validated_dir):
        total_files += 1  # Count every file in the directory
        match = pattern.match(filename)
        if match:
            date, hour, minute, second, period, extension = match.groups()
            hour = int(hour)
            period = period.upper()
            if period == "PM" and hour != 12:
                hour += 12
            elif period == "AM" and hour == 12:
                hour = 0
            new_filename = (
                f"screenshot {date} at {hour:02}.{minute}.{second}.{extension}"
            )
            old_filepath = os.path.join(validated_dir, filename)
            new_filepath = os.path.join(validated_dir, new_filename)
            try:
                logger.info(f"Renaming {old_filepath} to {new_filepath}")
                os.rename(old_filepath, new_filepath)
                logger.info(f"Successfully renamed to {new_filename}")
                renamed_files += 1
            except OSError as e:
                logger.error(f"Error renaming {old_filepath} to {new_filepath}: {e}")

    return total_files, renamed_files
