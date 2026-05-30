#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "Building vscode..."
export NIXPKGS_ALLOW_UNFREE=1
OUT=$(nix build --impure --no-link --print-out-paths .#vscode)

BIN="$OUT/bin/code"
if [ ! -x "$BIN" ]; then
	# darwin layout
	BIN="$OUT/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
fi

echo "Running: $BIN --version"
"$BIN" --version
