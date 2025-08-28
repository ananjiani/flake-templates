{
  description = "Python project template with modern tooling";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks.flakeModule
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        let
          python = pkgs.python313;
          setupScript = pkgs.writeScriptBin "setup" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail

            # Make hook scripts executable
            echo "Making hook scripts executable..."
            ${pkgs.findutils}/bin/find .claude/hooks -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
            echo "✓ Hook scripts made executable"

            # Note: Pre-commit hooks are automatically installed via git-hooks.nix
            # when entering the development shell

            # Success message
            echo
            echo "✅ Project initialized successfully!"
            echo
            echo "Note: Pre-commit hooks are automatically configured when you enter the dev shell."
            echo
          '';
        in
        {
          # Pre-commit hooks configuration
          pre-commit = {
            check.enable = true;
            settings = {
              hooks = {
                # Python formatters, linters, and typecheckers
                ruff.enable = true;
                ruff-format.enable = true;
                mypy.enable = true;

                # General file hygiene
                trim-trailing-whitespace.enable = true;
                end-of-file-fixer.enable = true;
                check-merge-conflicts.enable = true;
                check-added-large-files = {
                  enable = true;
                  args = [ "--maxkb=5000" ];
                };
                check-yaml.enable = true;
                check-json.enable = true;
                check-toml.enable = true;
                check-python.enable = true; # Check Python AST

                # Nix
                flake-checker.enable = true;
                nixfmt-rfc-style.enable = true;
                deadnix = {
                  enable = true;
                  settings.edit = true;
                };
                statix.enable = true;
              };
            };
          };

          apps = {
            setup = {
              type = "app";
              program = "${setupScript}/bin/setup";
            };
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [
              # Python and package management
              python
              pkgs.uv
            ]
            ++ (with pkgs.python313Packages; [
              python-lsp-server
              python-lsp-ruff
              pylsp-mypy
            ])
            # Add pre-commit enabled packages
            ++ config.pre-commit.settings.enabledPackages;

            env = {
              UV_PYTHON_DOWNLOADS = "never";
              UV_PYTHON = python.interpreter;
            };

            shellHook = ''
              # Run the pre-commit shellHook first
              ${config.pre-commit.installationScript}

              # Check if this is a fresh template
              if [ ! -f "pyproject.toml" ]; then
                echo "═══════════════════════════════════════════════════════════"
                echo "🚀 Welcome! This is a fresh Python project."
                echo "   Run 'uv init' then 'nix run .#setup' to initialize your project."
                echo "═══════════════════════════════════════════════════════════"
                echo ""
              fi

              echo "🐍 Python Development Environment"
              echo "Python: ${python.version}"

              # Set up environment
              unset PYTHONPATH
              export PYTHONPATH="$PWD:$PYTHONPATH"

              # Python virtual environment setup
              if [[ ! -d .venv ]]; then
                echo "Creating Python virtual environment..."
                uv venv
                uv sync
              else
                source .venv/bin/activate
                # Only sync if pyproject.toml is newer than .venv
                if [[ pyproject.toml -nt .venv ]]; then
                  echo "Dependencies may have changed, running uv sync..."
                  uv sync
                fi
              fi
            '';
          };

        };
    };
}
