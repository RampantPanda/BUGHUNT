#!/usr/bin/env bash

CSS="$HOME/.config/waybar/cheatsheet.css"
TEXT="$HOME/.config/waybar/cheatsheet.txt"

case "${1:-desktop}" in
    desktop) ;;
    vm) TEXT="$HOME/.config/waybar/cheatsheet-vm.txt" ;;
    *) printf 'Usage: %s [desktop|vm]\n' "$0" >&2; exit 2 ;;
esac

export GTK_THEME="Adwaita:dark"

yad \
    --text-info \
    --filename="$TEXT" \
    --center \
    --on-top \
    --undecorated \
    --no-buttons \
    --margins=36 \
    --fontname="monospace 10" \
    --css="$CSS" \
    --title="MANGOKEYBINDREFERENCE"
