#!/bin/sh

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/gtklock"

exec gtklock -d \
  --config "$CFG/config.ini" \
  --style "$CFG/buglock.css" \
  --layout "$CFG/layout.xml"
