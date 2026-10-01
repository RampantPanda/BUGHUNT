#!/usr/bin/env bash

exec swayidle -w \
    timeout 300 "$HOME/.config/gtklock/lock.sh" \
    timeout 600 "wlopm --off '*'" \
        resume "wlopm --on '*'" \
    timeout 900 "systemctl suspend" \
    before-sleep "$HOME/.config/gtklock/lock.sh" \
    after-resume "wlopm --on '*'"
