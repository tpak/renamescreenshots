"""Tests for macOS settings detection."""
import pytest
from unittest.mock import patch, MagicMock
import subprocess
import os

from src.macos_settings import ScreenshotSettings, get_screenshot_settings


class TestScreenshotSettings:
    """Tests for ScreenshotSettings class."""

    def test_default_location_when_command_fails(self):
        """Should return ~/Desktop when defaults command fails."""
        with patch('subprocess.run') as mock_run:
            mock_run.return_value = MagicMock(returncode=1, stdout='', stderr='')

            settings = ScreenshotSettings()
            location, prefix = settings.load_settings()

            assert location.endswith('/Desktop')
            assert prefix == "Screenshot"

    def test_reads_custom_location(self):
        """Should read custom location from defaults."""
        custom_location = "/Users/test/Screenshots"

        with patch('subprocess.run') as mock_run:
            with patch('os.path.isdir') as mock_isdir:
                # Mock directory exists
                mock_isdir.return_value = True

                def side_effect(*args, **kwargs):
                    if 'location' in args[0]:
                        return MagicMock(
                            returncode=0,
                            stdout=custom_location + '\n',
                            stderr=''
                        )
                    return MagicMock(returncode=1, stdout='', stderr='')

                mock_run.side_effect = side_effect

                settings = ScreenshotSettings()
                location, prefix = settings.load_settings()

                assert location == custom_location
                assert prefix == "Screenshot"  # Default

    def test_reads_custom_prefix(self):
        """Should read custom prefix from defaults."""
        custom_prefix = "MyScreenshot"

        with patch('subprocess.run') as mock_run:
            def side_effect(*args, **kwargs):
                if 'name' in args[0]:
                    return MagicMock(
                        returncode=0,
                        stdout=custom_prefix + '\n',
                        stderr=''
                    )
                return MagicMock(returncode=1, stdout='', stderr='')

            mock_run.side_effect = side_effect

            settings = ScreenshotSettings()
            location, prefix = settings.load_settings()

            assert prefix == custom_prefix

    def test_caching_settings(self):
        """Should cache settings and not re-run commands."""
        with patch('subprocess.run') as mock_run:
            mock_run.return_value = MagicMock(returncode=1, stdout='', stderr='')

            settings = ScreenshotSettings()
            settings.load_settings()
            settings.load_settings()  # Second call

            # Should only call subprocess twice (once for location, once for prefix)
            assert mock_run.call_count == 2

    def test_whitelist_includes_location(self):
        """get_whitelist_for_location should include detected location."""
        with patch('subprocess.run') as mock_run:
            with patch('os.path.isdir') as mock_isdir:
                mock_isdir.return_value = True
                mock_run.return_value = MagicMock(
                    returncode=0,
                    stdout="/Users/test/Screenshots\n",
                    stderr=''
                )

                settings = ScreenshotSettings()
                settings.load_settings()
                whitelist = settings.get_whitelist_for_location()

                assert "/Users/test/Screenshots" in whitelist

    def test_location_property_loads_if_needed(self):
        """location property should auto-load settings."""
        with patch('subprocess.run') as mock_run:
            with patch('os.path.isdir') as mock_isdir:
                mock_isdir.return_value = True
                mock_run.return_value = MagicMock(
                    returncode=0,
                    stdout="/Users/test/Docs\n",
                    stderr=''
                )

                settings = ScreenshotSettings()
                # Access property without explicit load
                location = settings.location

                assert "/Users/test/Docs" == location

    def test_prefix_property_loads_if_needed(self):
        """prefix property should auto-load settings."""
        with patch('subprocess.run') as mock_run:
            def side_effect(*args, **kwargs):
                if 'name' in args[0]:
                    return MagicMock(returncode=0, stdout="Custom\n", stderr='')
                return MagicMock(returncode=1, stdout='', stderr='')

            mock_run.side_effect = side_effect

            settings = ScreenshotSettings()
            # Access property without explicit load
            prefix = settings.prefix

            assert prefix == "Custom"

    def test_reload_forces_refresh(self):
        """reload() should force re-reading from defaults."""
        with patch('subprocess.run') as mock_run:
            mock_run.return_value = MagicMock(returncode=1, stdout='', stderr='')

            settings = ScreenshotSettings()
            settings.load_settings()
            call_count_first = mock_run.call_count

            settings.reload()
            call_count_after_reload = mock_run.call_count

            # Should have called subprocess again
            assert call_count_after_reload > call_count_first

    def test_timeout_handling(self):
        """Should handle subprocess timeout gracefully."""
        with patch('subprocess.run') as mock_run:
            mock_run.side_effect = subprocess.TimeoutExpired('defaults', 5)

            settings = ScreenshotSettings()
            location, prefix = settings.load_settings()

            # Should fall back to defaults
            assert location.endswith('/Desktop')
            assert prefix == "Screenshot"

    def test_subprocess_error_handling(self):
        """Should handle subprocess errors gracefully."""
        with patch('subprocess.run') as mock_run:
            mock_run.side_effect = subprocess.SubprocessError("Command failed")

            settings = ScreenshotSettings()
            location, prefix = settings.load_settings()

            # Should fall back to defaults
            assert location.endswith('/Desktop')
            assert prefix == "Screenshot"

    def test_location_doesnt_exist(self):
        """Should fall back to default if location doesn't exist."""
        with patch('subprocess.run') as mock_run:
            with patch('os.path.isdir') as mock_isdir:
                # Mock directory doesn't exist
                mock_isdir.return_value = False
                mock_run.return_value = MagicMock(
                    returncode=0,
                    stdout="/nonexistent/path\n",
                    stderr=''
                )

                settings = ScreenshotSettings()
                location, _ = settings.load_settings()

                # Should fall back to ~/Desktop
                assert location.endswith('/Desktop')

    def test_empty_stdout(self):
        """Should handle empty stdout gracefully."""
        with patch('subprocess.run') as mock_run:
            # Return success but empty output
            mock_run.return_value = MagicMock(returncode=0, stdout='   \n', stderr='')

            settings = ScreenshotSettings()
            location, prefix = settings.load_settings()

            # Should use defaults
            assert location.endswith('/Desktop')
            assert prefix == "Screenshot"


class TestGetScreenshotSettings:
    """Tests for get_screenshot_settings() function."""

    def test_returns_singleton(self):
        """Should return the same instance every time."""
        settings1 = get_screenshot_settings()
        settings2 = get_screenshot_settings()

        assert settings1 is settings2
