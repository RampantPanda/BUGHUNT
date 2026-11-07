#!/usr/bin/env bash

exec swayidle -w \
    timeout 300 "hyprlock --grace 0" \
    timeout 600 "wlopm --off '*'" \
        resume "wlopm --on '*'" \
    timeout 900 "systemctl suspend" \
    before-sleep "hyprlock --grace 0" \
    after-resume "wlopm --on '*'"
