# Development Commands

## Running Python Code
```bash
# Run any Python script
uv run path/to/script.py

# Run Python modules
uv run -m module_name

# Run with specific Python version
uv run --python 3.13 script.py
```

## Running Tests
```bash
# Run all tests
uv run pytest

# Run tests with TDD guard (auto-reruns on file changes)
uv run pytest --tdd

# Run specific test file
uv run pytest tests/test_module.py

# Run with coverage
uv run pytest --cov

# Run with verbose output
uv run pytest -v

# Run only tests matching a pattern
uv run pytest -k "test_pattern"
```

## Code Quality
```bash
# Format code with ruff
uv run ruff format .

# Lint code with ruff
uv run ruff check --fix .

# Type check with mypy
uv run mypy .

# Run all pre-commit hooks
pre-commit run --all-files

# Install pre-commit hooks
pre-commit install
```

## Dependency Management
```bash
# Add a runtime dependency
uv add package-name

# Add a development dependency
uv add --dev package-name

# Install all dependencies
uv sync

# Update dependencies
uv lock --upgrade

# Show installed packages
uv pip list

# Remove a dependency
uv remove package-name
```

## Project Setup
```bash
# Initialize a new Python project
uv init

# Create virtual environment
uv venv

# Install project in editable mode
uv pip install -e .

# Install with all extras
uv pip install -e ".[dev,test,docs]"
```

## Development Workflow
1. **Environment Setup**: Project uses Nix flakes with direnv for automatic environment activation
2. **Virtual Environment**: Managed automatically by uv, no manual activation needed
3. **Pre-commit Hooks**: Automatically run on git commit to ensure code quality
4. **Dependencies**: All Python dependencies managed through `pyproject.toml` and `uv.lock`
5. **Testing**: Run tests frequently during development using TDD guard mode
