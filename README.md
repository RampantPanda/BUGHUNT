# Rampant-Mango

Panda likes Mango.

An Arch Linux desktop built around the Mango Wayland compositor and a MUTHUR /
Nostromo-inspired theme: dark brown backgrounds, amber frames, Terminus text,
square controls, and a terminal-like status bar. The everyday workflow is
keyboard-driven tiling, with launchers and bar menus for applications, networking,
Bluetooth, notifications, and power controls.

These are personal, editable dotfiles managed with GNU Stow. This guide assumes
a working basic Arch installation, a regular user with `sudo`, internet access,
and graphics drivers suitable for Wayland. You should be comfortable editing
config files and building an AUR package. Disk setup, the bootloader, and graphics
driver installation are outside this repository.

**Use the manual setup below.** [`scripts/install.sh`](scripts/install.sh) is an
old setup draft, not a working unattended installer. It changes the system's
package repositories, includes personal applications, backgrounds dependent build
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
`kitty/.config/kitty/kitty.conf` becomes `~/.config/kitty/kitty.conf` when stowed.
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
| `wlogout` | Alternative graphical power menu |
| `bin` | Helpers installed under `~/.local/share/bin` |
| `colors` | Shared CSS, plus Geany, Kate syntax, and KDE color schemes |
| `gtk` | GTK 3/4 user styles and settings, and the Muthur icon theme |
| `fonts` | Bundled Terminus TTF fonts |
| `fastfetch` | Optional system summary with custom ANSI artwork |
| `eww` | Optional disk, RAM, and Proton connection widget; not started automatically |

`scripts` contains maintenance tools and the old installer; it is not a Stow
package. There is no shell configuration, display manager setup, wallpaper
service, or application account configuration here. The large application list
in the old installer is personal software preference, not a dependency list.

## Install on Arch

Run the shell examples in Bash, as your regular user. Use `sudo` only where shown.

### 1. Install supporting applications

Update Arch and install the official-repository packages used by this setup:

```sh
sudo pacman -Syu --needed \
  base-devel git stow fontconfig \
  kitty fuzzel swaync gtklock swayidle wlopm \
  wl-clip-persist wl-clipboard grim slurp libnotify brightnessctl \
  networkmanager bluez bluez-utils \
  pipewire pipewire-pulse wireplumber pavucontrol \
  thunar firefox geany yad \
  capitaine-cursors adwaita-icon-theme gsettings-desktop-schemas \
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
  xorg-xwayland polkit-gnome
```

`wireplumber` supplies `wpctl`; `libnotify` supplies `notify-send`;
`networkmanager` supplies both `nmcli` and `nmtui`. The bar's `pulseaudio` module
works with PipeWire through `pipewire-pulse`.

Install Mango, a Waybar build with `mango/workspaces` support, tofi, and wlogout
from the AUR. With an existing `yay` installation:

```sh
yay -S --needed mangowm-git waybar-git tofi wlogout
```

If you need an AUR helper first, build it as your regular user and inspect the
PKGBUILD before running `makepkg`, then run the command above:

```sh
mkdir -p ~/src
git clone https://aur.archlinux.org/yay.git ~/src/yay
cd ~/src/yay
less PKGBUILD
makepkg -si
```

The compositor package is `mangowm-git`, but its executable is `mango`.
See [Mango's installation guide](https://mangowm.github.io/docs/installation/).
This repo uses the [Mango Waybar modules](https://github.com/mangowm/mango/wiki/status-bar);
a build that reports `Unknown module: mango/workspaces` will not provide the
workspace buttons. The old installer also selects `waybar-git`.
[Tofi's upstream instructions](https://github.com/philj56/tofi#arch) cover its AUR
package and source build.

Optional packages include `fastfetch`, `eww`, `alacritty` for the secondary terminal
binding, and `kate`. `ark` and `thunar-archive-plugin` add archive integration to
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
  colors fonts gtk mango kitty waybar swaync gtklock fuzzel tofi wlogout bin
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
  colors fonts gtk mango kitty waybar swaync gtklock fuzzel tofi wlogout bin
fc-cache -f
gsettings set org.gnome.desktop.interface icon-theme 'Muthur'
```

Choose packages explicitly; do not use `stow *`. Always install `colors` alongside
the themed shell applications or `gtk`, because relative CSS imports need
`~/.config/colors` next to the application directories. The configs generally
assume the standard `~/.config` and `~/.local/share` paths.

Optional configs can be linked later:

```sh
stow --target="$HOME" fastfetch eww
```

The helper scripts live in `~/.local/share/bin`, not `~/.local/bin`. Existing
bindings call them by full path, so changing `PATH` is optional. To invoke them
by name, add this to your Bash startup configuration:

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

Make these local adjustments in your checkout. The repository currently contains
some unfinished edits, so correct them before relying on the menus or locking:

1. **Keyboard and display.** In
   [`cfg/input.conf`](mango/.config/mango/cfg/input.conf), `xkb_rules_layout = fi`
   selects Finnish and natural scrolling is enabled. Change the layout if needed.
   [`cfg/monitors.conf`](mango/.config/mango/cfg/monitors.conf) has only a commented
   example. Install `wlr-randr` and run it inside a Wayland session to inspect
   outputs if you need explicit monitor rules.
2. **Autostart typo.** Remove the stray `99;6u99;6u99;6u` at the start of
   `cfg/autostart.conf`, leaving its first line as a comment.
3. **Menu script syntax.** Remove the final line containing three backticks from
   [`bluetoothmenu.sh`](bin/.local/share/bin/bluetoothmenu.sh) and
   [`powermenu.sh`](bin/.local/share/bin/powermenu.sh). Both currently fail
   `bash -n` because of that leftover Markdown fence. Check them afterward:

   ```sh
   bash -n bin/.local/share/bin/bluetoothmenu.sh
   bash -n bin/.local/share/bin/powermenu.sh
   ```

4. **Tofi font.** Its `font` setting points under `/usr/share/fonts/TTF`, while
   Stow installs the bundled fonts under your home directory. In
   [`tofi/config`](tofi/.config/tofi/config), replace that line with
   `font = Terminus (TTF)`. Alternatively, use the absolute path to your installed
   `~/.local/share/fonts/terminus-ttf-4.49.3/TerminusTTF-Bold-4.49.3.ttf`, spelling
   out your home directory.
5. **Conflicting and malformed bindings.** In
   [`cfg/keybinds.conf`](mango/.config/mango/cfg/keybinds.conf), `Super+X` is assigned
   to both Geany and cycling layout proportions. Keep your preferred action and
   rebind the other. Also review the `Super+Shift+X`/`Super+Shift+x` gap and
   proportion bindings. Replace the malformed `Super+L` binding with:

   ```ini
   bind = SUPER, l, spawn, /bin/sh -c '$HOME/.config/gtklock/lock.sh'
   ```

   The intended emergency Ghostty binding has a misplaced modifier separator;
   if you want it, install Ghostty and use
   `bind = CTRL+ALT, Return, spawn, ghostty`.
6. **Use the same locker everywhere.** Try `~/.config/gtklock/lock.sh`, which
   explicitly selects the theme and layout. The Fuzzel power script currently
   calls bare `gtklock`; change that call in `lock_screen()` to
   `"$HOME/.config/gtklock/lock.sh"` for the same appearance. Wlogout's lock action
   uses `loginctl lock-session`, but the supplied swayidle command has no `lock`
   event handler. Set that action to `"$HOME/.config/gtklock/lock.sh"` in the
   wlogout layout, or add a swayidle `lock` handler yourself. Test locking and
   password unlock before leaving automatic suspend enabled.

Create `~/Pictures/Screenshots` even if your normal Pictures directory has a
localized name: both screenshot bindings use that exact path. Change Waybar's
`Europe/Helsinki` clock timezone if appropriate. On a desktop, remove `battery`
from Waybar's `modules-right` if it is not useful.

Start Mango from a local TTY by running `mango`, or select its session in your
display manager if the package installed a session entry. The launch command is
in [Mango's quick start](https://mangowm.github.io/docs/quick-start/). This repo
supplies its own config; do not copy the upstream example over it.

Once corrected, startup launches clipboard persistence, swayidle, Waybar, and
SwayNC. It does not launch Eww, Nextcloud, or the personal applications listed in
the old installer.

## Daily use

`Super` means the Windows/logo key. The source of truth is
[`cfg/keybinds.conf`](mango/.config/mango/cfg/keybinds.conf), not Mango's upstream
defaults. `Alt+H` opens a reference window; its
[`keybinds.txt`](waybar/.config/waybar/keybinds.txt) is maintained manually.

| Keys | Action |
| --- | --- |
| `Super+Return` / `Alt+Return` | Kitty / optional Alacritty |
| `Super+Space` or `Alt+T` | Tofi application launcher |
| `Alt+F` | Fuzzel application launcher |
| `Super+E` / `Super+B` | Thunar / Firefox |
| `Super+Q` or `Alt+Q` | Close the focused window |
| `Alt+Tab` / `Super+arrows` | Next window / directional focus |
| `Super+Shift+arrows` | Exchange windows in that direction |
| `Super+1…9` | Switch workspace |
| `Super+Shift+1…9` | Move the window to that workspace and follow it |
| `Super+Tab` | Toggle overview |
| `Super+F` / `Super+Shift+F` | Floating / fullscreen |
| `Super+Alt+F` | Fake fullscreen |
| `Super+G` / `Super+O` / `Super+Z` | Toggle global / overlay / scratchpad |
| `Super+Shift+N` | Cycle layout |
| `Super+left drag` / `Super+right drag` | Move / resize a window |
| `Ctrl+Shift+arrows` / `Ctrl+Alt+arrows` | Move / resize in 50-pixel steps |
| `Print` / `Ctrl+Print` | Save full-screen / selected-region PNG |
| `Super+N` | Notification control center |
| `Alt+L` | Themed lockscreen |
| `Alt+O` | Wlogout power menu |
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
| Bluetooth | Enable/disable, connect known devices, disconnect, or pair new devices |
| Volume | Scroll to adjust, click to mute, double-click for Pavucontrol |
| Network | Open `nmtui` in a floating Kitty window |
| `IDLE` / `ACTV` | Toggle the idle inhibitor |
| `NTF` | Open notifications |
| `SYS` | Open the Fuzzel power menu |

After the script syntax correction, the Fuzzel menu offers lock, logout, user
switching, suspend, reboot, and power off. Hibernate appears when logind reports
it available. Logout, reboot, and power off have confirmation menus. User
switching depends on having a compatible display manager.

Wlogout is a separate menu. Its logout action uses
`loginctl terminate-user $USER`, which ends **all sessions for that user**. Its
hibernate button is always present, but hibernation still needs working system
configuration; these dotfiles do not configure swap or resume.

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

With a Wayland-capable Eww installed and its config stowed:

```sh
eww daemon
eww open sysmon
```

Use `eww close sysmon` to hide it. The widget targets monitor `0`; change the
geometry in `eww.yuck` for your display. Its Proton indicator searches
NetworkManager output for a Proton connection; adapt it if you use another VPN.

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
| Lock status text and positioning | [`nostrolock.sh`](gtklock/.config/gtklock/nostrolock.sh), [`config.ini`](gtklock/.config/gtklock/config.ini), [`layout.xml`](gtklock/.config/gtklock/layout.xml) |

### Shared styling

| File | Edit here for |
| --- | --- |
| [`colors.css`](colors/.config/colors/colors.css) | Shared palette, including desktop, lockscreen, and cheatsheet roles |
| [`shell.css`](colors/.config/colors/shell.css) | Shell fonts, square corners, borders, panel backgrounds, and Waybar spacing |
| [`gtk.css`](colors/.config/colors/gtk.css) | GTK 3/4 desktop widget styling |

Waybar and its cheatsheet, SwayNC, wlogout, gtklock, and Eww import `shell.css`,
which imports `colors.css`. Desktop GTK styling imports the palette directly so
ordinary apps do not inherit the shell's 22px bold text. The GTK 4 entry point
adds focus handling and libadwaita color variables.

Application stylesheets retain layouts and exceptions: smaller lockscreen and
cheatsheet text, compact Eww typography and its rounded disk widget, and thinner
borders inside SwayNC. Check these overrides when changing global fonts or
borders. Eww deliberately uses `@import url("../colors/shell.css")` so GTK loads
the shared CSS instead of Sass parsing it.

These are [GTK stylesheets](https://docs.gtk.org/gtk3/css-overview.html), using
`@define-color`; shared font and border values use grouped selectors for GTK 3
compatibility. No CSS generation step is required.

Mango, Kitty, Fuzzel, and tofi retain colors in their own config formats.
`colors.conf` and the Geany/KDE/Kate schemes are also separate files; changing
`colors.css` does not regenerate them. The lock status script has explicit
Pango foreground colors of its own.

### GTK apps, icons, and editors

The desktop theme uses pale sand body text, amber active controls, square frames,
and visible keyboard focus. GTK settings select Adwaita with a dark preference,
Terminus, and Muthur icons. These are **user stylesheet overrides**, not an
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
process; run `thunar --quit`, then reopen it. Gtklock and wlogout load styles on
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
session. The parser and contrast check runs headlessly:

```sh
python3 scripts/check-gtk-theme.py
```

It checks both GTK parsers, shared stylesheet imports, and desktop text contrast.
The supplied palette has 29 checked foreground/background pairs at or above
4.5:1. This is a palette check, not a guarantee about every app's rendered UI.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Stow reports a conflict | Move the conflicting file to your backup, then repeat the simulation. Do not force adoption. |
| Shell CSS fails to load | Stow `colors` and confirm `~/.config/colors` is alongside the app's config directory. |
| Bar workspace module is missing | Use a Waybar build supporting `mango/workspaces`; inspect `/tmp/waybar.log`. |
| Bluetooth or SYS menu reports a shell error | Remove the trailing Markdown fence from the script and run `bash -n`. |
| Tofi cannot load its font | Correct the system font path as described before first login; run `fc-match 'Terminus (TTF)'`. |
| Lock status module fails to load | Check its path and compatibility with your gtklock version. |
| Wlogout's lock button does nothing | Use the explicit themed lock script, or configure a swayidle `lock` event handler. |
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
`fuzzel-power.sh`, `newmenu.sh`, `fuzzel-powermenu.ini` (which contains a shell
script), `*-bak`, `*-not`, and editor swap files. The `bin/nostrolock.sh` file is
empty; the real status collector is inside `gtklock`. The `logseq` helper embeds
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
  colors fonts gtk mango kitty waybar swaync gtklock fuzzel tofi wlogout bin
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
