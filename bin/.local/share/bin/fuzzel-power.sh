#!/usr/bin/env bash

choice=$(printf '%s\n' \
    "LCKSCR" \
    "LOGOUT" \
    "SUSPND" \
    "REBOOT" \
    "PWROFF"  |
    fuzzel --dmenu \
        --prompt="> " \
        --mesg="SYSTEM CONTROL" \
        --lines=5 \
        --width=20)

case "$choice" in
    "LCKSCR")
        "gtklock"
        ;;
    "Power")
        "$HOME/.local/share/bin/power-menu"
        ;;
    "Screenshots")
        "$HOME/.local/share/bin/screenshot-menu"
        ;;
esac
