{
  description = "A very basic flake";

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
      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };
      overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };
      pyprojectOverrides = _final: _prev:
        {
          # Implement build fixups here.
          # Note that uv2nix is _not_ using Nixpkgs buildPythonPackage.
          # It's using https://pyproject-nix.github.io/pyproject.nix/build.html
        };
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
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
      packages.x86_64-linux = {
        default = (pythonSet.mkVirtualEnv "fastapi-run-env"
          workspace.deps.default).overrideAttrs
          (old: { venvIgnoreCollisions = [ "*" ]; });
        docker = let
          venv = (pythonSet.mkVirtualEnv "fastapi-run-env"
            workspace.deps.default).overrideAttrs
            (old: { venvIgnoreCollisions = [ "*" ]; });
        in pkgs.dockerTools.buildLayeredImage {
          name = "spatial-jobs-index-api";
          tag = "latest";
          contents = [ venv pkgs.bash pkgs.coreutils ];
          config = {
            Cmd = [
              "${venv}/bin/uvicorn"
              "app.main:app"
              "--host"
              "0.0.0.0"
              "--port"
              "8000"
            ];
            WorkingDir = "/app";
            ExposedPorts = { "8000/tcp" = { }; };
            # Entrypoint = [ "${venv}/bin/python" ];
            # Env = [ "PYTHONPATH=${venv}/lib/python3.13/site-packages" ];
          };
        };
      };

      apps.x86_64-linux.default = {
        type = "app";
        program = "./result/bin/fastapi";
      };
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = [ python pkgs.ruff pkgs.uv ]
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
          unset PYTHONPATH
        '';

      };

    };
}
