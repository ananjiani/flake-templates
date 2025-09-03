# Python Guidelines & Code Quality

## Python Standards
- Python 3.13+ required
- Follow PEP 8 (enforced by ruff)
- Use type hints for all function signatures and public APIs
- Maximum line length: 88 characters (Black/ruff default)
- Keep functions short and focused on a single task

## Error Handling
- Use specific exception types rather than generic `Exception`
- Log errors effectively with context
- Handle errors gracefully with proper cleanup

## Security
- Always validate and sanitize user input
- Be mindful of potential injection vulnerabilities
- Never expose sensitive data in logs or error messages

## Quality Tools
- **ruff**: Linting and formatting (PEP 8 enforcement)
- **mypy**: Type checking
- **pytest**: Testing framework
- **pre-commit**: Git hooks for quality checks

## Pre-commit Hooks (Auto-configured)
- **Python**: ruff (linting & formatting), mypy (type checking)
- **File Hygiene**: trailing whitespace, end-of-file fixer, merge conflict check
- **Format Validation**: YAML, JSON, TOML, Python AST checking
- **Nix**: nixfmt, deadnix, statix, flake-checker
