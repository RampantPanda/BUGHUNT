#!/usr/bin/env bash

CSS="$HOME/.config/waybar/cheatsheet.css"
TEXT="$HOME/.config/waybar/cheatsheet.txt"

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
