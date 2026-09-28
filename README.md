# Rampant-Mango
Panda likes Mango

The shared styling lives in the `colors` package:

| File | Edit here for |
| --- | --- |
| [`colors.css`](colors/.config/colors/colors.css) | All colors, including desktop roles and the separate lockscreen and cheatsheet palettes |
| [`shell.css`](colors/.config/colors/shell.css) | Shared shell fonts, square corners, borders, panel backgrounds, and Waybar spacing |
| [`gtk.css`](colors/.config/colors/gtk.css) | Shared MUTHUR GTK 3 and GTK 4 desktop widget styling |

Waybar (including its cheatsheet), SwayNC, wlogout, gtklock, and Eww import
`shell.css`, which imports `colors.css`. The desktop theme imports the palette
directly, so ordinary apps do not inherit the shell's 22px bold text or its
module selectors. Most desktop styling is in one file, `colors/gtk.css`;
the GTK 4 entry point adds focus handling and libadwaita color variables.

The application stylesheets keep layouts, state styling, icons, and exceptions.
For example, gtklock and the cheatsheet use smaller fonts, Eww keeps its compact
typography and rounded disk widget, and SwayNC uses thinner borders inside its
control center. These rules follow the import and override the shared defaults.
To change every border, check these explicit exceptions as well as the two
shared border rules.

The files use [GTK CSS](https://docs.gtk.org/gtk3/css-overview.html), which supports
named colors with `@define-color`. For compatibility with GTK 3, font and border
values use grouped selectors rather than browser-style custom properties.
Add a new module's selector to the shared groups when it should use those styles.

Install the `colors` Stow package alongside any application that imports it.
The installed directories must be siblings, such as `~/.config/colors` and
`~/.config/waybar`, for the relative imports to resolve. For example, from this
checkout:

```sh
stow --target="$HOME" colors waybar swaync wlogout gtklock eww
```

Eww's `eww.scss` deliberately uses `@import url("../colors/shell.css")` so the
shared GTK stylesheet is loaded as CSS rather than parsed as Sass. No generation
step is needed. Reload or restart the affected applications after editing the
theme; an application may not watch changes to imported files. For gtklock and
wlogout, the next launch loads the updated styles.

Mango, Kitty, Fuzzel, and tofi have their own configuration formats. Their colors,
fonts, and borders remain in their native configuration files; `colors.conf` is
also separate and is not generated from `colors.css`. Sharing values with those
tools would require generating their native configuration from a common source.

MUTHUR's desktop theme uses the existing near-black brown and amber palette,
pale sand body text, and Kitty's brighter green/cyan/red status accents. Controls
have square corners, thin frames, and a visible keyboard-focus outline. Active
controls use solid amber with dark text. Body text uses Terminus at 16px, with
a monospace fallback. There are no scanlines or glow effects over text.

The desktop files are GTK user stylesheet overrides. Their `settings.ini` files
select the Adwaita base with a dark preference, Terminus, and the Muthur icon
theme. They do not install a named GTK widget theme. The GTK 4 adapter requires GTK 4.16 or
newer for [CSS variables](https://docs.gtk.org/gtk4/css-properties.html), including
the [libadwaita color roles](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html).
App-specific styling and sandboxed apps can still affect the final appearance.

Preview either version without installing the theme or changing settings in
other applications (requires Python GObject bindings and the relevant GTK):

```sh
python3 scripts/preview-gtk-theme.py 3
python3 scripts/preview-gtk-theme.py 4
```

Those commands load the repository theme directly. To test whether a freshly
started GTK application picks up your installed configuration, use:

```sh
python3 scripts/preview-gtk-theme.py 3 --installed
python3 scripts/preview-gtk-theme.py 4 --installed
```

Installed mode does not inject CSS or change GTK settings. It prints the config
path, base theme, dark preference, and `GTK_THEME` override for troubleshooting.

To install, first back up any existing `gtk.css` and `settings.ini` files in
`~/.config/gtk-3.0` and `~/.config/gtk-4.0` outside the Stow target paths, then run:

```sh
stow --target="$HOME" colors gtk
gsettings set org.gnome.desktop.interface icon-theme 'Muthur'
```

Stow will report conflicts if existing files have not been moved aside. Merge
any settings you want to retain (such as your cursor theme) into the tracked
`settings.ini` files.
Restart GTK applications after installation.
Thunar can keep a background process after its windows close; run `thunar --quit`
and then `thunar` to start a fresh instance.
To revert, unstow `gtk` and restore the backed-up stylesheets; keep `colors`
installed because the shell uses it too.

The `gtk` package also installs a small Muthur icon theme under
`~/.local/share/icons/Muthur`. Angular amber folder, navigation, drive, and generic
document icons replace the blue stock artwork. Other icons inherit from Adwaita,
so application-specific artwork keeps its identity. CSS does not recolor these
full-color SVGs. The GSettings command above selects the same icon theme for
Wayland applications that use desktop settings instead of `settings.ini`.
Their colors are generated from `colors.css`; after editing the
palette, regenerate the icons with:

```sh
python3 scripts/build-gtk-icons.py
```

The generated icons are checked in, so installation needs no generation step.
If `gtk` was already stowed before the icon theme was added, run the Stow command
again to install its new `.local/share/icons` directory. Restart Thunar to reload
its icons.

The GTK file chooser portal is a separate, long-running process. If file dialogs
retain an earlier theme after normal applications update, close the open file
dialogs and restart its backend:

```sh
systemctl --user restart xdg-desktop-portal-gtk.service
```

Then open a new file dialog. Restarting Firefox alone may leave the portal
running with its old stylesheet. The local Mango portal configuration selects
the GTK backend for file selection; other desktops may use another backend.

Firefox has its own interface styling. Select its System theme in
`about:addons`. If it still substitutes Adwaita colors, try setting
`widget.gtk.libadwaita-colors.enabled` to `false` in `about:config`, then restart
Firefox. [Firefox's color handling](https://searchfox.org/firefox-main/source/widget/gtk/nsLookAndFeel.cpp)
can override GTK colors when it identifies the base theme as Adwaita; this
preference disables its libadwaita color substitutions, but does not make every
part of Firefox follow GTK widget styling.

Validate both GTK parsers, the shell imports, and desktop text contrast with:

```sh
python3 scripts/check-gtk-theme.py
```

The initial palette has 10.69:1 body-text contrast. All 29 tested foreground /
background pairs are at least 4.5:1, including status text on hover surfaces,
selected text, destructive actions, and disabled text. This uses the
[WCAG text-contrast formula](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
as a palette check, not a claim about every application's rendered UI.
