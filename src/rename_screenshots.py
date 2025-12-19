#!/usr/bin/env python3
import argparse
import logging
import os
import re
from datetime import datetime
from typing import Tuple

# Create a custom logger for this module
logger = logging.getLogger('screenshot_renamer')


def rename_screenshots(directory: str) -> Tuple[int, int]:
    """
    Rename screenshot files in the specified directory to a consistent format.

    Args:
        directory (str): The directory containing the screenshot files.

    Returns:
        Tuple[int, int]: (total matching files, renamed files)
    """
    total_files = 0
    renamed_files = 0

    pattern = re.compile(
        r"Screenshot (\d{4}-\d{2}-\d{2}) at (\d{1,2})\.(\d{2})\.(\d{2})\s*([APMapm]{2})\.(\w+)",
        re.IGNORECASE,
    )

    for filename in os.listdir(directory):
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
            old_filepath = os.path.join(directory, filename)
            new_filepath = os.path.join(directory, new_filename)
            try:
                logger.info(f"Renaming {old_filepath} to {new_filepath}")
                os.rename(old_filepath, new_filepath)
                logger.info(f"Successfully renamed to {new_filename}")
                renamed_files += 1
            except OSError as e:
                logger.error(f"Error renaming {old_filepath} to {new_filepath}: {e}")

    return total_files, renamed_files
