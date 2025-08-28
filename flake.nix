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

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.git-hooks.flakeModule
      ];

      flake = {
        templates = {
          python-uv = {
            path = ./python-uv;
            description = "Boilerplate for python uv projects";
          };
        };
      };

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          ...
        }:
        {
          pre-commit = {
            check.enable = true;
            settings = {
              enable = true;
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
                nixfmt-rfc-style.enable = true;
                deadnix = {
                  enable = true;
                  settings.edit = true;
                };
                statix.enable = true;
              };
            };
          };
          devShells.default = config.pre-commit.devShell;
        };

    };
}
