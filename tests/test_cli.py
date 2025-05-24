import os
import subprocess
import sys
import tempfile


def test_cli_runs_and_renames(tmp_path):
    # Prepare a test directory with a screenshot file
    test_file = tmp_path / "Screenshot 2024-05-24 at 1.23.45 PM.png"
    test_file.write_text("test")

    # Run the CLI as a subprocess
    result = subprocess.run(
        [sys.executable, "src/cli.py", str(tmp_path)],
        capture_output=True,
        text=True,
    )

    # Check that the CLI ran successfully
    assert result.returncode == 0
    # Check that the renamed file exists
    assert (tmp_path / "screenshot 2024-05-24 at 13.23.45.png").exists()


def test_cli_with_no_matching_files(tmp_path):
    # Prepare a test directory with a non-matching file
    test_file = tmp_path / "not_a_screenshot.txt"
    test_file.write_text("test")

    result = subprocess.run(
        [sys.executable, "src/cli.py", str(tmp_path)],
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0
    # The file should still exist and not be renamed
    assert (tmp_path / "not_a_screenshot.txt").exists()


def test_cli_use_default_dir(monkeypatch, tmp_path):
    # Patch the user's Desktop/Screenshots path to our tmp_path
    fake_home = tmp_path.parent
    monkeypatch.setenv("HOME", str(fake_home))
    screenshots_dir = fake_home / "Desktop" / "Screenshots"
    screenshots_dir.mkdir(parents=True, exist_ok=True)
    test_file = screenshots_dir / "Screenshot 2024-05-24 at 1.23.45 PM.png"
    test_file.write_text("test")

    # Pass the environment to the subprocess
    env = os.environ.copy()
    env["HOME"] = str(fake_home)

    result = subprocess.run(
        [sys.executable, "src/cli.py", "--use-default-dir"],
        capture_output=True,
        text=True,
        env=env,  # <-- Pass the patched environment
    )

    assert result.returncode == 0
    assert (screenshots_dir / "screenshot 2024-05-24 at 13.23.45.png").exists()
