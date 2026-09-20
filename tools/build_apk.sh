#!/usr/bin/env bash
# Exports the "Meta Quest" Android preset to build/threshold.apk.
# Usage: tools/build_apk.sh [debug|release]
set -euo pipefail

MODE="${1:-debug}"
GODOT_BIN="${GODOT_BIN:-/opt/godot/godot}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$PROJECT_DIR/build"

case "$MODE" in
	debug)
		"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-debug "Meta Quest" build/threshold.apk
		;;
	release)
		"$GODOT_BIN" --headless --path "$PROJECT_DIR" --export-release "Meta Quest" build/threshold.apk
		;;
	*)
		echo "Usage: $0 [debug|release]" >&2
		exit 1
		;;
esac

echo "APK written to $PROJECT_DIR/build/threshold.apk"
