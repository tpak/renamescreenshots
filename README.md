# Screenshot Renamer

This project provides a tool for renaming screenshot files to a consistent format. It can be used as a command-line interface (CLI) tool or as a Streamlit web application.

## Features

- Rename screenshot files in a specified directory.
- Supports both CLI and Streamlit interface for user interaction.
- Automatically converts time from 12-hour to 24-hour format.

## Project Structure

```
screenshotrename
├── src
│   ├── __init__.py          # Marks the directory as a Python package
│   ├── cli.py               # Command-line interface for renaming screenshots
│   ├── streamlit_app.py     # Streamlit application for renaming screenshots
│   └── rename_screenshots.py # Core logic for renaming screenshots
├── requirements.txt          # Project dependencies
└── README.md                 # Project documentation
```

## Installation

To install the required dependencies, run:

```
pip install -r requirements.txt
```

## Usage

### Command-Line Interface

To use the CLI tool, run the following command in your terminal:

```
python -m src.cli [directory]
```

- Replace `[directory]` with the path to the directory containing the screenshot files. If no directory is specified, it will default to the current working directory.

### Streamlit Application

To run the Streamlit application, execute the following command:

```
streamlit run src/streamlit_app.py
```

This will start a local web server and open the Streamlit interface in your web browser, allowing you to select a directory and view the renaming results interactively.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.