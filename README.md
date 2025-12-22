# Screenshot Renamer
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CodeQL Advanced](https://github.com/tpak/renamescreenshots/actions/workflows/codeql.yml/badge.svg)](https://github.com/tpak/renamescreenshots/actions/workflows/codeql.yml)
[![Python application](https://github.com/tpak/renamescreenshots/actions/workflows/python-app.yml/badge.svg)](https://github.com/tpak/renamescreenshots/actions/workflows/python-app.yml)

Automatically rename macOS screenshots to a sortable 24-hour format.

**Before:** `Screenshot 2024-05-24 at 1.23.45 PM.png`
**After:** `screenshot 2024-05-24 at 13.23.45.png`


## Why?

macOS screenshot names don't sort chronologically in Finder due to 12-hour time format. This tool fixes that, making screenshots easier to find and organize.

## Requirements

- **macOS** (10.13 or later recommended)
- **Python 3.8+** (3.13 recommended)
- **pip** (Python package installer)

Check your Python version:
```bash
python3 --version
```

Install Python from [python.org](https://www.python.org/downloads/) if needed.

## Quick Start

### 1. Download
```bash
git clone https://github.com/tpak/renamescreenshots.git
cd renamescreenshots
```

### 2. Install
```bash
pip install -e .
```

### 3. Run Menu Bar App (Recommended)
```bash
# Launch the menu bar app
screenshot-rename-menubar

# Optional: Set up auto-start on login
./install_launch_agent.sh
```

The 📷 icon will appear in your menu bar. Take a screenshot and it will be automatically renamed!

## What Gets Installed

Running `pip install -e .` installs **4 command-line tools**:

1. **screenshot-rename** - One-time rename of existing screenshots
2. **screenshot-rename-watch** - Background watcher (CLI version)
3. **screenshot-rename-web** - Web interface on http://localhost:5001
4. **screenshot-rename-menubar** - Menu bar app (includes watcher + web server)

**For CLI-Only Users:**

If you prefer command-line tools and don't want the menu bar app:

```bash
# Install the package (all 4 commands available)
pip install -e .

# Use the CLI commands
screenshot-rename --auto-detect           # One-time rename
screenshot-rename-watch --auto-detect     # Background watcher
screenshot-rename-web                     # Web interface

# Skip the launch agent installer
# (./install_launch_agent.sh is only for menu bar auto-start)
```

The menu bar app only runs if you explicitly launch it with `screenshot-rename-menubar` or install the launch agent.

## Usage

### Menu Bar App (Easiest)

The menu bar app is the easiest way to use Screenshot Renamer:
- 📷 Lives in your menu bar
- 🔄 Auto-renames screenshots as you take them
- 🌐 Quick access to web interface
- ⚡ One-click manual rename

```bash
screenshot-rename-menubar
```

**Menu options:**
- **Open Web Interface** - Visual file browser
- **Stop/Start Watcher** - Toggle auto-rename (on by default)
- **Quick Rename** - Rename existing screenshots now

### Other Ways to Use

<details>
<summary><b>Command Line</b> (for automation/scripting)</summary>

**Auto-detect your screenshot location:**
```bash
screenshot-rename --auto-detect
```

**Rename specific directory:**
```bash
screenshot-rename /path/to/screenshots
```

**With custom prefix:**
```bash
screenshot-rename --prefix "MyScreenshot"
```

</details>

<details>
<summary><b>Web Interface</b> (visual file browser)</summary>

**Launch the web interface:**
```bash
screenshot-rename-web
```

Then open `http://localhost:5001` in your browser.

Features:
- Visual directory picker (Chrome/Edge)
- Real-time progress updates
- Drag-and-drop friendly

</details>

<details>
<summary><b>Background Watcher</b> (CLI version)</summary>

**Auto-watch your screenshot directory:**
```bash
screenshot-rename-watch --auto-detect
```

**Watch specific directory:**
```bash
screenshot-rename-watch /path/to/screenshots
```

Press `Ctrl+C` to stop.

</details>

## Uninstall

**Remove auto-start:**
```bash
./uninstall_launch_agent.sh
```

**Remove completely:**
```bash
./uninstall_launch_agent.sh  # Remove auto-start
pip uninstall screenshot-renamer  # Remove package
```

## Advanced Features

<details>
<summary><b>Custom Screenshot Prefix</b></summary>

If you've customized your screenshot name in macOS System Settings, the tool auto-detects it. Or specify manually:
```bash
screenshot-rename --prefix "MyScreenshot"
```

</details>

<details>
<summary><b>Directory Whitelist (Security)</b></summary>

Restrict which directories can be processed:
```bash
screenshot-rename --whitelist ~/Desktop/Screenshots ~/Documents
```

Or via environment variable:
```bash
export SCREENSHOT_RENAMER_WHITELIST="~/Desktop/Screenshots:~/Documents"
```

</details>

<details>
<summary><b>Environment Variables</b></summary>

**`SCREENSHOT_RENAMER_WHITELIST`** - Restrict allowed directories (colon-separated paths)

**`SCREENSHOT_RENAMER_SECRET_KEY`** - CSRF token key for web interface (recommended for production)

Generate a secure key:
```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

</details>

<details>
<summary><b>Security Features</b></summary>

- **Path validation** - Prevents path traversal attacks
- **File sanitization** - Blocks unsafe characters and null bytes
- **CSRF protection** - Secures web interface forms
- **Whitelist support** - Optional directory restrictions
- Fully tested with comprehensive test suite

</details>

## For Developers

### Running Tests
```bash
pytest -v
```

### Project Structure
```
src/
├── cli.py              # Command-line interface
├── menubar_app.py      # macOS menu bar app
├── rename_screenshots.py  # Core renaming logic
├── watcher.py          # Background file watcher
└── web_app.py          # Flask web interface
```

### Contributing

Contributions welcome! Please:
- Keep it simple - this is a focused utility
- Maintain test coverage
- Follow existing code style
- Update documentation

## Acknowledgments

**Built with:**
- [rumps](https://github.com/jaredks/rumps) (BSD-3-Clause) - macOS menu bar app framework
- [Flask](https://flask.palletsprojects.com/) (BSD-3-Clause) - Web interface
- [watchdog](https://github.com/gorakhargosh/watchdog) (Apache-2.0) - File monitoring

All dependencies are compatible with our MIT license.

## License

MIT License - see LICENSE file for details.

Created by [Chris Tirpak](https://github.com/tpak)

---

 When you run pip install -e ., all 4 commands are installed automatically:

  1. screenshot-rename (One-time rename)

  # Auto-detect macOS settings and rename
  screenshot-rename --auto-detect

  # Rename specific directory
  screenshot-rename /path/to/screenshots

  # With custom prefix
  screenshot-rename --prefix "MyScreenshot" ~/Desktop

  # With directory whitelist
  screenshot-rename --whitelist ~/Desktop ~/Documents

  2. screenshot-rename-watch (CLI background watcher)

  # Auto-detect and watch
  screenshot-rename-watch --auto-detect

  # Watch specific directory
  screenshot-rename-watch /path/to/screenshots

  # With custom prefix
  screenshot-rename-watch --prefix "MyScreenshot"

  3. screenshot-rename-web (Web interface)

  # Launch web UI on http://localhost:5001
  screenshot-rename-web

  4. screenshot-rename-menubar (Menu bar app)

  # Launch menu bar app (includes watcher + web server)
  screenshot-rename-menubar

  Installation Details

  pip install -e . installs:
  - ✅ All 4 CLI commands above
  - ✅ All dependencies (Flask, watchdog, rumps)
  - ✅ Python package screenshot-renamer

  ./install_launch_agent.sh only:
  - Sets up auto-start for the menu bar app on login
  - Does NOT install the commands (run pip install -e . first)
  - Optional - only for users who want the menu bar app to auto-start

  For CLI-Only Users

  Users who don't want the menu bar app can:

  1. Install the package:
  pip install -e .
  2. Use any of the first 3 commands:
    - screenshot-rename for one-time renames
    - screenshot-rename-watch for background watching
    - screenshot-rename-web for web interface
  3. Skip the ./install_launch_agent.sh script entirely

  The menu bar app only runs if explicitly launched with screenshot-rename-menubar or via the launch agent.