{
  lib,
  stdenvNoCC,
  stdenv,
  asar,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  bashNonInteractive,
  cairo,
  coreutils,
  cups,
  dbus,
  expat,
  gawk,
  glib,
  gnugrep,
  gnused,
  gtk3,
  libdrm,
  libgbm,
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxtst,
  libxcb,
  libxshmfence,
  makeWrapper,
  nspr,
  nss,
  nodejs,
  pango,
  python3,
  systemdLibs,
  util-linux,
  codexAppSrc ? null,
  codexCliPath ? null,
}:

let
  runtimePath = lib.makeBinPath [
    bashNonInteractive
    coreutils
    gawk
    gnugrep
    gnused
    python3
    util-linux
  ];

  runtimeLibPath = lib.makeLibraryPath [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libxkbcommon
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemdLibs
    libx11
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxtst
    libxcb
    libxshmfence
  ];

  maybeCodexCli =
    if codexCliPath == null then
      ""
    else
      "--set-default CODEX_CLI_PATH ${lib.escapeShellArg codexCliPath}";
in
if codexAppSrc == null then
  throw "codexAppSrc is required. Pass an unpacked Codex Desktop bundle path, e.g. pkgs.callPackage ./package.nix { codexAppSrc = /path/to/codex-app; }"
else
  stdenvNoCC.mkDerivation {
    pname = "codex-desktop-nixos";
    version = "local";

    src = codexAppSrc;

    nativeBuildInputs = [
      asar
      makeWrapper
      nodejs
    ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/opt/codex-app"
      cp -R . "$out/opt/codex-app"
      chmod -R u+w "$out/opt/codex-app"

      test -x "$out/opt/codex-app/electron"
      test -f "$out/opt/codex-app/resources/app.asar"
      test -f "$out/opt/codex-app/content/webview/index.html"

      bundled_marketplace="$out/opt/codex-app/resources/plugins/openai-bundled/.agents/plugins/marketplace.json"
      if [ ! -f "$bundled_marketplace" ]; then
        bundled_marketplace="$out/opt/codex-app/resources/app.asar.unpacked/plugins/openai-bundled/.agents/plugins/marketplace.json"
      fi

      if [ ! -f "$bundled_marketplace" ]; then
        cat >&2 <<'EOF'
      error: missing Codex bundled plugin marketplace.

      Browser use requires the official bundle directory:
        resources/plugins/openai-bundled

      Recreate the Codex app bundle from the official desktop app extraction,
      keeping resources/plugins/openai-bundled alongside resources/app.asar.
      EOF
        exit 1
      fi

      bundled_root="$(dirname "$(dirname "$(dirname "$bundled_marketplace")")")"
      node - "$bundled_marketplace" "$bundled_root" <<'NODE'
      const fs = require("node:fs");
      const path = require("node:path");

      const marketplacePath = process.argv[2];
      const marketplaceRoot = process.argv[3];
      const marketplace = JSON.parse(fs.readFileSync(marketplacePath, "utf8"));

      if (marketplace.name !== "openai-bundled") {
        throw new Error("expected marketplace name openai-bundled");
      }

      const browserUse = marketplace.plugins.find((plugin) => plugin.name === "browser-use");
      if (!browserUse?.source?.path) {
        throw new Error("openai-bundled marketplace does not list browser-use");
      }

      const pluginRoot = path.resolve(marketplaceRoot, browserUse.source.path);
      const pluginManifestPath = path.join(pluginRoot, ".codex-plugin", "plugin.json");
      const browserClientPath = path.join(pluginRoot, "scripts", "browser-client.mjs");
      const pluginManifest = JSON.parse(fs.readFileSync(pluginManifestPath, "utf8"));

      if (pluginManifest.name !== "browser-use") {
        throw new Error("browser-use plugin manifest has the wrong name");
      }

      if (!fs.existsSync(browserClientPath)) {
        throw new Error("browser-use plugin is missing scripts/browser-client.mjs");
      }
      NODE

      rm -f "$out/opt/codex-app/resources/app.asar.bak-original"

      mkdir app-asar
      asar extract "$out/opt/codex-app/resources/app.asar" app-asar

      bootstrap_js="$(find app-asar/.vite/build -maxdepth 1 -type f -name 'bootstrap*.js' | head -n 1)"
      main_js="$(find app-asar/.vite/build -maxdepth 1 -type f -name 'main*.js' | head -n 1)"

      test -n "$bootstrap_js"
      test -n "$main_js"

      node ${./patches/patch-bootstrap-import-logging.mjs} "$bootstrap_js"
      node ${./patches/patch-linux-skip-shell-env-timeout.mjs} "$main_js"

      asar pack app-asar "$out/opt/codex-app/resources/app.asar"

      patchShebangs "$out/opt/codex-app/start.sh"

      makeWrapper "$out/opt/codex-app/start.sh" "$out/bin/codex-desktop" \
        --prefix PATH : ${lib.escapeShellArg runtimePath} \
        --prefix LD_LIBRARY_PATH : "$out/opt/codex-app:${runtimeLibPath}" \
        --set-default CODEX_ELECTRON_SKIP_SHELL_ENV 1 \
        --set-default CODEX_ELECTRON_BUNDLED_PLUGINS_RESOURCES_PATH "$out/opt/codex-app/resources" \
        ${maybeCodexCli}

      mkdir -p "$out/bin"
      cat > "$out/bin/codex-app" <<EOF
      #!${bashNonInteractive}/bin/bash
      set -euo pipefail

      workspace="\''${1:-.}"
      if [ "\''${1:-}" = "--help" ] || [ "\''${1:-}" = "-h" ]; then
        printf 'usage: codex-app [PATH]\n'
        exit 0
      fi

      if [ "\$#" -gt 1 ]; then
        printf 'usage: codex-app [PATH]\n' >&2
        exit 2
      fi

      workspace="\$(${coreutils}/bin/realpath "\$workspace" 2>/dev/null || printf '%s' "\$workspace")"

      if ! ${util-linux}/bin/setsid -f "$out/bin/codex-desktop" --open-project "\$workspace"; then
        ${coreutils}/bin/nohup "$out/bin/codex-desktop" --open-project "\$workspace" >/dev/null 2>&1 &
      fi
      EOF
      chmod +x "$out/bin/codex-app"

      icon_source=""
      for candidate in \
        "$out/opt/codex-app/.codex-linux/codex-desktop.png" \
        "$out/opt/codex-app"/content/webview/assets/codex-app*-logo*.png
      do
        if [ -f "$candidate" ]; then
          icon_source="$candidate"
          break
        fi
      done

      if [ -n "$icon_source" ]; then
        install -Dm644 "$icon_source" \
          "$out/share/icons/hicolor/256x256/apps/codex-desktop.png"
      fi

      mkdir -p "$out/share/applications"
      cat > "$out/share/applications/codex-desktop.desktop" <<EOF
      [Desktop Entry]
      Type=Application
      Name=Codex
      Comment=Open Codex Desktop
      Exec=$out/bin/codex-app %f
      Icon=codex-desktop
      Terminal=false
      Categories=Development;IDE;
      StartupWMClass=codex-desktop
      EOF

      runHook postInstall
    '';

    meta = {
      description = "NixOS wrapper for a user-provided Codex Desktop Electron bundle";
      homepage = "https://github.com/openai/codex";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "codex-app";
    };
  }
