#!/usr/bin/env bash
set -euo pipefail

bundle="${1:-${CODEX_APP_DIR:-}}"

if [[ -z "$bundle" ]]; then
  printf 'usage: %s /path/to/codex-app\n' "$0" >&2
  printf 'or set CODEX_APP_DIR=/path/to/codex-app\n' >&2
  exit 2
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

"$script_dir/verify-local-bundle.sh" "$bundle"

CODEX_APP_DIR="$bundle" nix build --impure "$repo_root#fromEnv"

printf 'Built package at %s/result\n' "$repo_root"
