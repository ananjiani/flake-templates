{
  description = "Python project template with modern tooling";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ruler = {
      url = "github:intellectronica/ruler";
      flake = false;
    };
    tdd-guard = {
      url = "github:nizos/tdd-guard";
      flake = false;
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

            # Initialize project with uv first
            echo "Initializing project with uv..."
            uv init

            # Extract project name from pyproject.toml and add to .serena/project.yml
            if [ -f pyproject.toml ] && [ -f .serena/project.yml ]; then
              PROJECT_NAME=$(grep '^name = ' pyproject.toml | sed 's/name = "\(.*\)"/\1/')
              if [ ! -z "$PROJECT_NAME" ]; then
                echo "Setting project name in Serena config: $PROJECT_NAME"
                # Add project_name at the end of the file
                echo "" >> .serena/project.yml
                echo "# Project name from uv init" >> .serena/project.yml
                echo "project_name: $PROJECT_NAME" >> .serena/project.yml
                echo "✓ Added project name to .serena/project.yml"
              fi
            fi

            # Make hook scripts executable
            echo "Making hook scripts executable..."
            ${pkgs.findutils}/bin/find .claude/hooks -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
            echo "✓ Hook scripts made executable"

            # Add .env to .gitignore if not already present
            if [ -f .gitignore ]; then
              if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
                echo "Adding .env to .gitignore..."
                echo ".env" >> .gitignore
                echo "✓ Added .env to .gitignore"
              else
                echo "✓ .env already in .gitignore"
              fi
            else
              echo "Creating .gitignore with .env..."
              echo ".env" > .gitignore
              echo "✓ Created .gitignore with .env"
            fi

            # Extract project name from pyproject.toml and add to .serena/project.yml
            if [ -f pyproject.toml ] && [ -f .serena/project.yml ]; then
              PROJECT_NAME=$(grep '^name = ' pyproject.toml | sed 's/name = "\(.*\)"/\1/')
              if [ ! -z "$PROJECT_NAME" ]; then
                echo "Setting project name in Serena config: $PROJECT_NAME"
                # Add project_name at the end of the file
                echo "" >> .serena/project.yml
                echo "# Project name from uv init" >> .serena/project.yml
                echo "project_name: $PROJECT_NAME" >> .serena/project.yml
                echo "✓ Added project name to .serena/project.yml"
              fi
            fi
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
                mypy = {
                  enable = true;
                  entry = "${pkgs.uv}/bin/uv run mypy";
                };

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

          devShells.default =
            let
              # Build ruler CLI tool (auto-updating from flake input)
              ruler-pkg = pkgs.buildNpmPackage {
                pname = "ruler";
                version = "latest";

                src = inputs.ruler;

                npmDepsHash = "sha256-XRcVHK45qBUVXsrHSGS88aJ8XMRR+5eQ+jgwBEmgnc8=";

                # The package has a prepare script that runs the build
                npmBuildScript = "build";

                meta = {
                  description = "Centralise Your AI Coding Assistant Instructions";
                  homepage = "https://github.com/intellectronica/ruler";
                };
              };

              # Build tdd-guard CLI tool (auto-updating from flake input)
              tdd-guard-pkg = pkgs.buildNpmPackage {
                pname = "tdd-guard";
                version = "latest";

                src = inputs.tdd-guard;

                npmDepsHash = "sha256-IAL1Puc+BzXVYPp3+7iS9Qgp8yVjkyvjmFW4gkumYVA=";

                # The package has a build script
                npmBuildScript = "build";

                # Skip the postinstall scripts that try to download native bindings
                npmFlags = [ "--ignore-scripts" ];

                # Make sure the binary is executable
                postInstall = ''
                  chmod +x $out/bin/tdd-guard
                  # Remove broken symlinks that cause build failure
                  rm -f $out/lib/node_modules/tdd-guard/node_modules/tdd-guard-vitest
                  rm -f $out/lib/node_modules/tdd-guard/node_modules/tdd-guard-jest
                '';

                meta = {
                  description = "Test-Driven Development Guard for monitoring and running tests";
                  homepage = "https://github.com/nizos/tdd-guard";
                };
              };
            in
            pkgs.mkShell {
              buildInputs = [
                # Python and package management
                python
                pkgs.uv
                ruler-pkg
                tdd-guard-pkg

                # System libraries for numpy/pandas
                pkgs.stdenv.cc.cc.lib
                pkgs.zlib
              ]
              ++ (with pkgs.python313Packages; [
                debugpy
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
                  echo "   Run 'nix run .#setup' to initialize your project."
                  echo "═══════════════════════════════════════════════════════════"
                  echo ""
                fi

                echo "🐍 Python Development Environment"
                echo "Python: ${python.version}"

                # Set up environment
                unset PYTHONPATH
                export PYTHONPATH="$PWD:$PYTHONPATH"

                # Set LD_LIBRARY_PATH for numpy and other C extensions
                export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:$LD_LIBRARY_PATH"

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
