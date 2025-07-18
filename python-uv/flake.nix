{
  description = "Python project template with modern tooling";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, uv2nix, pyproject-nix, pyproject-build-systems, ... }:
    let
      inherit (nixpkgs) lib;

      # Support multiple systems
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
      overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
      pyprojectOverrides = _final: _prev:
        {
          # Implement build fixups here.
          # Note that uv2nix is _not_ using Nixpkgs buildPythonPackage.
          # It's using https://pyproject-nix.github.io/pyproject.nix/build.html
        };
    in {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          python = pkgs.python313;

          # Construct package set
          pythonSet =
            # Use base package set from pyproject.nix builders
            (pkgs.callPackage pyproject-nix.build.packages {
              inherit python;
            }).overrideScope (lib.composeManyExtensions [
              pyproject-build-systems.overlays.default
              overlay
              pyprojectOverrides
            ]);
        in {
          default = pkgs.mkShell {
            buildInputs = [
              # Python and package management
              python
              pkgs.uv

              # Development tools
              pkgs.ruff
              pkgs.just
              pkgs.watchexec
              pkgs.git
              pkgs.pre-commit
            ]
            ++ (with pkgs.python313Packages; [
              mypy
              python-lsp-server
              python-lsp-ruff
              pylsp-mypy
            ]);

            env = {
              UV_PYTHON_DOWNLOADS = "never";
              UV_PYTHON = python.interpreter;
            };

            shellHook = ''
              # Check if this is a fresh template
              if [ -d "PROJECT_NAME" ] && [ ! -f ".setup-complete" ]; then
                echo "═══════════════════════════════════════════════════════════"
                echo "🚀 Welcome! This is a fresh Python project template."
                echo "   Run 'just setup' to initialize your project."
                echo "═══════════════════════════════════════════════════════════"
                echo ""
              fi

              echo "🐍 Python Development Environment"
              echo "Python: ${python.version}"
              echo ""
              echo "Available commands:"
              echo "  just          - Show available development tasks"
              echo "  just install  - Install Python dependencies"
              echo "  just test     - Run tests"
              echo "  just lint     - Run linters"
              echo "  just check    - Run all checks"
              echo ""
              echo ""

              # Set up environment
              unset PYTHONPATH
              export PYTHONPATH="$PWD:$PYTHONPATH"
            '';
          };
        });
    };
}
