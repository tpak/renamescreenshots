# Screenshot Renamer
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CodeQL Advanced](https://github.com/tpak/renamescreenshots/actions/workflows/codeql.yml/badge.svg)](https://github.com/tpak/renamescreenshots/actions/workflows/codeql.yml)
[![Python application](https://github.com/tpak/renamescreenshots/actions/workflows/python-app.yml/badge.svg)](https://github.com/tpak/renamescreenshots/actions/workflows/python-app.yml)

This project provides a tool for renaming screenshot files to a consistent format. It can be used as a command-line interface (CLI) tool or as a Streamlit web application. I use it on my Mac, you can adapt as needed.

## Features

- Rename screenshot files in a specified directory.
- Supports both CLI and Streamlit interface for user interaction.
- Automatically converts time from 12-hour to 24-hour format. This keeps the files sorted in finder and makes it easier to find the latest and drag them into Slack, Teams, email, etc.
- Yes, there are probably easier ways

## Project Structure

```
renamescreenshots
├── src
│   ├── __init__.py
│   ├── cli.py
│   ├── streamlit_app.py
│   └── rename_screenshots.py
├── tests
│   ├── test_cli.py
│   └── test_rename_screenshots.py
├── requirements.txt
└── README.md
```

## Installation

To install the required dependencies, run:

```
pip install -r requirements.txt
```

> **Note:** `argparse` and `logging` are part of the Python standard library and do not need to be installed separately. CoPilot really wants me to tell you this :-)

## Usage

### Command-Line Interface

To use the CLI tool, run:

```
python -m src.cli [directory]

or

python src/cli.py [directory]
```

- Replace `[directory]` with the path to the directory containing the screenshot files. If no directory is specified, it will default to the current working directory.
- You can also use the `--use-default-dir` flag to process `~/Desktop/Screenshots`:
  ```
  python -m src.cli --use-default-dir
  ```

### Streamlit Application

To run the Streamlit application, you have two options:

**Option 1: Use the helper script (recommended)**

From the project root, run:
```
./rename-ui.sh
```
This will launch the Streamlit web interface for renaming screenshots.

> **Hint:** If you haven't already, make the script executable with:
> ```
> chmod +x rename-ui.sh
> ```

**Option 2: Use the Streamlit CLI directly**

```
streamlit run src/streamlit_app.py
```

This will start a local web server and open the Streamlit interface in your web browser, allowing you to select a directory and view the renaming results interactively.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.