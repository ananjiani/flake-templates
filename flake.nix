{
  description = "Templates";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
      ...
    }:
    let

      # Support multiple systems
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      python-uv = {
        path = ./python-uv;
        description = "Boilerplate for python uv projects";
      };

      checks = forAllSystems (system: {
        pre-commit-check = git-hooks.lib.${system}.run {
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
      });

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
          };
        }
      );
    };
}
