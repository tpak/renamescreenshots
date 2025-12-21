#!/usr/bin/env python3

import argparse
import logging
import os

from .rename_screenshots import rename_screenshots

# Create a custom logger
logger = logging.getLogger('screenshot_renamer')


def main():
    """
    Main function to parse arguments and call the rename_screenshots function.
    """
    parser = argparse.ArgumentParser(
        description="Rename screenshot files to a consistent format."
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=os.getcwd(),
        help="The directory containing the screenshot files",
    )
    parser.add_argument(
        "--use-default-dir",
        action="store_true",
        help="Use the default directory ~/Desktop/Screenshots",
    )
    parser.add_argument(
        "--whitelist",
        nargs="+",
        metavar="DIR",
        help="Optional whitelist of allowed directories (space-separated). "
             "Only these directories and their subdirectories can be processed. "
             "Can also be set via SCREENSHOT_RENAMER_WHITELIST environment variable (colon-separated).",
    )
    args = parser.parse_args()

    directory = (
        os.path.expanduser("~/Desktop/Screenshots")
        if args.use_default_dir
        else args.directory
    )

    # Configure logging with custom format
    logging.basicConfig(
        level=logging.INFO,
        format='%(levelname)s:%(name)s: %(message)s'
    )

    try:
        total_files, renamed_files = rename_screenshots(
            directory,
            whitelist=args.whitelist
        )
        logger.info(f"Total files scanned: {total_files}")
        logger.info(f"Total files renamed: {renamed_files}")
    except (ValueError, FileNotFoundError, NotADirectoryError, PermissionError) as e:
        logger.error(f"Error: {e}")
        return 1

    return 0


def watch_command():
    """
    Entry point for the watch command.
    Watches a directory and automatically renames screenshots as they appear.
    """
    parser = argparse.ArgumentParser(
        description="Watch directory and auto-rename screenshots."
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=os.path.expanduser("~/Desktop/Screenshots"),
        help="Directory to watch (default: ~/Desktop/Screenshots)",
    )
    parser.add_argument(
        "--whitelist",
        nargs="+",
        metavar="DIR",
        help="Optional whitelist of allowed directories (space-separated). "
             "Only these directories and their subdirectories can be processed. "
             "Can also be set via SCREENSHOT_RENAMER_WHITELIST environment variable (colon-separated).",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose logging",
    )
    args = parser.parse_args()

    # Configure logging
    log_level = logging.DEBUG if args.verbose else logging.INFO
    logging.basicConfig(
        level=log_level,
        format='%(levelname)s:%(name)s: %(message)s'
    )

    try:
        from .watcher import watch_directory
        watch_directory(args.directory, whitelist=args.whitelist)
        return 0
    except (ValueError, FileNotFoundError, NotADirectoryError, PermissionError) as e:
        logger.error(f"Error: {e}")
        return 1
    except KeyboardInterrupt:
        return 0


if __name__ == "__main__":
    main()
