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

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

printf 'Codex Desktop bundle looks usable: %s\n' "$bundle"
