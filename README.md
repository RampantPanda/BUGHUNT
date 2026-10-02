# Rampant-Mango

Panda likes Mango.

This is my Linux desktop built around the Mango Wayland compositor and a theme inspired by the autogun UI in Aliens. Really. That's why the text is ugly, the contrast is bad and everything is clunky. However, I try to make it pretty snappy to use and use it as my main desktop. There will be versions that are less ugly, but still look like they came from a 1980's scifi flick. 

The workflow is aimed at being keyboard-centric, for speed. There are more launchers than is needed, but more is more.

This is aimed at being used on Arch-based distros. I have used EndeavourOS, CachyOS and Garudalinux when writing and testing. Haven't really noticed anything different between them. Could work in any distro, dunno.

Use GNU Stow (or GNU/Stow) to manage the files.

**Use the manual setup below.** [`scripts/install.sh`](scripts/install.sh) is an
old setup draft for my own use to make reinstalls faster and it should not be used by anyone. It changes the system's package repositories, includes personal applications, backgrounds dependent build
steps, and leaves Stow installation as a comment. You do not need Chaotic-AUR or
CachyOS to use these configs.

- [What is included](#what-is-included)
- [Install on Arch](#install-on-arch)
- [Before the first login](#before-the-first-login)
- [Daily use](#daily-use)
- [Customize the desktop](#customize-the-desktop)
- [Theme development](#theme-development)
- [Troubleshooting](#troubleshooting)
- [Updating and removing the configs](#updating-and-removing-the-configs)

## What is included

Each package directory mirrors paths relative to your home directory. For example,
`kitty/.config/kitty/kitty.conf` becomes `~/.config/kitty/kitty.conf` when stowed with "stow kitty" ran in the ~/dotfiles directory.
Stow creates symlinks, so editing the installed config also edits this checkout.
Keep the checkout wherever you install it; the examples use `~/dotfiles`.

| Package | Purpose |
| --- | --- |
| `mango` | Compositor, input, nine workspaces, bindings, window rules, startup, and idle handling |
| `waybar` | Top bar, menus, and a Yad keyboard reference |
| `kitty` | Main terminal and a separate profile for the network menu |
| `tofi`, `fuzzel` | Application launchers; Fuzzel also displays script menus |
| `swaync` | Notification daemon and control center |
| `gtklock` | Themed lockscreen with a live system-status readout |
| `bin` | Helpers installed under `~/.local/share/bin` |
| `colors` | Shared CSS, plus Geany, Kate syntax, and KDE color schemes |
| `gtk` | GTK 3/4 user styles and settings, and the Muthur icon theme |
| `fonts` | Bundled Terminus TTF fonts |
| `fastfetch` | Optional system summary with custom ANSI artwork |
| `eww` | Host, disk, RAM, and Proton connection widget; enabled in Mango startup |
| `starship` | Optional Muthur-colored shell prompt; shell initialization is not included |

`geany/geany` also contains editor settings, but its current directory layout
does not target `~/.config/geany` when stowed normally. The Geany color scheme
and some support files are included in `colors`.

`scripts` contains maintenance tools and the old installer; it is not a Stow
package. There is no shell startup configuration, display manager setup, wallpaper
service, or application account configuration here. **The large application list
in the old installer is personal software preference, not a dependency list.**

## Install on Arch

Run the shell examples in Bash, as your regular user. Use `sudo` only where shown.

### 1. Install supporting applications

Update Arch and install the official-repository packages used by this setup:

```sh
sudo pacman -Syu --needed \
  base-devel git stow fontconfig \
  kitty fuzzel swaync gtklock swayidle wlopm \
  wl-clip-persist wl-clipboard grim slurp libnotify brightnessctl \
  networkmanager bluez bluez-utils blueman jq \
  pipewire pipewire-pulse wireplumber pavucontrol \
  thunar firefox geany yad \
  capitaine-cursors adwaita-icon-theme gsettings-desktop-schemas \
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
  xorg-xwayland polkit-gnome
```

`wireplumber` supplies `wpctl`; `libnotify` supplies `notify-send`;
`networkmanager` supplies both `nmcli` and `nmtui`. The bar's `pulseaudio` module
works with PipeWire through `pipewire-pulse`. `blueman` supplies the bar's
Bluetooth manager; `jq` is used by its notification-status script.

Install Mango, a Waybar build with `mango/workspaces` support, and tofi
from the AUR. With an existing `yay` installation:

```sh
yay -S --needed mangowm-git waybar-git tofi
```

Mangowm and waybar are installed as -git versions, because they had some neat stuff the regular packages didn't have at the time of writing this. 

The compositor package is `mangowm-git`, but its executable is `mango`.
See [Mango's installation guide](https://mangowm.github.io/docs/installation/).
This repo uses the [Mango Waybar modules](https://github.com/mangowm/mango/wiki/status-bar);
a build that reports `Unknown module: mango/workspaces` will not provide the
workspace buttons. The old installer also selects `waybar-git`.
[Tofi's upstream instructions](https://github.com/philj56/tofi#arch) cover its AUR
package and source build.

Optional packages include `fastfetch`, `eww`, `starship`, and `kate`. Install
`ghostty` to use the `Ctrl+Alt+Return` emergency-terminal binding.
`ark` and `thunar-archive-plugin` add archive integration to
Thunar; `gvfs` and `udisks2` are useful for removable media. Install personal
applications such as Nextcloud, Proton, photography tools, and office software
separately.

### 2. Install the gtklock status module

The lock configuration expects `/usr/lib/gtklock/runshell-module.so`.
Install a matching module package if you have one available, or build it:

```sh
sudo pacman -S --needed meson ninja pkgconf gtk3
mkdir -p ~/src
git clone https://gitlab.com/wef/gtklock-runshell-module.git ~/src/gtklock-runshell-module
cd ~/src/gtklock-runshell-module
meson setup build --prefix=/usr --libdir=lib
meson compile -C build
sudo meson install -C build
```

The [module's version must match gtklock](https://gitlab.com/wef/gtklock-runshell-module).
This source installation is outside pacman's package tracking; keep the build
directory if you need to maintain it. For a lockscreen without the status readout,
remove the `modules=` line and `[runshell]` section from your gtklock config instead.

### 3. Clone and link the dotfiles

```sh
git clone https://github.com/RampantPanda/Rampant-Mango.git ~/dotfiles
cd ~/dotfiles
mkdir -p ~/.config ~/.local/share ~/Pictures/Screenshots

stow --simulate --verbose --target="$HOME" \
  colors fonts gtk mango kitty waybar swaync gtklock fuzzel tofi bin
```

The simulation reports proposed links and conflicts. Move existing conflicting
files or directories into a backup **outside their target paths**, then repeat
it. For example, if you already have a Kitty config:

```sh
backup_dir="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"
mv ~/.config/kitty "$backup_dir/kitty"
```

Back up only paths you actually have, and retain settings you want to merge.
For GTK, this includes existing `gtk.css` and `settings.ini` files in both
`~/.config/gtk-3.0` and `~/.config/gtk-4.0`. Avoid `stow --adopt` for initial setup:
it moves existing files into this checkout and can replace the supplied configs.

When the simulation is clean:

```sh
stow --verbose --target="$HOME" \
  colors fonts gtk mango kitty waybar swaync gtklock fuzzel tofi bin
fc-cache -f
gsettings set org.gnome.desktop.interface icon-theme 'Muthur'
```

Choose packages explicitly; do not use `stow *`. Always install `colors` alongside
the themed shell applications or `gtk`, because relative CSS imports need
`~/.config/colors` next to the application directories. The configs generally
assume the standard `~/.config` and `~/.local/share` paths.

Optional configs can be linked later:

```sh
stow --target="$HOME" fastfetch eww starship
```

The helper scripts live in `~/.local/share/bin`. To invoke them by name, add
this to your Bash startup configuration:

```sh
export PATH="$HOME/.local/share/bin:$PATH"
```

### 4. Enable desktop services

For a fresh installation using NetworkManager:

```sh
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now bluetooth.service
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
nmtui
```

Skip Bluetooth if you do not use it. If you already have a network manager, decide
which one will own your interfaces before enabling another.

For graphical authentication prompts, add this to
[`cfg/autostart.conf`](mango/.config/mango/cfg/autostart.conf) when using the
`polkit-gnome` package above:

```ini
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
```

Portal configuration is not included in this repository. To use GTK file dialogs
and the wlroots screen-sharing backend, create
`~/.config/xdg-desktop-portal/mango-portals.conf` with:

```ini
[preferred]
default=gtk
org.freedesktop.impl.portal.FileChooser=gtk
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
```

Current Mango handles the D-Bus activation environment itself. See its
[portal documentation](https://mangowm.github.io/docs/configuration/xdg-portals/)
if screen sharing or file dialogs do not work.

## Before the first login

Review these local settings in your checkout before the first login:

1. **Keyboard and display.** In
   [`cfg/input.conf`](mango/.config/mango/cfg/input.conf), `xkb_rules_layout = fi`
   selects Finnish and natural scrolling is enabled. Change the layout if needed.
   [`cfg/monitors.conf`](mango/.config/mango/cfg/monitors.conf) has only a commented
   example. Install `wlr-randr` and run it inside a Wayland session to inspect
   outputs if you need explicit monitor rules.

2. **Eww startup.** [`autostart.conf`](mango/.config/mango/cfg/autostart.conf)
   starts `eww daemon` with `exec-once` and opens `sysmon` with `exec`.
   Install Eww and stow both `eww` and `colors`, or comment out both startup
   entries if you do not use the widget.

3. **GTK preferences.** Both GTK settings files currently select `breeze-dark`
   icons, `breeze_cursors`, and Noto Sans. If you want the bundled icons, set
   `gtk-icon-theme-name=Muthur` in both files as well as the GSettings command
   above. Choose installed fonts and cursors to match your system; Mango's
   cursor setting separately uses `capitaine-cursors`.

Create `~/Pictures/Screenshots` even if your normal Pictures directory has a
localized name: both screenshot bindings use that exact path. Change Waybar's
`Europe/Helsinki` clock timezone if appropriate. On a desktop, remove `battery`
from Waybar's `modules-right` if it is not useful.

Start Mango from a local TTY by running `mango`, or select its session in your
display manager if the package installed a session entry. The launch command is
in [Mango's quick start](https://mangowm.github.io/docs/quick-start/). This repo
supplies its own config; do not copy the upstream example over it.

Startup launches clipboard persistence, swayidle, Waybar, and SwayNC, and includes
the Eww entries noted above. It does not launch Nextcloud or the personal
applications listed in the old installer.

## Daily use

`Super` means the Windows/logo key. The source of truth is
[`cfg/keybinds.conf`](mango/.config/mango/cfg/keybinds.conf), not Mango's upstream
defaults. `Alt+H` opens a reference window; its
[`cheatsheet.txt`](waybar/.config/waybar/cheatsheet.txt) is maintained manually.
The older `keybinds.txt` is not loaded by the reference window.

| Keys | Action |
| --- | --- |
| `Super+T` | Kitty |
| `Super+Space` or `Alt+T` | Tofi application launcher |
| `Alt+F` | Fuzzel application launcher |
| `Super+E` / `Super+B` | File Manager / Firefox |
| `Super+X` | Geany |
| `Super+Q` or `Alt+Q` | Close the focused window |
| `Alt+Tab` / `Super+arrows` | Next window / directional focus |
| `Super+Shift+arrows` | Exchange windows in that direction |
| `Super+1…9` | Switch workspace |
| `Super+Shift+1…9` | Move the window to that workspace and follow it |
| `Super+Tab` | Toggle overview |
| `Super+F` / `Super+Shift+F` | Floating / fullscreen |
| `Super+Alt+F` | Fake fullscreen |
| `Super+G` / `Super+Z` | Toggle global / scratchpad |
| `Super+Shift+N` | Cycle layout |
| `Super+Shift+T` / `Super+Shift+S` / `Super+Shift+C` | Tile / scroller / center tile layout |
| `Super+Shift+X` / `Super+Shift+Z` | 100% scroller width / cycle scroller proportion |
| `Super+Alt+X` / `Super+Alt+Z` / `Super+Alt+R` | Increase / decrease / toggle gaps |
| `Super+left drag` / `Super+right drag` | Move / resize a window |
| `Ctrl+Shift+arrows` / `Ctrl+Alt+arrows` | Move / resize in 50-pixel steps |
| `Print` / `Ctrl+Print` | Save full-screen / selected-region PNG |
| `Super+N` | Notification control center |
| `Alt+L` or `Super+L` | Themed lockscreen |
| `Super+O` | Fuzzel power menu |
| `Ctrl+Alt+Return` | Emergency terminal (Ghostty) |
| `Alt+H` | Keyboard reference |
| `Super+R` or `Alt+R` | Reload Mango's configuration |

Media keys change volume in 5% steps; mute toggles output mute, and `Shift+mute`
toggles microphone mute. Brightness keys change brightness in 2% steps; adding
Shift sets 100% or 1%. Three-finger horizontal swipes change workspace; a
four-finger upward swipe toggles overview.

All nine workspaces start in the `tile` layout with a 55% master area. Their bar
labels are `NET`, `WRK`, `TRM`, `AUD`, `VID`, `EML`, `MSG`, `REM`, and `AUX`.
These are organizational labels; there are no corresponding automatic
application-to-workspace assignments.

### The bar and power menus

| Bar control | Action |
| --- | --- |
| `MUTHUR` | Left-click for Fuzzel; right-click for the keyboard reference |
| Workspace label | Activate that workspace |
| Clock | Hover for the calendar |
| `NFO` | Expand/collapse CPU, RAM, and temperature readings |
| `SYS` | Expand/collapse Bluetooth and the system tray |
| Bluetooth (inside `SYS`) | Open Blueman Manager |
| Volume | Scroll to adjust, click to mute, double-click for Pavucontrol |
| Network | Open `nmtui` in a floating Kitty window |
| `IDLE` / `ACTV` | Toggle the idle inhibitor |
| Notification status (`000`, `!!!`, `---`, `-!-`) | Click to open notifications; right-click to toggle Do Not Disturb |
| `PWR` | Open the Fuzzel power menu; right-click to lock |

The Fuzzel menu offers lock, logout, user
switching, suspend, reboot, and power off. Hibernate appears when logind reports
it available. Logout, reboot, and power off have confirmation menus. User
switching depends on having a compatible display manager.

Logout uses `loginctl terminate-session` for the current session. Hibernation
still needs working system configuration; these dotfiles do not configure swap
or resume. No Wlogout config is included.

### Idle and locking

[`mango/swayidle.sh`](mango/.config/mango/swayidle.sh) locks after 5 minutes,
turns displays off after 10 minutes, and suspends after 15 minutes. It also locks
before sleep and turns displays back on after resume. Edit those timeouts for
your workflow. The input config separately requests suspend on lid close and
turns displays on when it opens; this can interact with systemd-logind's own lid
handling.

The lockscreen shows the host, time, uptime, package-update age, approximate
installation date, Wi-Fi, root-disk space, and battery. Its network readout checks
Wi-Fi through NetworkManager, so Ethernet-only machines may show `DISCONNECTED`
there even when networking works.

### Optional tools

Run `fastfetch` manually for the system summary. Its `PublicIp` module makes an
external lookup; remove that module if you do not want it.

Eww's [`eww.css`](eww/.config/eww/eww.css) imports the shared palette through
`../colors/colors.css`; stow `colors` alongside `eww` so that path resolves.
With a Wayland-capable Eww installed and its config stowed:

```sh
eww daemon
eww open sysmon
```

Use `eww close sysmon` to hide it. The widget targets monitor `0`; change the
geometry in `eww.yuck` for your display. Its Proton indicator searches
NetworkManager output for a Proton connection; adapt it if you use another VPN.

The optional Starship config supplies the prompt's colors and segments. Stowing
it does not initialize Starship in your shell; keep that setup in your own shell
configuration.

## Customize the desktop

Edit the files in this checkout. Mango's top-level config sources the `cfg`
files first and `themes/muthur.conf` last.

| Change | File |
| --- | --- |
| Keyboard, scrolling, lid actions | [`input.conf`](mango/.config/mango/cfg/input.conf) |
| Output resolution and placement | [`monitors.conf`](mango/.config/mango/cfg/monitors.conf) |
| Application shortcuts | [`keybinds.conf`](mango/.config/mango/cfg/keybinds.conf) |
| Startup applications | [`autostart.conf`](mango/.config/mango/cfg/autostart.conf) |
| Layouts and master proportions | [`layout.conf`](mango/.config/mango/cfg/layout.conf) |
| Floating windows and placement | [`rules.conf`](mango/.config/mango/cfg/rules.conf) |
| Gaps, borders, cursor, blur, animations | [`appearance.conf`](mango/.config/mango/cfg/appearance.conf) |
| Compositor colors | [`muthur.conf`](mango/.config/mango/themes/muthur.conf) |
| Bar modules, click actions, timezone | [`config.jsonc`](waybar/.config/waybar/config.jsonc) |
| Terminal font, padding, colors | [`kitty.conf`](kitty/.config/kitty/kitty.conf) |
| Shell prompt colors and segments | [`starship.toml`](starship/.config/starship.toml) |
| Lock status text and positioning | [`nostrolock.sh`](gtklock/.config/gtklock/nostrolock.sh), [`config.ini`](gtklock/.config/gtklock/config.ini), [`layout.xml`](gtklock/.config/gtklock/layout.xml) |

### Shared styling

| File | Edit here for |
| --- | --- |
| [`colors.css`](colors/.config/colors/colors.css) | Shared palette, including desktop, lockscreen, and cheatsheet roles |
| [`shell.css`](colors/.config/colors/shell.css) | Shell fonts, square corners, borders, panel backgrounds, and Waybar spacing |
| [`gtk.css`](colors/.config/colors/gtk.css) | GTK 3/4 desktop widget styling |

Waybar and its cheatsheet, SwayNC, and gtklock import `shell.css`,
which imports `colors.css`. Desktop GTK styling imports the palette directly so
ordinary apps do not inherit the shell's 22px bold text. The GTK 4 entry point
adds focus handling and libadwaita color variables.

Application stylesheets retain layouts and exceptions: smaller lockscreen status
and cheatsheet text, Eww's own widget frames, and thinner borders inside SwayNC.
Check these overrides when changing global fonts or
borders. Eww has its own typography and imports the shared palette directly.

These are [GTK stylesheets](https://docs.gtk.org/gtk3/css-overview.html), using
`@define-color`; shared font and border values use grouped selectors for GTK 3
compatibility. No CSS generation step is required.

Mango, Kitty, Fuzzel, tofi, and Starship retain colors in their own config formats.
`colors.conf` and the Geany/KDE/Kate schemes are also separate files; changing
`colors.css` does not regenerate them. The lock status script has explicit
Pango foreground colors of its own.

### GTK apps, icons, and editors

The desktop theme uses pale sand body text, amber active controls, square frames,
and visible keyboard focus. GTK settings select Adwaita with a dark preference,
Noto Sans, and Breeze icons/cursors; the shared CSS supplies Terminus typography.
Both GTK entry stylesheets also import local Breeze `colors.css` files.
These are **user stylesheet overrides**, not an
installed widget theme named Muthur. The GTK 4 adapter needs GTK 4.16 or newer for
[CSS variables](https://docs.gtk.org/gtk4/css-properties.html), including
[libadwaita's color roles](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html).
Application-specific styles and sandboxing can affect the result.

The small Muthur icon theme supplies amber folders, navigation, drives, and generic
documents. Other icons inherit from Adwaita/hicolor. Generated SVGs are checked
in, so installation needs no build. After changing the shared palette:

```sh
python3 scripts/build-gtk-icons.py
```

Select `MUTHUR` in Geany's color-scheme chooser and Kate's editor color-theme
settings. The KDE application color scheme is installed under
`~/.local/share/color-schemes/Muthur.colors`; select it with the KDE/Qt settings
tool you use. Installing it does not configure every Qt application automatically.

### Reload changes

Mango: press `Super+R`. Changes to `exec-once` entries need a new session or a
manual launch. To restart the bar or reload notifications from a terminal:

```sh
pkill -x waybar
waybar >/tmp/waybar.log 2>&1 &
swaync-client --reload-config
swaync-client --reload-css
```

Restart GTK applications after styling changes. Thunar may retain a background
process; run `thunar --quit`, then reopen it. Gtklock loads styles on
the next launch. Reload or restart Eww after editing its styles. An application
may not notice changes to an imported stylesheet automatically.

## Theme development

Install the preview and checker dependencies:

```sh
sudo pacman -S --needed python-gobject gtk3 gtk4
```

Preview the repository's GTK theme without installing it or changing other apps:

```sh
python3 scripts/preview-gtk-theme.py 3
python3 scripts/preview-gtk-theme.py 4
```

To check what a newly launched application gets from the installed configuration:

```sh
python3 scripts/preview-gtk-theme.py 3 --installed
python3 scripts/preview-gtk-theme.py 4 --installed
```

Installed mode does not inject CSS or change settings; it prints the config path,
base theme, dark preference, and any `GTK_THEME` override. Previews need a graphical
session. The parser and contrast checker runs headlessly:

```sh
python3 scripts/check-gtk-theme.py
```

The checker validates the GTK 3/4 stylesheets and shared imports, including
Eww's `eww.css`. All 29 desktop foreground/background pairs pass its 4.5:1
contrast threshold. This is a palette check, not a guarantee about every app's
rendered UI.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Stow reports a conflict | Move the conflicting file to your backup, then repeat the simulation. Do not force adoption. |
| Shell CSS fails to load | Stow `colors` and confirm `~/.config/colors` is alongside the app's config directory. |
| Bar workspace module is missing | Use a Waybar build supporting `mango/workspaces`; inspect `/tmp/waybar.log`. |
| Bluetooth manager does not open | Install `blueman`; the bar launches `blueman-manager`, not `bluetoothmenu.sh`. |
| Notification status is missing or shows errors | Install `jq` and confirm SwayNC is running. |
| Tofi cannot load its font | Check the `font` path in `tofi/.config/tofi/config`, or use `font = Terminus (TTF)`; run `fc-match 'Terminus (TTF)'`. |
| Lock status module fails to load | Check its path and compatibility with your gtklock version. |
| Eww does not appear | Install Eww, stow `eww` and `colors`, and inspect `eww logs` for errors. |
| Screenshot is not saved | Check `grim`, `slurp`, and `~/Pictures/Screenshots`; run the command in a terminal for errors. The full-screen binding notifies without waiting for capture to finish. |
| Authorization prompts never appear | Start a polkit authentication agent in the graphical session. |
| GTK icons or colors look unchanged | Restart the app, check GTK settings and `GTK_THEME`, and use installed preview mode. |

File chooser portals are long-running processes. If dialogs keep the old theme,
close them and restart the backend, then open a new dialog:

```sh
systemctl --user restart xdg-desktop-portal-gtk.service
```

Restarting Firefox alone may leave that process running. Firefox also has its own
UI styling: select its System theme in `about:addons`. If it substitutes Adwaita
colors, try `widget.gtk.libadwaita-colors.enabled = false` in `about:config` and
restart Firefox. This disables its libadwaita color substitutions; it does not
make the entire interface follow GTK CSS. See
[Firefox's GTK color handling](https://searchfox.org/firefox-main/source/widget/gtk/nsLookAndFeel.cpp).

Some files are retained experiments rather than active parts of the desktop:
`fuzzel-powermenu.ini` (which contains a shell script), `*-bak`, `*-not`, and
editor swap files. The standalone `bluetoothmenu.sh` helper is not called by the
bar. The lock status collector is inside `gtklock`. The `logseq` helper embeds
a local AppImage path and temporary mount path and needs replacing for another
machine. Do not treat every helper as a portable application launcher.

Waybar lists an undefined `custom/nextcloud` module; remove it from `modules-right`
or implement it. Its inactive `custom/media` definition references an absent
`mediaplayer.py`. Clipboard persistence is configured, but history is not:
installing `cliphist` alone does not add a watcher or history picker.

## Updating and removing the configs

Keep customizations in a local branch or fork. Before pulling changes, check
`git status` and commit or stash your edits. After updating, rerun Stow for the
packages you use so new files are linked, then reload the affected apps:

```sh
cd ~/dotfiles
git diff
stow --restow --target="$HOME" \
  colors fonts gtk mango kitty waybar swaync gtklock fuzzel tofi bin
```

Stow can link entire directories. Files created by apps inside them can appear
in the checkout; inspect untracked files before committing, especially GTK
bookmarks, histories, and editor swap files.

To remove a package's links, use `stow --delete`, then restore the backed-up
config. For example:

```sh
cd ~/dotfiles
stow --delete --target="$HOME" gtk
```

Restore the previous GTK styles/settings and icon-theme preference, then restart
the apps. Keep `colors` installed while any shell stylesheet still imports it.
To remove the whole setup, log out of Mango, run the same delete command with all
package names you installed, restore backups, and select your previous session.
Unstowing does not uninstall packages, undo enabled services or GSettings
changes, or remove the manually installed gtklock module and portal config.
Unstow before moving or deleting the checkout.

See [LICENSE](LICENSE) for the repository license and the bundled
[Terminus font license](fonts/.local/share/fonts/terminus-ttf-4.49.3/COPYING)
for the font's terms.
