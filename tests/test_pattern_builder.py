"""Tests for dynamic screenshot pattern building."""
import pytest
import re

from src.rename_screenshots import build_screenshot_pattern


class TestBuildScreenshotPattern:
    """Tests for build_screenshot_pattern() function."""

    def test_build_pattern_default(self):
        """Default pattern should match 'Screenshot'."""
        pattern = build_screenshot_pattern()

        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.png")
        assert pattern.match("Screenshot 2024-12-31 at 11.59.59 PM.jpg")

    def test_build_pattern_custom(self):
        """Custom prefix should be matched."""
        pattern = build_screenshot_pattern("MyScreenshot")

        assert pattern.match("MyScreenshot 2024-05-24 at 1.23.45 PM.png")
        assert not pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.png")

    def test_build_pattern_escapes_special_chars(self):
        """Should escape regex special characters in prefix."""
        # Prefix with a dot (special regex character)
        pattern = build_screenshot_pattern("My.Screenshot")
        assert pattern.match("My.Screenshot 2024-05-24 at 1.23.45 PM.png")

        # Prefix with parentheses
        pattern = build_screenshot_pattern("My(Screenshot)")
        assert pattern.match("My(Screenshot) 2024-05-24 at 1.23.45 PM.png")

        # Prefix with brackets
        pattern = build_screenshot_pattern("My[Screenshot]")
        assert pattern.match("My[Screenshot] 2024-05-24 at 1.23.45 PM.png")

    def test_build_pattern_case_insensitive(self):
        """Pattern should be case-insensitive."""
        pattern = build_screenshot_pattern("Screenshot")

        assert pattern.match("screenshot 2024-05-24 at 1.23.45 PM.png")
        assert pattern.match("SCREENSHOT 2024-05-24 at 1.23.45 PM.png")
        assert pattern.match("ScReEnShOt 2024-05-24 at 1.23.45 PM.png")

    def test_pattern_captures_groups(self):
        """Pattern should capture date, time, sequence number, and extension groups."""
        pattern = build_screenshot_pattern("Screenshot")
        match = pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.png")

        assert match is not None
        groups = match.groups()

        assert groups[0] == "2024-05-24"  # Date
        assert groups[1] == "1"            # Hour
        assert groups[2] == "23"           # Minute
        assert groups[3] == "45"           # Second
        assert groups[4] == "PM"           # AM/PM
        assert groups[5] is None           # Sequence number (None for single screenshot)
        assert groups[6] == "png"          # Extension

    def test_pattern_matches_various_extensions(self):
        """Pattern should match various file extensions."""
        pattern = build_screenshot_pattern()

        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.png")
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.jpg")
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.jpeg")
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.gif")

    def test_pattern_matches_am_pm_variations(self):
        """Pattern should match AM/PM in various cases."""
        pattern = build_screenshot_pattern()

        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 AM.png")
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.png")
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 am.png")
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 pm.png")

    def test_pattern_matches_single_digit_hours(self):
        """Pattern should match single-digit hours."""
        pattern = build_screenshot_pattern()

        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.png")
        assert pattern.match("Screenshot 2024-05-24 at 9.59.59 AM.png")

    def test_pattern_matches_double_digit_hours(self):
        """Pattern should match double-digit hours."""
        pattern = build_screenshot_pattern()

        assert pattern.match("Screenshot 2024-05-24 at 10.23.45 PM.png")
        assert pattern.match("Screenshot 2024-05-24 at 12.00.00 AM.png")

    def test_pattern_doesnt_match_invalid_format(self):
        """Pattern should not match incorrectly formatted filenames."""
        pattern = build_screenshot_pattern()

        # Wrong date format
        assert not pattern.match("Screenshot 05-24-2024 at 1.23.45 PM.png")

        # Missing 'at'
        assert not pattern.match("Screenshot 2024-05-24 1.23.45 PM.png")

        # Wrong time separator
        assert not pattern.match("Screenshot 2024-05-24 at 1:23:45 PM.png")

        # No AM/PM
        assert not pattern.match("Screenshot 2024-05-24 at 1.23.45.png")

        # No extension
        assert not pattern.match("Screenshot 2024-05-24 at 1.23.45 PM")

    def test_pattern_returns_compiled_regex(self):
        """Function should return a compiled regex Pattern object."""
        pattern = build_screenshot_pattern()

        assert isinstance(pattern, re.Pattern)

    def test_pattern_with_whitespace_variations(self):
        """Pattern should handle whitespace variations before AM/PM."""
        pattern = build_screenshot_pattern()

        # No space before AM/PM
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45PM.png")

        # Single space
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.png")

        # Multiple spaces
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45  PM.png")

    def test_custom_prefix_with_spaces(self):
        """Should handle custom prefix with spaces."""
        pattern = build_screenshot_pattern("My Screenshot")

        assert pattern.match("My Screenshot 2024-05-24 at 1.23.45 PM.png")

    def test_custom_prefix_with_numbers(self):
        """Should handle custom prefix with numbers."""
        pattern = build_screenshot_pattern("Screenshot2")

        assert pattern.match("Screenshot2 2024-05-24 at 1.23.45 PM.png")

    def test_empty_prefix(self):
        """Should handle empty prefix (edge case)."""
        pattern = build_screenshot_pattern("")

        # Matches files with just space before date
        assert pattern.match(" 2024-05-24 at 1.23.45 PM.png")

    def test_pattern_matches_sequential_screenshots(self):
        """Should match screenshots with sequence numbers (rapid screenshots)."""
        pattern = build_screenshot_pattern()

        # Single screenshot (no sequence number)
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.png")

        # Sequential screenshots (multiple in same second)
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM 1.png")
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM 2.png")
        assert pattern.match("Screenshot 2024-05-24 at 1.23.45 PM 10.png")

    def test_pattern_captures_sequence_number(self):
        """Pattern should capture sequence number when present."""
        pattern = build_screenshot_pattern()

        # Without sequence number
        match = pattern.match("Screenshot 2024-05-24 at 1.23.45 PM.png")
        assert match is not None
        groups = match.groups()
        assert groups[5] is None  # sequence_num is None
        assert groups[6] == "png"  # extension

        # With sequence number
        match = pattern.match("Screenshot 2024-05-24 at 1.23.45 PM 2.png")
        assert match is not None
        groups = match.groups()
        assert groups[5] == "2"  # sequence_num
        assert groups[6] == "png"  # extension
