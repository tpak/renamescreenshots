# Screenshot Renamer
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CodeQL Advanced](https://github.com/tpak/renamescreenshots/actions/workflows/codeql.yml/badge.svg)](https://github.com/tpak/renamescreenshots/actions/workflows/codeql.yml)
[![Python application](https://github.com/tpak/renamescreenshots/actions/workflows/python-app.yml/badge.svg)](https://github.com/tpak/renamescreenshots/actions/workflows/python-app.yml)

A clean, simple macOS utility for renaming screenshot files to a sortable format. Available as both a command-line tool and a beautiful web interface.

## Why?

macOS names screenshots like `Screenshot 2024-05-24 at 1.23.45 PM.png`, which don't sort chronologically in Finder. This tool converts them to `screenshot 2024-05-24 at 13.23.45.png`, making them properly sortable and easier to find when dragging into Slack, Teams, or email.

## Features

- 🎯 Simple, focused functionality - does one thing well
- 💻 Command-line interface for automation and scripting
- 🌐 Beautiful web interface for visual interaction
- 👁️ Background watcher for automatic real-time screenshot renaming
- 🔒 Comprehensive security features (CSRF protection, path validation, sanitization)
- ⚡ Fast and efficient - no heavy dependencies
- ✅ Fully tested with comprehensive test suite
- 📦 Properly packaged as an installable Python module

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/tpak/renamescreenshots.git
cd renamescreenshots

# Install the package in development mode
pip install -e .
```

For development with testing dependencies:
```bash
pip install -e ".[dev]"
```

## Usage

### Web Interface (Recommended)

The web interface provides a beautiful, user-friendly way to rename your screenshots with real-time feedback.

**Features:**
- 📁 **Directory Picker** (Chrome/Edge) - Click to browse and select folders
- ⚡ **Real-Time Progress** - See each file as it's being renamed with live updates
- 📊 **Detailed Feedback** - View renamed files, skipped files, and any errors
- 🎨 **Clean, Simple Design** - Beautiful interface that stays out of your way
- 🔄 **Graceful Fallback** - Works in all modern browsers

**Using the helper script:**
```bash
./rename-ui.sh
```

**Or run directly:**
```bash
python -m src.web_app
```

Then open your browser to `http://localhost:5000`

**Browser Compatibility:**
- Chrome/Edge: Full features including directory picker
- Firefox/Safari: Text input for directory path (directory picker not supported)
- All browsers support real-time progress via Server-Sent Events

**For production use, set a persistent SECRET_KEY:**
```bash
export SCREENSHOT_RENAMER_SECRET_KEY="your-secret-key-here"
./rename-ui.sh
```

### Command-Line Interface

Perfect for automation, scripts, or terminal lovers.

**Rename screenshots in a specific directory:**
```bash
python -m src.cli /path/to/screenshots
```

**Use the default macOS screenshots directory:**
```bash
python -m src.cli --use-default-dir
```

**Or use the current directory:**
```bash
python -m src.cli
```

**With directory whitelist for additional security:**
```bash
python -m src.cli --whitelist ~/Desktop/Screenshots ~/Documents/Screenshots
```

You can also set a whitelist via environment variable:
```bash
export SCREENSHOT_RENAMER_WHITELIST="~/Desktop/Screenshots:~/Documents/Screenshots"
python -m src.cli
```

### Background Watcher

Automatically watch a directory and rename screenshots as they appear in real-time.

**Watch the default screenshots directory:**
```bash
screenshot-rename-watch
```

**Watch a specific directory:**
```bash
screenshot-rename-watch /path/to/screenshots
```

**With directory whitelist for security:**
```bash
screenshot-rename-watch --whitelist ~/Desktop/Screenshots
```

**With verbose logging:**
```bash
screenshot-rename-watch -v
```

The watcher runs in the foreground and can be stopped with `Ctrl+C`.

**Features:**
- ⚡ Instant renaming as screenshots are created
- 🔒 Same security validations as CLI (whitelist support, path validation)
- 📊 Real-time logging of detected and renamed files
- 🎯 Non-recursive (watches only the specified directory, not subdirectories)

**Use Cases:**
- Set it and forget it - automatically rename screenshots as you take them
- Integrate with automation workflows
- Run as a background service (see below)

**Running as a macOS Launch Agent (optional):**

To automatically start the watcher on login, create a launch agent plist file:

```bash
# Create the launch agent file
cat > ~/Library/LaunchAgents/com.screenshot-renamer.watcher.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.screenshot-renamer.watcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/screenshot-rename-watch</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/screenshot-renamer.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/screenshot-renamer.err</string>
</dict>
</plist>
EOF

# Load the launch agent
launchctl load ~/Library/LaunchAgents/com.screenshot-renamer.watcher.plist

# To stop and unload:
# launchctl unload ~/Library/LaunchAgents/com.screenshot-renamer.watcher.plist
```

### As an Installed Command

After installation, you can also use the installed command:
```bash
screenshot-rename /path/to/screenshots
screenshot-rename --use-default-dir
```

## Development

### Running Tests

```bash
pytest
```

Or with verbose output:
```bash
pytest -v
```

### Project Structure

```
renamescreenshots/
├── src/
│   ├── __init__.py
│   ├── cli.py                  # Command-line interface
│   ├── rename_screenshots.py   # Core renaming logic
│   ├── watcher.py             # Background file watcher
│   ├── web_app.py             # Flask web application
│   ├── templates/
│   │   └── index.html         # Web interface template
│   └── static/                # Static assets (if needed)
├── tests/
│   ├── test_cli.py
│   ├── test_rename_screenshots.py
│   ├── test_security.py
│   ├── test_watcher.py
│   └── test_web_app.py
├── pyproject.toml             # Modern Python packaging
├── requirements.txt
└── README.md
```

## Security Features

This utility includes comprehensive security protections to ensure safe file operations:

### Path Validation
All directory paths are validated and normalized to prevent path traversal attacks. The tool:
- Resolves symlinks to real paths
- Converts relative paths to absolute paths
- Verifies the directory exists and is actually a directory
- Checks for read/write permissions before operating

### Directory Whitelist (Optional Security Layer)
Restricts which directories the tool can operate on. When enabled, the tool will **ONLY** process files in:
- Directories explicitly listed in the whitelist, OR
- Subdirectories of whitelisted directories

**Example:**
```bash
# Only allow ~/Desktop/Screenshots and its subdirectories
screenshot-rename ~/Desktop/Screenshots/2024 --whitelist ~/Desktop/Screenshots
# ✅ ALLOWED (subdirectory of whitelisted path)

screenshot-rename ~/Documents --whitelist ~/Desktop/Screenshots
# ❌ BLOCKED - PermissionError: "Directory not allowed"
```

**Use cases:**
- Multi-user systems: Prevent operations on other users' files
- Automated scripts: Ensure scripts can't accidentally process wrong directories
- Web interface: Prevent web users from renaming files in sensitive locations
- Defense in depth: Extra safety layer on top of path validation

**Note:** If no whitelist is provided, the tool can operate on any directory the user has permissions for.

### File Sanitization
All filenames are sanitized before renaming to prevent:
- Null bytes in filenames
- Control characters
- Path separators (/, \)
- Path traversal attempts (../, ..\)

### CSRF Protection (Web Interface)
The web interface uses Flask-WTF to protect against Cross-Site Request Forgery attacks:
- All form submissions require a valid CSRF token
- Tokens are cryptographically signed using the SECRET_KEY
- SSE endpoints validate CSRF tokens via query parameters

### Environment Variables

#### `SCREENSHOT_RENAMER_WHITELIST`
**Purpose:** Define allowed directories for file operations (optional security restriction)

**Format:** Colon-separated list of directory paths
```bash
export SCREENSHOT_RENAMER_WHITELIST="~/Desktop/Screenshots:~/Documents/Screenshots"
```

**Behavior:**
- When set: Tool can ONLY operate in listed directories and their subdirectories
- When not set: Tool can operate in any directory with proper permissions
- Both CLI and web interface respect this setting

#### `SCREENSHOT_RENAMER_SECRET_KEY`
**Purpose:** Cryptographic key for signing CSRF tokens and session cookies (web interface only)

**Format:** Random string (minimum 32 characters recommended)
```bash
export SCREENSHOT_RENAMER_SECRET_KEY="your-secure-random-key-here"
```

**Behavior:**
- **Not set (development):** Auto-generates a random key on each server start
  - ⚠️ CSRF tokens become invalid when server restarts
  - Shows warning message in console
- **Set (production):** Uses your provided key consistently
  - ✅ CSRF tokens remain valid across server restarts
  - No warning messages

**Generate a secure key:**
```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

**Security note:** Keep this key secret! Anyone with access to it can forge valid CSRF tokens.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

### Guidelines
- Keep it simple - this is a focused utility
- Maintain test coverage
- Follow existing code style
- Update documentation as needed

## License

This project is licensed under the MIT License. See the LICENSE file for more details.

## Author

Created by [Chris Tirpak](https://github.com/tpak)