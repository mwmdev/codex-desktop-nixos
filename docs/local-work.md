# Local Work Captured

These are the local changes that informed this package.

## Current Machine

- Local app bundle: `/home/mike/bin/codex-app`
- Patched launcher: `/home/mike/bin/codex-app/start.sh`
- Patched ASAR: `/home/mike/bin/codex-app/resources/app.asar`
- Original ASAR backup: `/home/mike/bin/codex-app/resources/app.asar.bak-original`
- Local CLI wrapper: `/home/mike/.local/bin/codex`
- Local desktop entry: `/home/mike/.local/share/applications/codex-desktop.desktop`

## Fixes Generalized Into This Package

- Patch ASAR bootstrap failure logging so native module loader errors are visible.
- Patch ASAR main startup to skip the shell environment hydration timeout when `CODEX_ELECTRON_SKIP_SHELL_ENV=1`.
- Add `libstdc++.so.6` via the Nix wrapper `LD_LIBRARY_PATH`.
- Add `python3`, shell utilities, and `setsid` to launcher `PATH`.
- Launch workspaces through the app's native `--open-project` argument.
