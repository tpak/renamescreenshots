# How to run:
# From project root, run:
# pytest
# or
# python -m pytest
import os
import tempfile

from src.rename_screenshots import rename_screenshots


def create_file(path):
    with open(path, "w") as f:
        f.write("test")


def test_rename_screenshots_basic():
    with tempfile.TemporaryDirectory() as tmpdir:
        # Create files that match and don't match the pattern
        matching = [
            "Screenshot 2024-05-24 at 1.23.45 PM.png",
            "Screenshot 2024-05-24 at 12.00.00 AM.jpg",
        ]
        non_matching = [
            "not_a_screenshot.txt",
            "image.png",
        ]
        for fname in matching + non_matching:
            create_file(os.path.join(tmpdir, fname))

        total, renamed = rename_screenshots(tmpdir)

        # Should count all files
        assert total == len(matching) + len(non_matching)
        # Should rename only matching files
        assert renamed == len(matching)
        # Check renamed files exist
        assert os.path.exists(
            os.path.join(tmpdir, "screenshot 2024-05-24 at 13.23.45.png")
        )
        assert os.path.exists(
            os.path.join(tmpdir, "screenshot 2024-05-24 at 00.00.00.jpg")
        )
        # Check non-matching files are still there
        for fname in non_matching:
            assert os.path.exists(os.path.join(tmpdir, fname))


def test_rename_screenshots_no_matches():
    with tempfile.TemporaryDirectory() as tmpdir:
        create_file(os.path.join(tmpdir, "randomfile.txt"))
        total, renamed = rename_screenshots(tmpdir)
        assert total == 1
        assert renamed == 0


def test_rename_screenshots_empty_dir():
    with tempfile.TemporaryDirectory() as tmpdir:
        total, renamed = rename_screenshots(tmpdir)

        assert total == 0
        assert renamed == 0
