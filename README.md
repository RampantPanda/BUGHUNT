# BUGHUNT / Rampant-Mango

Panda likes Mango.

This is my Linux desktop built around the Mango Wayland compositor and a theme inspired by the autogun UI in Aliens. Really. That's why the text is ugly, the contrast is bad and everything is clunky. However, I try to make it pretty snappy to use and use it as my main desktop. There will be versions that are less ugly, but still look like they came from a 1980's scifi flick. 

The workflow is aimed at being keyboard-centric, for speed. There are more launchers than is needed, but more is more.

This is aimed at being used on Arch-based distros. I have used EndeavourOS, CachyOS and Garudalinux when writing and testing. Haven't really noticed anything different between them. Could work in any distro, dunno.

Use GNU Stow (or GNU/Stow) to manage the files.

The repository includes the amber **BUGHUNT** theme and cyan **BUGHUNT-NEO**
variants. Use the manual setup below or review the dependency installer's dry
run first. [`scripts/install.sh`](scripts/install.sh) uses your configured
repositories and prints separate Stow instructions; personal applications are
opt-in. Its runshell-module build still requires **gtklock 4**, so use manual
setup on gtklock 5. You do not need Chaotic-AUR or CachyOS to use these configs.

- [What is included](#what-is-included)
- [Install on Arch](#install-on-arch)
- [Before the first login](#before-the-first-login)
- [Daily use](#daily-use)
- [Customize the desktop](#customize-the-desktop)
- [Switch between BUGHUNT and BUGHUNT-NEO](#switch-between-bughunt-and-bughunt-neo)
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
| `colors` | Shared CSS, Kate syntax, and KDE color schemes |
| `geany` | Editor settings and the Bughunt color scheme |
| `cursors` | Capitaine Gruvbox cursor theme |
| `gtk` | GTK 3/4 user styles and settings, and the Bughunt icon theme |
| `fonts` | Bundled Terminus TTF fonts |
| `fastfetch` | Optional system summary with custom ANSI artwork |
| `eww` | Host, disk, RAM, and Proton connection widget; enabled in Mango startup |
| `starship`, `starship-neo` | Shell prompt themes |
| `fish` | Interactive Fish startup with Starship and Fastfetch, plus Copilot completions |
| `mpd` | Music Player Daemon configuration with PipeWire output; runtime data stays local |
| `rmpc` | Terminal MPD client configuration and BUGHUNT theme using terminal ANSI colors |
| `icons-neo` | Neo-Wire icon theme |
| `thunderbird` | Thunderbird UI stylesheet for an existing profile |

Neo variants are also supplied for `colors`, `eww`, `fastfetch`, `fuzzel`, `gtk`,
`gtklock`, `kitty`, `mango`, and `waybar`. Choose one Mango profile from `mango`,
`mango-vm`, `mango-neo`, or `mango-vm-neo`; they target the same config directory.
Other original/Neo pairs also overlap, so do not stow both wholesale. Neo GTK
uses the original GTK CSS with Neo settings and colors. The
[theme switcher](#switch-between-bughunt-and-bughunt-neo) handles these combinations.

`geany` targets `~/.config/geany`. Its session state and runtime socket are
ignored by Git. MPD's directory tracks only `*.conf`: its database, playback
state, PID files, and local playlists are ignored, including when Stow links the
whole directory into this checkout.

`scripts` contains maintenance tools and the dependency installer; it is not a
Stow package. Fish startup configuration is included, but display manager setup,
wallpaper services, and application accounts require separate configuration.

## Install on Arch

Run the shell examples in Bash, as your regular user. Use `sudo` only where shown.
Clone the repository first if you have not already:

```sh
git clone https://github.com/RampantPanda/BUGHUNT.git ~/dotfiles
cd ~/dotfiles
```

The installer covers dependencies for the checked-in desktop, including Eww,
Fish/Starship, MPD/rmpc, Neo's Python launcher, and the network connection editor:

```sh
bash scripts/install.sh --dry-run --theme neo
bash scripts/install.sh --theme neo
```

Use `--theme original` (the default) for the original theme's Stow instructions.
`--with-apps` adds the personal office, photography, Proton, and other application
collection. An existing `yay` or `paru` is required for packages absent from your
configured repositories; select one with `--aur-helper yay` or `--aur-helper paru`.
The preflight uses local pacman sync databases, then installation performs a full
`pacman -Syu` before installing AUR packages. Package availability can change.

The installer builds runshell release 4.0.0 for gtklock 4, installs the font used
by tofi, and creates the screenshots directory. It stops on incompatible gtklock
versions after the package/font steps, so it is not a complete installer for
gtklock 5. Temporary module sources are cleaned up on failure or interruption.
It does not add repositories, overwrite GTK settings, or enable services. Stow
commands are printed as simulations for you to review and apply separately.
For Neo, the first command installs the original GTK CSS while excluding its
settings; the second installs Neo settings and the remaining packages. Remove
the opposite variant's Stow links before switching themes manually. Its Neo
package list selects `mango-vm-neo` and shares the original Fuzzel and Starship
configs; use the theme switcher for the full Neo appearance. Hyprlock,
Alacritty, swaybg, and Tailscale are not in the installer's dependency list; install
them separately if using the desktop Neo profile and its Tailscale module.

The manual installation steps below remain available as an alternative.

Run the script regression checks without installing packages or changing desktop
settings:

```sh
python3 -B -m unittest discover -s scripts/tests -v
```

### 1. Install supporting applications

Update Arch and install the official-repository packages used by this setup:

```sh
sudo pacman -Syu --needed \
  base-devel git stow fontconfig python python-gobject \
  kitty fuzzel swaync gtklock swayidle wlopm \
  wl-clip-persist wl-clipboard grim slurp libnotify brightnessctl \
  networkmanager nm-connection-editor bluez bluez-utils blueman jq \
  pipewire pipewire-pulse wireplumber pavucontrol \
  thunar firefox geany yad fish fastfetch starship mpd rmpc \
  capitaine-cursors breeze adwaita-icon-theme gsettings-desktop-schemas \
  noto-fonts ttf-terminus-nerd ttf-space-mono-nerd \
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
  xorg-xwayland polkit-gnome plasma-integration
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
workspace buttons. The installer also selects `waybar-git`.
[Tofi's upstream instructions](https://github.com/philj56/tofi#arch) cover its AUR
package and source build.

Optional packages include `fastfetch`, `eww`, `starship`, and `kate`. Install
`ghostty` to use the `Ctrl+Alt+Return` emergency-terminal binding.
`ark` and `thunar-archive-plugin` add archive integration to
Thunar; `gvfs` and `udisks2` are useful for removable media. Install personal
applications such as Nextcloud, Proton, photography tools, and office software
separately.

### 2. Choose the lockscreen and optional status module

The original gtklock config enables `/usr/lib/gtklock/runshell-module.so`;
the Neo config comments it out for gtklock 5. If using the original config
without a compatible module, comment out `modules=` before launching gtklock.
The wrapper [`lock.sh`](gtklock/.config/gtklock/lock.sh) selects the bundled
`layout.xml`; Neo's raw `config.ini` still names `layout.ui`, so use the wrapper
or correct that setting. The theme switcher sets the correct layout path and
preserves the installed module selection.

For **gtklock 4**, the installer pins runshell 4.0.0. To build that version manually:

```sh
sudo pacman -S --needed meson ninja pkgconf gtk3
mkdir -p ~/src
git clone --branch 4.0.0 --depth 1 https://gitlab.com/wef/gtklock-runshell-module.git ~/src/gtklock-runshell-module
cd ~/src/gtklock-runshell-module
meson setup build --prefix=/usr --libdir=lib
meson compile -C build
sudo meson install -C build
```

The [module's version must match gtklock](https://gitlab.com/wef/gtklock-runshell-module).
This source installation is outside pacman's package tracking; keep the build
directory if you need to maintain it. For a lockscreen without the status readout,
remove the `modules=` line and `[runshell]` section from your gtklock config instead.

`mango-neo` uses **Hyprlock** for its lock shortcuts, idle handling, and lid-close
command. No Hyprlock configuration is included: install and configure it yourself
before using that profile. The original and both VM profiles use gtklock.
Neo's bar and power-menu lock actions still use gtklock, so align those commands
if you want one locker everywhere.

### 3. Link the dotfiles

```sh
cd ~/dotfiles
mkdir -p ~/.config ~/.local/share ~/Pictures/Screenshots

stow --simulate --verbose --target="$HOME" \
  colors fonts cursors geany gtk mango kitty waybar swaync gtklock fuzzel tofi bin mpd rmpc
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
  colors fonts cursors geany gtk mango kitty waybar swaync gtklock fuzzel tofi bin mpd rmpc
fc-cache -f
gsettings set org.gnome.desktop.interface icon-theme 'Bughunt'
```

Choose packages explicitly; do not use `stow *`. Always install `colors` alongside
the themed shell applications or `gtk`, because relative CSS imports need
`~/.config/colors` next to the application directories. The configs generally
assume the standard `~/.config` and `~/.local/share` paths.

Optional configs can be linked later:

```sh
stow --target="$HOME" fastfetch eww starship fish
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

The checked-in Mango startup files leave SwayNC commented out and expect it to
be managed separately. In your graphical session, enable its user service:

```sh
systemctl --user enable --now swaync.service
```

Alternatively, add `exec_once = swaync` to your active Mango startup file.
For MPD setup, see [Music with MPD and rmpc](#music-with-mpd-and-rmpc).

For graphical authentication prompts, add this to
[`cfg/autostart.conf`](mango/.config/mango/cfg/autostart.conf) when using the
`polkit-gnome` package above:

```ini
exec_once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
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
   starts `eww daemon` with `exec_once` and opens `sysmon` and `logowindow` with `exec`.
   Install Eww and stow both `eww` and `colors`, or comment out both startup
   entries if you do not use the widget.

3. **GTK preferences.** The original GTK 3/4 settings select the bundled `Bughunt`
   icons, `breeze_cursors`, and Noto Sans. The original-theme GSettings command
   above also selects `Bughunt`. Neo's raw settings have conflicting icon entries;
   the theme switcher normalizes them to Neo-Wire by default. Choose installed
   fonts and cursors to match your system; the original Mango config separately
   selects `capitaine-cursors`.

Create `~/Pictures/Screenshots` even if your normal Pictures directory has a
localized name: both screenshot bindings use that exact path. Change Waybar's
`Europe/Helsinki` clock timezone if appropriate. On a desktop, remove `battery`
from Waybar's `modules-right` if it is not useful.

Start Mango from a local TTY by running `mango`, or select its session in your
display manager if the package installed a session entry. The launch command is
in [Mango's quick start](https://mangowm.github.io/docs/quick-start/). This repo
supplies its own config; do not copy the upstream example over it.

Startup launches clipboard persistence, swayidle, Waybar, and the Eww entries
noted above. `mango-neo` also starts the polkit agent and uses `swaybg` for its
solid background. SwayNC needs the separate setup above. Nextcloud and other
personal applications are not started by these configs.

## Daily use

The shortcut table below describes the original `mango` profile.
`Super` means the Windows/logo key. The source of truth is
[`cfg/keybinds.conf`](mango/.config/mango/cfg/keybinds.conf), not Mango's upstream
defaults. `Alt+H` opens a reference window; its
[`cheatsheet.txt`](waybar/.config/waybar/cheatsheet.txt) is maintained manually.
The older `keybinds.txt` is not loaded by the reference window.

With `mango-vm`, `Alt+H` instead opens
[`cheatsheet-vm.txt`](waybar/.config/waybar/cheatsheet-vm.txt), based on the active
[`cfg/keybinds-VM.conf`](mango-vm/.config/mango/cfg/keybinds-VM.conf).
It includes the remaining Super shortcuts and notes conflicting or malformed
bindings. Both references are maintained manually; run
`~/.config/waybar/cheatsheet.sh desktop` or `~/.config/waybar/cheatsheet.sh vm`
to open either explicitly.

`mango-neo` has different bindings: `Super+Space` opens Fuzzel, `Super+W`
relaunches its 70%-width bar, `Super+H` opens the VM reference, `Alt+R` reloads
Mango, `Alt+L`/`Super+L` run Hyprlock, and `Ctrl+Alt+Return` runs Alacritty.
Consult its [keybinds.conf](mango-neo/.config/mango/cfg/keybinds.conf) or the
active VM profile instead of applying the original table to every variant.

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
Neo uses workspace icons instead of these text labels.
These are organizational labels; there are no corresponding automatic
application-to-workspace assignments.

### The bar and power menus

The original bar uses the controls below. Neo places MPD in the center,
shows Bluetooth and the tray directly, uses icons for most controls, and adds
a Tailscale status/toggle. Its Python launcher creates a bar at 70% of each
monitor's logical width.

| Bar control | Action |
| --- | --- |
| Hostname (original bar center) | Left-click for Fuzzel; right-click for the keyboard reference |
| Workspace label | Activate that workspace |
| Clock | Hover for the calendar |
| `MUS` | Expand/collapse MPD track information |
| MPD track | Focus an existing window titled `rmpc`; it does not start the client |
| `SYS` | Expand/collapse Bluetooth and the system tray |
| Bluetooth (inside `SYS`) | Open Blueman Manager |
| Volume | Scroll to adjust, click to mute, double-click for Pavucontrol |
| Network | Original: `nmtui` in Kitty; Neo: `nm-connection-editor` |
| Nextcloud (original) | Display client sync status; click to open Nextcloud |
| Tailscale (Neo) | Hover for state/IP; click to run `tailscale up` or `tailscale down` |
| `IDLE` / `ACTV` | Toggle the idle inhibitor |
| Notification status (`000`, `!!!`, `---`, `-!-`) | Click to open notifications; right-click to toggle Do Not Disturb |
| `PWR` | Open the Fuzzel power menu; right-click to lock |

The Tailscale helper requires `tailscale`, `jq`, a running daemon, and permission
for your user to control the connection. Remove `custom/tailscale` from Neo's
`modules-right` if you do not use it. Nextcloud status comes from the running
client's tray tooltip; it reports offline when the client is unavailable.

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

With the runshell module enabled, gtklock shows the host, time, uptime,
package-update age, approximate installation date, network, root-disk space,
and battery. Its collector handles Wi-Fi, wired Ethernet, and offline states.
The desktop Neo profile uses the same idle timeouts with Hyprlock, and launches
Hyprlock before a one-second delay and suspend on lid close.

### Music with MPD and rmpc

[`mpd.conf`](mpd/.config/mpd/mpd.conf) reads music from `~/Music`, stores playlists
in `~/Music/playlists`, and outputs through PipeWire. After installing `mpd` and
`rmpc` and stowing both packages:

```sh
mkdir -p ~/Music/playlists
systemctl --user enable --now mpd.service
kitty --title rmpc rmpc
```

The client connects to `127.0.0.1:6600`; use its help (`?`) and library-update
actions to populate the database after adding music. The bar's MPD click helper
focuses an already running window titled `rmpc`. The BUGHUNT rmpc theme uses
terminal ANSI colors, so it follows Kitty's selected palette.

Only MPD configuration is versioned. Its database (`mpd.db`), playback state
(`mpdstate`), PID files, and playlists are machine-local and are not pushed to
the remote repository. They remain on disk when excluded from Git.

### Optional tools

Run `fastfetch` manually for the system summary. Its `PublicIp` module makes an
external lookup; remove that module if you do not want it.

Eww's [`eww.css`](eww/.config/eww/eww.css) imports the shared palette through
a local `colors.css` symlink into the repository's `colors` package. This keeps
the import working when Eww resolves the stowed config path to the checkout.
With a Wayland-capable Eww installed and its config stowed:

```sh
eww daemon
eww open sysmon
```

Use `eww close sysmon` to hide it. The widget targets monitor `0`; change the
geometry in `eww.yuck` for your display. Its Proton indicator searches
NetworkManager output for a Proton connection; adapt it if you use another VPN.

The optional Starship config supplies the prompt's colors and segments. The
included Fish config initializes Starship and runs Fastfetch in interactive
shells; install both when stowing `fish`. Other shells need their own startup
integration.

Thunderbird's [userChrome.css](thunderbird/.config/thunderbird/f12qqs1c.default-release/chrome/userChrome.css)
themes the application UI. The checked-in profile name is personal; copy the CSS
to your existing profile's `chrome` directory, or use the theme switcher to find
existing profiles automatically. Enable
`toolkit.legacyUserProfileCustomizations.stylesheets` in Thunderbird's Config
Editor and restart Thunderbird. Do not stow the personal profile name as a way
to create or select your own account profile.

## Customize the desktop

Edit the files in this checkout. Mango's top-level config sources the `cfg`
files first and `themes/bughunt.conf` last for the original desktop; Neo uses
`themes/k.conf`. Edit the matching variant's directory when using Neo.

| Change | File |
| --- | --- |
| Keyboard, scrolling, lid actions | [`input.conf`](mango/.config/mango/cfg/input.conf) |
| Output resolution and placement | [`monitors.conf`](mango/.config/mango/cfg/monitors.conf) |
| Application shortcuts | [`keybinds.conf`](mango/.config/mango/cfg/keybinds.conf) |
| Startup applications | [`autostart.conf`](mango/.config/mango/cfg/autostart.conf) |
| Layouts and master proportions | [`layout.conf`](mango/.config/mango/cfg/layout.conf) |
| Floating windows and placement | [`rules.conf`](mango/.config/mango/cfg/rules.conf) |
| Gaps, borders, cursor, blur, animations | [`appearance.conf`](mango/.config/mango/cfg/appearance.conf) |
| Compositor colors | [`bughunt.conf`](mango/.config/mango/themes/bughunt.conf) |
| Bar modules, click actions, timezone | [`config.jsonc`](waybar/.config/waybar/config.jsonc) |
| Terminal font, padding, colors | [`kitty.conf`](kitty/.config/kitty/kitty.conf) |
| Shell prompt colors and segments | [`starship.toml`](starship/.config/starship.toml) |
| Lock status text and positioning | [`buglock.sh`](gtklock/.config/gtklock/buglock.sh), [`config.ini`](gtklock/.config/gtklock/config.ini), [`layout.xml`](gtklock/.config/gtklock/layout.xml) |

### Shared styling

| File | Edit here for |
| --- | --- |
| [`colors.css`](colors/.config/colors/colors.css) | Master BUGHUNT palette, including desktop, lockscreen, cheatsheet roles, and shared GTK semantic aliases |
| [`shell.css`](colors/.config/colors/shell.css) | Shared shell fonts, square corners, control borders, and panel styling |
| [`waybar/style.css`](waybar/.config/waybar/style.css) | Waybar frames, module spacing, colors, and state overrides |
| [`gtk.css`](colors/.config/colors/gtk.css) | GTK 3/4 desktop widget styling |
| [`gtk-3.0/compat.css`](gtk/.config/gtk-3.0/compat.css) | GTK 3 Breeze compatibility definitions |
| [`gtk-4.0/compat.css`](gtk/.config/gtk-4.0/compat.css) | GTK 4 focus handling, libadwaita custom properties, and Breeze compatibility definitions |

Waybar and its cheatsheet, SwayNC, and gtklock import `shell.css`,
which imports `colors.css`. Desktop GTK styling imports the palette directly so
ordinary apps do not inherit the shell's 22px bold text. The thin
[`GTK 3 entrypoint`](gtk/.config/gtk-3.0/gtk.css) imports its adapter first,
then the shared widget stylesheet (which imports the master palette once).
The thin [`GTK 4 entrypoint`](gtk/.config/gtk-4.0/gtk.css) imports the shared
widget stylesheet first, then its adapter so GTK 4 focus rules follow shared rules.
GTK 4 custom properties reference the master palette's roles.

The two adapters retain all original `*_breeze` definitions and values for base
themes or applications that may consume them. They are compatibility data;
edit the master palette for BUGHUNT colors. Shared GTK semantic aliases stay in
the master palette because GTK 3, GTK 4, and shell consumers already receive them.
Eww's local `colors.css` is a symlink to that same master, not another palette.

When updating an existing installation with individual Stow file links, restow
the `gtk` package (`stow -R -t "$HOME" gtk`) to pick up the renamed adapters.
Installations with whole-directory links pick up the new paths automatically.

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
and visible keyboard focus. GTK settings select adw-gtk3-dark for GTK 3 and
Adwaita for GTK 4, with a dark preference,
Noto Sans, Bughunt icons, and Breeze cursors; the shared CSS supplies Terminus typography.
Both GTK entry stylesheets also load the retained Breeze definitions through
their version-specific `compat.css` adapters.
These are **user stylesheet overrides**, not an
installed widget theme named Bughunt. The GTK 4 adapter needs GTK 4.16 or newer for
[CSS variables](https://docs.gtk.org/gtk4/css-properties.html), including
[libadwaita's color roles](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html).
Application-specific styles and sandboxing can affect the result.

The small Bughunt icon theme supplies amber folders, navigation, drives, and generic
documents. Other icons inherit from Adwaita/hicolor. Generated SVGs are checked
in, so installation needs no build. After changing the shared palette:

```sh
python3 scripts/build-gtk-icons.py
```

Select `BUGHUNT` in Geany's color-scheme chooser and Kate's editor color-theme
settings. The KDE application color scheme is installed under
`~/.local/share/color-schemes/Bughunt.colors`; select it with the KDE/Qt settings
tool you use. Installing it does not configure every Qt application automatically.

## Switch between BUGHUNT and BUGHUNT-NEO

[`scripts/switch-theme.py`](scripts/switch-theme.py) applies either theme using
the current files in this checkout. It requires Python 3.10+, Git, and installed
desktop dependencies. From the repository root:

```sh
python3 scripts/switch-theme.py neo --dry-run
python3 scripts/switch-theme.py neo
python3 scripts/switch-theme.py original
python3 scripts/switch-theme.py toggle
python3 scripts/switch-theme.py status
python3 scripts/switch-theme.py restore
```

It covers Mango appearance, Waybar, GTK/SwayNC, Kitty, launchers, Eww, Fastfetch,
Starship, gtklock, icons, Geany, KDE/Qt/Kate, rmpc, and existing Thunderbird
profiles. Neo selects Neo-Wire icons by default; use `--neo-icons Bughunt-Neo`
for the smaller icon set. MPD configuration and state are outside its scope.

By default, Mango's keybindings, input, monitors, rules, and personal startup
commands are preserved; the Waybar launch command and the repo's solid-color
background are adjusted. Use `--mango-profile desktop` or `--mango-profile vm`
only when you also want to replace that complete profile.

Each switch backs up displaced files and Stow links under
`~/.local/state/bughunt-switch/` and installs **copies** without editing the
source checkout. Edits to those installed copies no longer update the repo;
reapply after changing source configs. `restore` undoes the latest switch,
including saved desktop preferences; repeated restores step backward.
Restore before returning management of those files to Stow.

Normal application reloads the desktop and updates available desktop appearance
preferences. `--no-reload` changes files only. `--target /tmp/bughunt-preview`
uses a separate test home without affecting the running desktop. Restart
Thunderbird to load its UI stylesheet. See the
[full switcher guide](scripts/SWITCH-THEME.md) for scope, recovery, and backups.

`scripts/apply-neo.sh` only selects Neo-Wire icons and rebuilds their cache;
it does not switch the whole desktop. `scripts/generate-neo-icons.sh` regenerates
application icons using local desktop entries and icon sources, and assumes
the checkout is at `~/dotfiles`. The generated icons are already included.

### Reload changes

Mango: press `Super+R` in the original profile or `Alt+R` in either desktop
profile. Changes to `exec_once` entries need a new session or a
manual launch. To restart the bar or reload notifications from a terminal:

```sh
pkill -x waybar
waybar >/tmp/waybar.log 2>&1 &
swaync-client --reload-config
swaync-client --reload-css
```

For Neo, replace the bare `waybar` command with
`python3 ~/.config/waybar/launch.py --width-percent 70` to retain per-monitor
widths. After applying the theme switcher, use
`~/.config/waybar/launch-theme.sh`, which selects the active mode's launcher.

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

The checker validates both the original and Neo GTK 3/4 stylesheets and shared
imports, including Eww's `eww.css`. Use `--variant original` or `--variant neo`
to check one theme, or `--syntax-only` to skip contrast checks. Neo uses the
original GTK CSS entrypoints with its own palette and settings. All 29 desktop
foreground/background pairs in each theme pass the 4.5:1 contrast threshold.
This is a palette check, not a guarantee about every app's rendered UI.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Stow reports a conflict | Move the conflicting file to your backup, then repeat the simulation. Do not force adoption. Original and Neo packages can also conflict on local GTK bookmarks: Git ignore rules do not exclude files from Stow. After using the theme switcher, restore before switching back to Stow. |
| Shell CSS fails to load | Stow `colors` and confirm `~/.config/colors` is alongside the app's config directory. |
| Bar workspace module is missing | Use a Waybar build supporting `mango/workspaces`; inspect `/tmp/waybar.log`. |
| Bluetooth manager does not open | Install `blueman`; the bar launches `blueman-manager`, not `bluetoothmenu.sh`. |
| Notification status is missing or shows errors | Install `jq` and confirm SwayNC is running. |
| MPD shows `DISC` | Check the user MPD service, music paths, and PipeWire output; rmpc expects `127.0.0.1:6600`. |
| Clicking MPD does nothing | Start rmpc in a window titled `rmpc`; the helper only focuses existing windows. |
| Neo lock shortcut fails | `mango-neo` requires a separately configured Hyprlock; its bar still invokes gtklock. |
| Neo Tailscale toggle fails | Check that Tailscale is installed, its daemon is running, and your user can run `tailscale up`/`down`. |
| Tofi cannot load its font | Check the `font` path in `tofi/.config/tofi/config`, or use `font = Terminus (TTF)`; run `fc-match 'Terminus (TTF)'`. |
| Lock status module fails to load | Check its path and compatibility with your gtklock version. |
| Eww does not appear | Install Eww, stow `eww` and `colors`, and inspect `eww logs` for errors. |
| Screenshot is not saved | Check `grim`, `slurp`, and the stowed `bin` package. Run `~/.local/share/bin/snip.sh full` in a terminal for errors. The helper creates `~/Pictures/Screenshots` and reports success only after capture succeeds. |
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

Both bars include a Nextcloud module definition and helper; only the original
bar enables it by default. Their inactive `custom/media` definitions reference
an absent `mediaplayer.py`. Clipboard persistence is configured, but history is not:
installing `cliphist` alone does not add a watcher or history picker.

## Updating and removing the configs

Keep customizations in a local branch or fork. Before pulling changes, check
`git status` and commit or stash your edits. After updating, rerun Stow for the
packages you use so new files are linked, then reload the affected apps:

```sh
cd ~/dotfiles
git diff
stow --restow --target="$HOME" \
  colors fonts cursors geany gtk mango kitty waybar swaync gtklock fuzzel tofi bin mpd rmpc
```

For the original-theme package set hardcoded in `scripts/stow.sh`:

```sh
bash scripts/stow.sh --simulate --verbose
bash scripts/stow.sh --verbose
```

That helper does not detect your installed variant and omits Fish, MPD/rmpc,
Thunderbird, and Neo packages. Restow your chosen packages explicitly; manage
Thunderbird's existing profile as described above. If the theme
switcher manages your files, reapply your selected mode after pulling instead
of running Stow over its copies.

Local repair backups live in `.stow-backups/`, which Git ignores.

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
