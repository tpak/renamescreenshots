# filepath: /screenshotrename/screenshotrename/src/cli.py

import argparse
import logging
import os
from rename_screenshots import rename_screenshots

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
    
    logging.basicConfig(level=logging.INFO)
    total_files, renamed_files = rename_screenshots(directory)

    logging.info(f"Total files iterated: {total_files}")
    logging.info(f"Total files renamed: {renamed_files}")

if __name__ == "__main__":
    main()