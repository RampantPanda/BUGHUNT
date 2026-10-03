#!/usr/bin/env bash
# Explicit package list: mango-vm conflicts with mango; scripts is not a package.
set -euo pipefail
dotfiles_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
exec stow --dir="$dotfiles_dir" --target="$HOME" --restow "$@" \
    bin colors cursors eww fastfetch fonts fuzzel geany gtk gtklock \
    kitty mango starship swaync tofi waybar
