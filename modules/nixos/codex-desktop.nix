{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.codex-desktop;
  package =
    if cfg.package != null then
      cfg.package
    else
      pkgs.callPackage ../../package.nix {
        codexAppSrc = cfg.bundlePath;
        codexCliPath = cfg.codexCliPath;
      };
in
{
  options.programs.codex-desktop = {
    enable = lib.mkEnableOption "Codex Desktop";

    bundlePath = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/home/alice/bin/codex-app";
      description = "Path to an unpacked Codex Desktop app bundle.";
    };

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Prebuilt Codex Desktop package. Overrides bundlePath when set.";
    };

    codexCliPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/alice/.npm-global/bin/codex";
      description = "Optional absolute path to the Codex CLI used by the desktop app.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.package != null || cfg.bundlePath != null;
        message = "programs.codex-desktop.bundlePath or programs.codex-desktop.package must be set.";
      }
    ];

    environment.systemPackages = [ package ];
  };
}
