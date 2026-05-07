# Codex Desktop for NixOS

Nix packaging for running a user-provided Codex Desktop Electron bundle on NixOS.

This repo does not contain the Codex Desktop app, Electron binary, `app.asar`, or OpenAI assets. It only contains Nix packaging and local patch scripts. Each user must provide their own unpacked official Codex Desktop bundle.

## Requirements

- NixOS or Nix on Linux.
- An unpacked Codex Desktop directory with:
  - `electron`
  - `resources/app.asar`
  - `content/webview/index.html`
- The Codex CLI available in `PATH`, or pass `codexCliPath` in NixOS config.

## Quick Test

```bash
git clone git@github.com:mwmdev/codex-desktop-nixos.git
cd codex-desktop-nixos

scripts/verify-local-bundle.sh /path/to/codex-app
CODEX_APP_DIR=/path/to/codex-app nix build --impure .#fromEnv
./result/bin/codex-app ~/my-project
```

## Install With Nix Profile

```bash
CODEX_APP_DIR=/path/to/codex-app nix profile install --impure .#fromEnv
codex-app ~/my-project
```

## Install On Channel-Based NixOS

Add this to your NixOS configuration:

```nix
{ config, pkgs, ... }:

let
  codexDesktop = pkgs.callPackage /path/to/codex-desktop-nixos/package.nix {
    codexAppSrc = /path/to/codex-app;
    # codexCliPath = "/home/alice/.npm-global/bin/codex";
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

Then rebuild:

```bash
sudo nixos-rebuild switch
codex-app ~/my-project
```

## Install With A Flake NixOS Module

```nix
{
  inputs.codex-desktop-nixos.url = "github:mwmdev/codex-desktop-nixos";

  outputs = { nixpkgs, codex-desktop-nixos, ... }: {
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

## Updating Codex Desktop

When the official Codex Desktop app updates, update the local bundle and rebuild the package.

Update flow:

```bash
scripts/verify-local-bundle.sh /path/to/codex-app
CODEX_APP_DIR=/path/to/codex-app nix build --impure .#fromEnv
./result/bin/codex-app --help
```

If that passes, rebuild NixOS:

```bash
sudo nixos-rebuild switch
```

If the build fails while patching `app.asar`, the official bundle internals changed. Update the patch scripts in `patches/`, commit that change, then rebuild. The package is designed to fail loudly instead of silently producing a broken app.

Runtime logs are written by the app to:

```text
~/.cache/codex-desktop/launcher.log
```

## License

The packaging code in this repository is MIT licensed. Codex Desktop binaries and OpenAI assets are not redistributed or licensed by this repository.
