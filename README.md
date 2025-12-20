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

The web interface provides a beautiful, user-friendly way to rename your screenshots.

**Using the helper script:**
```bash
./rename-ui.sh
```

**Or run directly:**
```bash
python -m src.web_app
```

Then open your browser to `http://localhost:5000`

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
│   ├── web_app.py             # Flask web application
│   ├── templates/
│   │   └── index.html         # Web interface template
│   └── static/                # Static assets (if needed)
├── tests/
│   ├── test_cli.py
│   ├── test_rename_screenshots.py
│   └── test_security.py
├── pyproject.toml             # Modern Python packaging
├── requirements.txt
└── README.md
```

## Security Features

This utility includes comprehensive security protections:

- **Path Validation**: All directory paths are validated and normalized to prevent path traversal attacks
- **Directory Whitelist**: Optional whitelist to restrict operations to specific directories only
- **File Sanitization**: Filenames are sanitized to prevent null bytes, control characters, and path traversal attempts
- **CSRF Protection**: Web interface includes CSRF token validation to prevent cross-site request forgery
- **Secure Configuration**: Support for environment variables to manage secrets securely

### Environment Variables

- `SCREENSHOT_RENAMER_WHITELIST`: Colon-separated list of allowed directories (optional)
- `SCREENSHOT_RENAMER_SECRET_KEY`: Secret key for Flask sessions (recommended for web interface)

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