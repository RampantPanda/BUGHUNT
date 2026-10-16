# Bughunt Neo Icons

Thin cyan outlines, transparent interiors, and clipped folder corners. The
18 custom icons cover folders, navigation, devices, and generic files; other
icons inherit from Adwaita and hicolor.

Regenerate from `primary` in `colors-neo/.config/colors/colors.css`:

```sh
python3 scripts/build-gtk-icons.py --neo
gtk-update-icon-cache --force --ignore-theme-index gtk-neo/.local/share/icons/Bughunt-Neo
```

This package provides GTK 3 and GTK 4 settings selecting `Bughunt-Neo`.
Use these settings in place of the original `gtk` package's settings, retaining
its CSS files. The theme directory belongs in `~/.local/share/icons/`.
For applications using the desktop preference, select it with:

```sh
gsettings set org.gnome.desktop.interface icon-theme Bughunt-Neo
```
