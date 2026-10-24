#!/usr/bin/env bash

set -e

echo "NEO desktop settings:"

# GTK icon theme:
gsettings set org.gnome.desktop.interface icon-theme 'Neo-Wire'

# XFCE/Thunar icon theme:
if command -v xfconf-query >/dev/null 2>&1; then
    if xfconf-query \
        -c xsettings \
        -p /Net/IconThemeName >/dev/null 2>&1
    then
        xfconf-query \
            -c xsettings \
            -p /Net/IconThemeName \
            -s Neo-Wire
    else
        xfconf-query \
            -c xsettings \
            -p /Net/IconThemeName \
            --create \
            -t string \
            -s Neo-Wire
    fi
fi

# Rebuild icon cache
gtk-update-icon-cache -f \
    "$HOME/.local/share/icons/Neo-Wire" \
    >/dev/null 2>&1 || true

echo "NEO icon theme apply complete."
