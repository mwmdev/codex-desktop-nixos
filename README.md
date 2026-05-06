# Codex Desktop for NixOS

Nix packaging and Linux patch scripts for running the Codex Desktop Electron app on NixOS.

This repository intentionally does **not** redistribute the Codex Desktop app bundle, Electron binary, or `app.asar`. Users provide their own official/unpacked Codex Desktop bundle and this package applies the NixOS runtime fixes locally.

## What This Packages

- A Nix derivation for an unpacked Codex Desktop Electron directory.
- ASAR patches for Linux/NixOS startup behavior.
- A `codex-desktop` launcher for the native Electron app.
- A `codex-app [PATH]` detached launcher that opens a workspace via `--open-project`.
- Desktop entry and icon installation.

## Requirements

- NixOS or Nix on Linux.
- An unpacked Codex Desktop app directory containing:
  - `electron`
  - `resources/app.asar`
  - `content/webview/index.html`
- The Codex CLI available as `codex` in `PATH`, or set `CODEX_CLI_PATH`.

On Mike's machine the local source bundle was:

```bash
/home/mike/bin/codex-app
```

## Quick Build With Flakes

```bash
git clone git@github.com:mwmdev/codex-desktop-nixos.git
cd codex-desktop-nixos

CODEX_APP_DIR=/path/to/codex-app nix build --impure .#fromEnv
./result/bin/codex-app /path/to/project
```

Install into the user profile:

```bash
CODEX_APP_DIR=/path/to/codex-app nix profile install --impure .#fromEnv
codex-app /path/to/project
```

## Channel-Based NixOS

For non-flake systems, import `package.nix` directly:

```nix
{ config, pkgs, ... }:

let
  codexDesktop = pkgs.callPackage /path/to/codex-desktop-nixos/package.nix {
    codexAppSrc = /path/to/codex-app;
  };
in
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [ "codex-desktop-nixos" ];

  environment.systemPackages = [
    codexDesktop
  ];
}
```

Then:

```bash
sudo nixos-rebuild switch
codex-app ~/my-project
```

## Flake NixOS Module

```nix
{
  inputs.codex-desktop-nixos.url = "github:mwmdev/codex-desktop-nixos";

  outputs = { self, nixpkgs, codex-desktop-nixos, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        codex-desktop-nixos.nixosModules.default
        {
          programs.codex-desktop = {
            enable = true;
            bundlePath = /path/to/codex-app;
          };
        }
      ];
    };
  };
}
```

## Notes

- The package wraps the app with `libstdc++.so.6` from `stdenv.cc.cc.lib`, which fixes the native Node module loader crash seen on NixOS.
- The package sets `CODEX_ELECTRON_SKIP_SHELL_ENV=1` by default. The Electron bundle's shell environment probe can time out under NixOS desktop sessions; the launched app still inherits the wrapper environment.
- The desktop app starts its bundled webview with `python3 -m http.server`, so `python3` is included in the launcher `PATH`.
- Runtime logs are written by the app to `~/.cache/codex-desktop/launcher.log`.
- The desktop icon is installed when the bundle contains `.codex-linux/codex-desktop.png` or a matching Codex logo PNG in `content/webview/assets`.

## Legal

This repository only contains packaging and patch code. It does not grant rights to redistribute Codex Desktop binaries or OpenAI assets.
