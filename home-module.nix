{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.varlock;
in
{
  options.programs.varlock = {
    enable = lib.mkEnableOption "varlock - AI-safe .env files";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix { };
      defaultText = lib.literalExpression "pkgs.callPackage ./package.nix { }";
      description = "The varlock package to use.";
    };

    enableBinSymlink = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.isLinux;
      description = ''
        Whether to create a symlink at ~/.local/bin/varlock.
        Enabled by default on Linux to ensure the binary is in a standard location.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".local/bin/varlock" = lib.mkIf cfg.enableBinSymlink {
      source = "${cfg.package}/bin/varlock";
    };
  };
}
