{
  description = "Templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      flake = {
        templates = {
          python-uv = {
            path = ./python-uv;
            description = "Boilerplate for python uv projects";
          };
        };
      };

      perSystem = { config, pkgs, system, ... }: {
        checks = {
          pre-commit-check = inputs.git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
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
              flake-checker.enable = true;
              # nix-fmt-rfc-style.enable = true;
              deadnix.enable = true;
              statix.enable = true;
            };
          };
        };

        devShells = {
          default = pkgs.mkShell {
            inherit (config.checks.pre-commit-check) shellHook;
            buildInputs = config.checks.pre-commit-check.enabledPackages;
          };
        };
      };
    };
}
