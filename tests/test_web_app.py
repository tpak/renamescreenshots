"""
Tests for the Flask web application.
Tests SSE endpoint, CSRF validation, backward compatibility, and error handling.
"""
import os
import tempfile
import pytest
import json

from src.web_app import app


def create_file(path):
    """Helper to create a test file."""
    with open(path, "w") as f:
        f.write("test")


@pytest.fixture
def client():
    """Create a test client for the Flask app."""
    app.config['TESTING'] = True
    app.config['WTF_CSRF_ENABLED'] = False  # Disable CSRF for testing
    with app.test_client() as client:
        yield client


@pytest.fixture
def csrf_token():
    """Return a dummy CSRF token for testing (CSRF disabled in test mode)."""
    return "test-csrf-token"


class TestIndexRoute:
    """Tests for the index route."""

    def test_index_loads(self, client):
        """Index page should load successfully."""
        response = client.get('/')
        assert response.status_code == 200
        assert b'Screenshot Renamer' in response.data


class TestPostEndpoint:
    """Tests for the original POST /rename endpoint (backward compatibility)."""

    def test_post_endpoint_missing_directory(self, client):
        """POST without directory should return 400."""
        response = client.post('/rename',
                              json={},
                              headers={'Content-Type': 'application/json'})
        assert response.status_code == 400

    def test_post_endpoint_success(self, client, csrf_token):
        """POST with valid directory should succeed."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a test screenshot file
            create_file(os.path.join(tmpdir, "Screenshot 2024-05-24 at 1.23.45 PM.png"))

            response = client.post('/rename',
                                  json={'directory': tmpdir},
                                  headers={
                                      'Content-Type': 'application/json',
                                      'X-CSRFToken': csrf_token
                                  })
            assert response.status_code == 200
            data = json.loads(response.data)
            assert data['success'] is True
            assert data['total_files'] == 1
            assert data['renamed_files'] == 1

    def test_post_endpoint_invalid_directory(self, client, csrf_token):
        """POST with invalid directory should return 400."""
        response = client.post('/rename',
                              json={'directory': '/nonexistent/path'},
                              headers={
                                  'Content-Type': 'application/json',
                                  'X-CSRFToken': csrf_token
                              })
        assert response.status_code == 400
        data = json.loads(response.data)
        assert data['success'] is False

    def test_post_endpoint_no_directory(self, client, csrf_token):
        """POST without directory parameter should return 400."""
        response = client.post('/rename',
                              json={},
                              headers={
                                  'Content-Type': 'application/json',
                                  'X-CSRFToken': csrf_token
                              })
        assert response.status_code == 400
        data = json.loads(response.data)
        assert data['success'] is False


class TestSSEEndpoint:
    """Tests for the SSE /rename/stream endpoint."""

    def test_sse_no_directory(self, client, csrf_token):
        """SSE without directory parameter should return error."""
        response = client.get(f'/rename/stream?csrf_token={csrf_token}')
        assert response.status_code == 400
        assert b'No directory specified' in response.data

    def test_sse_streams_events(self, client, csrf_token):
        """SSE should stream progress events."""
        with tempfile.TemporaryDirectory() as tmpdir:
            # Create test files
            create_file(os.path.join(tmpdir, "Screenshot 2024-05-24 at 1.23.45 PM.png"))
            create_file(os.path.join(tmpdir, "Screenshot 2024-05-24 at 2.30.15 PM.jpg"))
            create_file(os.path.join(tmpdir, "not_a_screenshot.txt"))

            response = client.get(f'/rename/stream?directory={tmpdir}&csrf_token={csrf_token}')
            assert response.status_code == 200
            assert response.content_type == 'text/event-stream; charset=utf-8'

            # Parse SSE events
            events = []
            for line in response.data.decode('utf-8').strip().split('\n\n'):
                if line.startswith('data: '):
                    event_data = json.loads(line[6:])  # Remove 'data: ' prefix
                    events.append(event_data)

            # Check event sequence
            assert len(events) > 0
            assert events[0]['event'] == 'start'
            assert tmpdir in events[0]['directory']

            # Should have rename events for matching files
            rename_events = [e for e in events if e['event'] == 'rename']
            assert len(rename_events) == 2

            # Should have skip event for non-matching file
            skip_events = [e for e in events if e['event'] == 'skip']
            assert len(skip_events) == 1

            # Should have complete event
            complete_events = [e for e in events if e['event'] == 'complete']
            assert len(complete_events) == 1
            assert complete_events[0]['total_files'] == 3
            assert complete_events[0]['renamed_files'] == 2

    def test_sse_handles_errors(self, client, csrf_token):
        """SSE should stream error events for invalid paths."""
        response = client.get(f'/rename/stream?directory=/nonexistent/path&csrf_token={csrf_token}')
        assert response.status_code == 200

        # Parse events
        events = []
        for line in response.data.decode('utf-8').strip().split('\n\n'):
            if line.startswith('data: '):
                event_data = json.loads(line[6:])
                events.append(event_data)

        # Should have an error event
        assert len(events) > 0
        assert events[0]['event'] == 'error'

    def test_sse_respects_whitelist(self, client, csrf_token):
        """SSE should enforce directory whitelist."""
        with tempfile.TemporaryDirectory() as allowed_dir:
            with tempfile.TemporaryDirectory() as denied_dir:
                # Set whitelist via environment variable
                os.environ['SCREENSHOT_RENAMER_WHITELIST'] = allowed_dir

                try:
                    # Try to access denied directory
                    response = client.get(f'/rename/stream?directory={denied_dir}&csrf_token={csrf_token}')
                    assert response.status_code == 200

                    # Parse events
                    events = []
                    for line in response.data.decode('utf-8').strip().split('\n\n'):
                        if line.startswith('data: '):
                            event_data = json.loads(line[6:])
                            events.append(event_data)

                    # Should have error event about whitelist
                    assert len(events) > 0
                    assert events[0]['event'] == 'error'
                    assert 'whitelist' in events[0]['error'].lower() or 'not allowed' in events[0]['error'].lower()
                finally:
                    # Clean up environment
                    del os.environ['SCREENSHOT_RENAMER_WHITELIST']


class TestStreamingGenerator:
    """Tests for the streaming generator function."""

    def test_generator_yields_correct_events(self):
        """Streaming generator should yield all expected event types."""
        from src.rename_screenshots import rename_screenshots_streaming

        with tempfile.TemporaryDirectory() as tmpdir:
            # Create test files
            create_file(os.path.join(tmpdir, "Screenshot 2024-05-24 at 1.23.45 PM.png"))
            create_file(os.path.join(tmpdir, "other_file.txt"))

            events = list(rename_screenshots_streaming(tmpdir))

            # Check event types in sequence
            assert events[0]['event'] == 'start'
            assert events[-1]['event'] == 'complete'

            # Should have rename and skip events
            event_types = [e['event'] for e in events]
            assert 'rename' in event_types
            assert 'skip' in event_types

    def test_generator_maintains_security(self):
        """Streaming generator should enforce all security validations."""
        from src.rename_screenshots import rename_screenshots_streaming

        # Test with invalid directory
        with pytest.raises(FileNotFoundError):
            list(rename_screenshots_streaming('/nonexistent/path'))

    def test_generator_handles_validation_errors(self):
        """Streaming generator should yield error events for validation failures."""
        from src.rename_screenshots import rename_screenshots_streaming

        with tempfile.TemporaryDirectory() as tmpdir:
            # Create a file that will be renamed
            create_file(os.path.join(tmpdir, "Screenshot 2024-05-24 at 1.23.45 PM.png"))
            # Create the target file so rename will skip it
            create_file(os.path.join(tmpdir, "screenshot 2024-05-24 at 13.23.45.png"))

            events = list(rename_screenshots_streaming(tmpdir))

            # Should have skip event for file that already exists
            skip_events = [e for e in events if e['event'] == 'skip' and e.get('reason') == 'target_exists']
            assert len(skip_events) == 1
