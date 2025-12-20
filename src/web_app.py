#!/usr/bin/env python3
"""
Flask web interface for Screenshot Renamer.
Simple, beautiful, and functional.
"""

import os
import secrets
from pathlib import Path

from flask import Flask, render_template, request, jsonify
from flask_wtf.csrf import CSRFProtect

from .rename_screenshots import rename_screenshots

app = Flask(__name__)

# Use environment variable for SECRET_KEY, or generate a secure random key
# For production, always set SCREENSHOT_RENAMER_SECRET_KEY environment variable
SECRET_KEY = os.environ.get('SCREENSHOT_RENAMER_SECRET_KEY')
if not SECRET_KEY:
    # Generate a secure random key for development
    SECRET_KEY = secrets.token_hex(32)
    print("⚠️  WARNING: Using randomly generated SECRET_KEY. Set SCREENSHOT_RENAMER_SECRET_KEY environment variable for production.")

app.config['SECRET_KEY'] = SECRET_KEY
app.config['WTF_CSRF_TIME_LIMIT'] = None  # CSRF tokens don't expire (simple single-user app)

# Enable CSRF protection
csrf = CSRFProtect(app)


@app.route('/')
def index():
    """Render the main page."""
    default_dir = os.path.expanduser("~/Desktop/Screenshots")
    # CSRF token is automatically made available in templates by Flask-WTF
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

    try:
        # The rename_screenshots function now handles all validation
        total_files, renamed_files = rename_screenshots(directory)
        return jsonify({
            'success': True,
            'total_files': total_files,
            'renamed_files': renamed_files,
            'message': f'Successfully renamed {renamed_files} out of {total_files} files'
        })
    except (ValueError, FileNotFoundError, NotADirectoryError) as e:
        # User input errors - 400 Bad Request
        return jsonify({
            'success': False,
            'error': str(e)
        }), 400
    except PermissionError as e:
        # Permission errors - 403 Forbidden
        return jsonify({
            'success': False,
            'error': str(e)
        }), 403
    except Exception as e:
        # Unexpected errors - 500 Internal Server Error
        return jsonify({
            'success': False,
            'error': f'Unexpected error: {str(e)}'
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
