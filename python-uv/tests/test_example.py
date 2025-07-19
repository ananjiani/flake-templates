"""Example tests for PROJECT_NAME."""

import pytest

from PROJECT_NAME.__main__ import main


@pytest.mark.unit
def test_main_returns_zero():
    """Test that main function returns 0."""
    assert main() == 0


@pytest.mark.unit
def test_version():
    """Test that version is accessible."""
    from PROJECT_NAME import __version__

    assert __version__ == "0.1.0"
