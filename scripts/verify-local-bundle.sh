#!/usr/bin/env bash
set -euo pipefail

bundle="${1:-${CODEX_APP_DIR:-}}"

if [[ -z "$bundle" ]]; then
  printf 'usage: %s /path/to/codex-app\n' "$0" >&2
  printf 'or set CODEX_APP_DIR=/path/to/codex-app\n' >&2
  exit 2
fi

missing=0
for path in \
  "$bundle/electron" \
  "$bundle/resources/app.asar" \
  "$bundle/content/webview/index.html"
do
  if [[ ! -e "$path" ]]; then
    printf 'missing: %s\n' "$path" >&2
    missing=1
  fi
done

marketplace="$bundle/resources/plugins/openai-bundled/.agents/plugins/marketplace.json"
if [[ ! -f "$marketplace" ]]; then
  marketplace="$bundle/resources/app.asar.unpacked/plugins/openai-bundled/.agents/plugins/marketplace.json"
fi

if [[ ! -f "$marketplace" ]]; then
  printf 'missing: %s\n' "$bundle/resources/plugins/openai-bundled/.agents/plugins/marketplace.json" >&2
  printf 'Browser use needs the official resources/plugins/openai-bundled directory.\n' >&2
  missing=1
else
  bundled_root="$(dirname "$(dirname "$(dirname "$marketplace")")")"
  browser_plugin="$bundled_root/plugins/browser-use"

  if ! grep -q '"name"[[:space:]]*:[[:space:]]*"openai-bundled"' "$marketplace"; then
    printf 'invalid marketplace name: %s\n' "$marketplace" >&2
    missing=1
  fi

  if ! grep -q '"name"[[:space:]]*:[[:space:]]*"browser-use"' "$marketplace"; then
    printf 'missing browser-use entry: %s\n' "$marketplace" >&2
    missing=1
  fi

  for path in \
    "$browser_plugin/.codex-plugin/plugin.json" \
    "$browser_plugin/scripts/browser-client.mjs"
  do
    if [[ ! -e "$path" ]]; then
      printf 'missing: %s\n' "$path" >&2
      missing=1
    fi
  done
fi

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

printf 'Codex Desktop bundle looks usable: %s\n' "$bundle"
