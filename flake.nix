{
  description = "varlock - AI-safe .env files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        let
          unwrapped = pkgs.callPackage ./package.nix { };
          varlock = pkgs.callPackage ./wrapper.nix { } { package = unwrapped; };
        in
        {
          packages = {
            inherit varlock;
            varlock-unwrapped = unwrapped;
            default = varlock;
          };

          checks.wrapper = import ./checks/wrapper.nix { inherit pkgs; };
        };

      flake = {
        overlays.default = final: prev: {
          varlock-unwrapped = final.callPackage ./package.nix { };
          varlock = final.callPackage ./wrapper.nix { } { package = final.varlock-unwrapped; };
        };

        homeManagerModules.default = import ./home-module.nix;
      };
    };
}
