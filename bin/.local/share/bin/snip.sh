#!/usr/bin/env bash
set -euo pipefail

mode=${1:-region}
args=()
case "$mode" in
    region)
        # Cancellation must not fall through to a full-screen capture.
        geometry=$(slurp) || exit 0
        [[ -n "$geometry" ]] || exit 0
        args=(-g "$geometry")
        ;;
    full) ;;
    *) printf 'Usage: %s [region|full]\n' "$0" >&2; exit 2 ;;
esac

directory="$HOME/Pictures/Screenshots"
mkdir -p "$directory"
file="$directory/$(date +%Y-%m-%d_%H-%M-%S-%N).png"
if grim "${args[@]}" "$file"; then
    notify-send 'SCREEN CAPTURE' "Saved: $file"
else
    notify-send -u critical 'SCREEN CAPTURE FAILED' 'No screenshot was saved.'
    exit 1
fi
