#!/usr/bin/env bash
# Export the Windows x86_64 build. Godot can cross-export this from macOS.
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
OUT="${OUT:-$HOME/Builds}"
EXE="$OUT/Amalgaform.exe"
ZIP="$OUT/Amalgaform-Windows.zip"

if [ ! -x "$GODOT" ]; then
	echo "Godot not found or not executable: $GODOT" >&2
	exit 1
fi

mkdir -p "$OUT"
echo "==> export Windows x86_64"
"$GODOT" --headless --path . --export-release "Windows Desktop" "$EXE"
echo "==> package $ZIP"
rm -f "$ZIP"
zip -j "$ZIP" "$EXE"
echo "Windows build ready: $ZIP"
