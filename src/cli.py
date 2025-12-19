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

    total_files, renamed_files = rename_screenshots(directory)

    logger.info(f"Total files scanned: {total_files}")
    logger.info(f"Total files renamed: {renamed_files}")


if __name__ == "__main__":
    main()
