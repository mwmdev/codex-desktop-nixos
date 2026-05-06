{
  description = "NixOS packaging for a user-provided Codex Desktop Electron bundle";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkFromEnv =
        pkgs:
        let
          codexAppDir = builtins.getEnv "CODEX_APP_DIR";
        in
        if codexAppDir == "" then
          throw "Set CODEX_APP_DIR=/path/to/unpacked/codex-app and use --impure"
        else
          pkgs.callPackage ./package.nix {
            codexAppSrc = builtins.path {
              path = codexAppDir;
              name = "codex-app-src";
            };
          };
    in
    {
      packages = forEachSystem (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          fromEnv = mkFromEnv pkgs;
          default = mkFromEnv pkgs;
        }
      );

      overlays.default = final: prev: {
        codex-desktop-nixos = final.callPackage ./package.nix { };
      };

      nixosModules.default = import ./modules/nixos/codex-desktop.nix;
    };
}
