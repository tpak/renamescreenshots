#!/usr/bin/env python3
"""
Flask web interface for Screenshot Renamer.
Simple, beautiful, and functional.
"""

import os
from pathlib import Path

from flask import Flask, render_template, request, jsonify

from .rename_screenshots import rename_screenshots

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)


@app.route('/')
def index():
    """Render the main page."""
    default_dir = os.path.expanduser("~/Desktop/Screenshots")
    return render_template('index.html', default_directory=default_dir)


@app.route('/rename', methods=['POST'])
def rename():
    """Process the rename request."""
    data = request.get_json()
    directory = data.get('directory', '')

    if not directory:
        return jsonify({
            'success': False,
            'error': 'No directory specified'
        }), 400

    expanded_dir = os.path.expanduser(directory)

    if not os.path.isdir(expanded_dir):
        return jsonify({
            'success': False,
            'error': f'Directory does not exist: {directory}'
        }), 400

    try:
        total_files, renamed_files = rename_screenshots(expanded_dir)
        return jsonify({
            'success': True,
            'total_files': total_files,
            'renamed_files': renamed_files,
            'message': f'Successfully renamed {renamed_files} out of {total_files} files'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


def main():
    """Run the Flask application."""
    print("\n🖼️  Screenshot Renamer Web Interface")
    print("=" * 50)
    print("\nStarting server at http://localhost:5000")
    print("Press Ctrl+C to stop\n")
    app.run(debug=False, host='127.0.0.1', port=5000)


if __name__ == '__main__':
    main()
