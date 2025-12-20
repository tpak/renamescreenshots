"""
Security tests for screenshot renamer.
Tests path validation, whitelist, filename sanitization, and file operations.
"""
import os
import tempfile
import pytest

from src.rename_screenshots import (
    rename_screenshots,
    validate_directory,
    sanitize_filename,
    validate_file_path,
)


def create_file(path):
    """Helper to create a test file."""
    with open(path, "w") as f:
        f.write("test")


class TestValidateDirectory:
    """Tests for directory validation."""

    def test_empty_directory_path(self):
        """Empty directory path should raise ValueError."""
        with pytest.raises(ValueError, match="Directory path cannot be empty"):
            validate_directory("")

    def test_whitespace_only_path(self):
        """Whitespace-only path should raise ValueError."""
        with pytest.raises(ValueError, match="Directory path cannot be empty"):
            validate_directory("   ")

    def test_nonexistent_directory(self):
        """Non-existent directory should raise FileNotFoundError."""
        with pytest.raises(FileNotFoundError, match="Directory does not exist"):
            validate_directory("/this/path/does/not/exist")

    def test_file_instead_of_directory(self):
        """File path instead of directory should raise NotADirectoryError."""
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            try:
                with pytest.raises(NotADirectoryError, match="Path is not a directory"):
                    validate_directory(tmp.name)
            finally:
                os.unlink(tmp.name)

    def test_valid_directory(self):
        """Valid directory should return absolute path."""
        with tempfile.TemporaryDirectory() as tmpdir:
            result = validate_directory(tmpdir)
            assert os.path.isabs(result)
            assert os.path.exists(result)

    def test_tilde_expansion(self):
        """Tilde (~) should be expanded to home directory."""
        result = validate_directory("~")
        assert result == os.path.realpath(os.path.expanduser("~"))

    def test_whitelist_allowed_directory(self):
        """Directory in whitelist should be allowed."""
        with tempfile.TemporaryDirectory() as tmpdir:
            result = validate_directory(tmpdir, whitelist=[tmpdir])
            assert result == os.path.realpath(tmpdir)

    def test_whitelist_subdirectory_allowed(self):
        """Subdirectory of whitelisted directory should be allowed."""
        with tempfile.TemporaryDirectory() as tmpdir:
            subdir = os.path.join(tmpdir, "subdir")
            os.makedirs(subdir)
            result = validate_directory(subdir, whitelist=[tmpdir])
            assert result == os.path.realpath(subdir)

    def test_whitelist_denied_directory(self):
        """Directory not in whitelist should be denied."""
        with tempfile.TemporaryDirectory() as tmpdir1:
            with tempfile.TemporaryDirectory() as tmpdir2:
                with pytest.raises(PermissionError, match="not in the whitelist"):
                    validate_directory(tmpdir1, whitelist=[tmpdir2])


class TestSanitizeFilename:
    """Tests for filename sanitization."""

    def test_empty_filename(self):
        """Empty filename should raise ValueError."""
        with pytest.raises(ValueError, match="Filename cannot be empty"):
            sanitize_filename("")

    def test_whitespace_only_filename(self):
        """Whitespace-only filename should raise ValueError."""
        with pytest.raises(ValueError, match="Filename cannot be empty"):
            sanitize_filename("   ")

    def test_null_byte_in_filename(self):
        """Null byte in filename should raise ValueError."""
        with pytest.raises(ValueError, match="null bytes"):
            sanitize_filename("file\0name.txt")

    def test_path_separator_in_filename(self):
        """Path separator in filename should raise ValueError."""
        with pytest.raises(ValueError, match="path separators"):
            sanitize_filename("path/to/file.txt")

    def test_path_traversal_dotdot(self):
        """Path traversal attempt (..) should raise ValueError."""
        with pytest.raises(ValueError, match="path traversal"):
            sanitize_filename("..")

    def test_path_traversal_in_filename(self):
        """Path traversal in filename should raise ValueError."""
        with pytest.raises(ValueError, match="path separators"):
            sanitize_filename("../etc/passwd")

    def test_control_characters(self):
        """Control characters in filename should raise ValueError."""
        with pytest.raises(ValueError, match="null bytes"):
            sanitize_filename("file\x00name.txt")

    def test_valid_filename(self):
        """Valid filename should pass sanitization."""
        valid_filenames = [
            "screenshot.png",
            "Screenshot 2024-05-24 at 1.23.45 PM.png",
            "file-with-dashes.jpg",
            "file_with_underscores.txt",
        ]
        for filename in valid_filenames:
            assert sanitize_filename(filename) == filename


class TestValidateFilePath:
    """Tests for file path validation."""

    def test_file_within_directory(self):
        """File within directory should be validated."""
        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = os.path.join(tmpdir, "test.txt")
            result = validate_file_path(filepath, tmpdir)
            assert result == os.path.realpath(filepath)

    def test_file_outside_directory(self):
        """File outside directory should raise ValueError."""
        with tempfile.TemporaryDirectory() as tmpdir1:
            with tempfile.TemporaryDirectory() as tmpdir2:
                filepath = os.path.join(tmpdir2, "test.txt")
                with pytest.raises(ValueError, match="outside base directory"):
                    validate_file_path(filepath, tmpdir1)

    def test_path_traversal_attempt(self):
        """Path traversal attempt should raise ValueError."""
        with tempfile.TemporaryDirectory() as tmpdir:
            filepath = os.path.join(tmpdir, "../etc/passwd")
            with pytest.raises(ValueError, match="outside base directory"):
                validate_file_path(filepath, tmpdir)


class TestRenameScreenshotsSecure:
    """Tests for secure file renaming operations."""

    def test_prevents_duplicate_overwrites(self):
        """Should not overwrite existing files with same target name."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create two files that would rename to the same name
            create_file(os.path.join(tmpdir, "Screenshot 2024-05-24 at 1.23.45 PM.png"))
            # Create target file that already exists
            create_file(os.path.join(tmpdir, "screenshot 2024-05-24 at 13.23.45.png"))

            total, renamed = rename_screenshots(tmpdir)

            # Should count files but skip rename due to existing target
            assert total == 2
            assert renamed == 0  # Skipped because target exists

    def test_whitelist_integration(self):
        """Whitelist should be enforced during rename operations."""
        with tempfile.TemporaryDirectory() as allowed_dir:
            with tempfile.TemporaryDirectory() as denied_dir:
                create_file(os.path.join(denied_dir, "Screenshot 2024-05-24 at 1.23.45 PM.png"))

                with pytest.raises(PermissionError, match="not in the whitelist"):
                    rename_screenshots(denied_dir, whitelist=[allowed_dir])

    def test_environment_variable_whitelist(self):
        """Should load whitelist from environment variable."""
        with tempfile.TemporaryDirectory() as tmpdir:
            create_file(os.path.join(tmpdir, "Screenshot 2024-05-24 at 1.23.45 PM.png"))

            # Set environment variable
            os.environ['SCREENSHOT_RENAMER_WHITELIST'] = tmpdir
            try:
                total, renamed = rename_screenshots(tmpdir)
                assert renamed == 1
            finally:
                # Clean up
                del os.environ['SCREENSHOT_RENAMER_WHITELIST']
