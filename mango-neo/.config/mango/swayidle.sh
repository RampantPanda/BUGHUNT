#!/usr/bin/env bash

exec swayidle -w \
    timeout 300 "hyprlock" \
    timeout 600 "wlopm --off '*'" \
        resume "wlopm --on '*'" \
    timeout 900 "systemctl suspend" \
    before-sleep "hyprlock" \
    after-resume "wlopm --on '*'"
