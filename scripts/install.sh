#!/usr/bin/env bash
# Install dependencies for the checked-in Arch desktop configs; Stow is separate.
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
dry_run=false
with_apps=false
theme=original
aur_helper=

usage() {
    cat <<'HELP'
Usage: bash scripts/install.sh [options]
  --dry-run          Print commands without installing or changing anything
  --with-apps        Also install the optional personal application collection
  --theme original|neo
                     Select the theme for the printed Stow instructions
  --aur-helper yay|paru
                     Choose an already installed AUR helper (otherwise autodetect)
  -h, --help         Show this help

Run as your regular user on Arch. Uses sudo for package/font/module installation.
Uses your configured repositories; does not add third-party repositories.
Does not stow files, change GTK settings, enable services, or change your shell.
HELP
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
while (($#)); do
    case "$1" in
        --dry-run) dry_run=true; shift ;;
        --with-apps) with_apps=true; shift ;;
        --theme|--aur-helper)
            (($# >= 2)) || fail "$1 requires a value"
            case "$1" in
                --theme) theme=$2 ;;
                --aur-helper) aur_helper=$2 ;;
            esac
            shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) fail "Unknown option: $1" ;;
    esac
done
[[ "$theme" == original || "$theme" == neo ]] || fail 'Theme must be original or neo'
[[ -z "$aur_helper" || "$aur_helper" == yay || "$aur_helper" == paru ]] || fail 'AUR helper must be yay or paru'
if ! "$dry_run" && ((EUID == 0)); then
    fail 'Run as your regular user, not with sudo; AUR builds must not run as root.'
fi
command -v pacman >/dev/null || fail 'This installer requires Arch Linux and pacman'

packages=(
    base-devel git stow fontconfig python python-gobject gtk3 gtk4
    meson ninja pkgconf scdoc wayland-protocols
    kitty fish fuzzel swaync gtklock swayidle wlopm
    wl-clip-persist wl-clipboard cliphist grim slurp libnotify brightnessctl
    networkmanager nm-connection-editor bluez bluez-utils blueman jq
    pipewire pipewire-pulse wireplumber pavucontrol
    thunar firefox geany yad ghostty wlogout
    capitaine-cursors breeze breeze-icons adwaita-icon-theme adw-gtk-theme
    gsettings-desktop-schemas noto-fonts ttf-terminus-nerd ttf-space-mono-nerd
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr
    xorg-xwayland polkit-gnome plasma-integration
    eww fastfetch starship pacman-contrib mpd rmpc
    mangowm-git waybar-git tofi
)
if "$with_apps"; then
    packages+=(
        nextcloud-client darktable rapid-photo-downloader protonmail-bridge
        proton-mail-bin proton-vpn-gtk-app proton-pass vivaldi vlc
        drawio-desktop onlyoffice-bin audacity pencil2d micro qbittorrent
        yazi ghostwriter kate thunderbird github-cli ark thunar-archive-plugin
        tigervnc remmina freerdp libvncserver htop
        ttf-iosevka ttf-iosevkatermslab-nerd ttf-iosevkaterm-nerd ttf-iosevka-nerd
        markless manuskript
    )
fi

# Read-only preflight against local sync databases. A normal -Syu below refreshes
# them and upgrades the system together, avoiding a partial Arch upgrade.
repo_packages=()
aur_packages=()
repo_catalog=$(pacman -Slq) || fail 'Cannot read pacman sync databases; initialize them with a full system update first.'
declare -A available=()
while IFS= read -r package; do
    [[ -z "$package" ]] || available["$package"]=1
done <<< "$repo_catalog"
for package in "${packages[@]}"; do
    if [[ -n "${available[$package]:-}" ]]; then
        repo_packages+=("$package")
    else
        aur_packages+=("$package")
    fi
done
if [[ -z "$aur_helper" ]]; then
    for candidate in yay paru; do
        if command -v "$candidate" >/dev/null; then
            aur_helper=$candidate
            break
        fi
    done
fi
if ((${#aur_packages[@]})); then
    if [[ -z "$aur_helper" ]] || ! command -v "$aur_helper" >/dev/null; then
        if "$dry_run"; then
            printf 'AUR helper required for: %s\n' "${aur_packages[*]}"
            aur_helper=${aur_helper:-yay}
        else
            fail "Install yay or paru first. Not found in configured sync databases: ${aur_packages[*]}"
        fi
    fi
fi

show() { printf '  '; printf '%q ' "$@"; printf '\n'; }
run() {
    show "$@"
    if ! "$dry_run"; then "$@"; fi
}

TERMINUS_DIR="$DOTFILES_DIR/fonts/.local/share/fonts/terminus-ttf-4.49.3"
shopt -s nullglob
fonts=("$TERMINUS_DIR"/*.ttf)
((${#fonts[@]})) || fail "Bundled Terminus fonts missing: $TERMINUS_DIR"
if ! "$dry_run"; then
    command -v sudo >/dev/null || fail 'sudo is required'
    sudo -v
fi
run sudo pacman -Syu --needed "${repo_packages[@]}"
if ((${#aur_packages[@]})); then
    run "$aur_helper" -S --needed "${aur_packages[@]}"
fi

# Tofi's config uses this absolute font path, in addition to the stowed fonts.
run sudo install -d /usr/share/fonts/TTF
run sudo install -m 644 "${fonts[@]}" /usr/share/fonts/TTF/
run sudo fc-cache -f
run mkdir -p "$HOME/.config" "$HOME/.local/share" "$HOME/Pictures/Screenshots"

# The runshell module explicitly targets gtklock's major ABI. Build the matching
# upstream release, not an unversioned checkout. See upstream README and tags.
module_version=4.0.0
if ! "$dry_run"; then
    installed_version=$(pacman -Q gtklock)
    installed_version=${installed_version#* }
    installed_version=${installed_version#*:}
    [[ "${installed_version%%.*}" == 4 ]] || fail "runshell $module_version requires gtklock 4; found $installed_version"
fi
build_dir=
cleanup() {
    if [[ -n "$build_dir" && -d "$build_dir" ]]; then
        rm -rf -- "$build_dir"
    fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
if "$dry_run"; then
    module_dir='/tmp/bughunt-module.XXXXXX/gtklock-runshell-module'
    printf 'Build plan (temporary directory created only during installation):\n'
else
    build_dir=$(mktemp -d -t bughunt-module.XXXXXXXX)
    module_dir="$build_dir/gtklock-runshell-module"
fi
run git clone --depth=1 --branch "$module_version" \
    https://gitlab.com/wef/gtklock-runshell-module.git "$module_dir"
run meson setup "$module_dir/build" "$module_dir" --prefix=/usr --libdir=lib
run meson compile -C "$module_dir/build"
run sudo meson install -C "$module_dir/build"
if ! "$dry_run"; then
    [[ -f /usr/lib/gtklock/runshell-module.so ]] || fail 'Expected runshell-module.so was not installed'
fi

printf '\nNext: review Stow conflicts with these simulations; remove --simulate to apply.\n'
common=(bin fonts cursors geany fish starship fastfetch fuzzel tofi swaync mpd rmpc)
if [[ "$theme" == neo ]]; then
    # Neo has GTK settings only; exclude the original settings while retaining CSS.
    show stow --dir="$DOTFILES_DIR" --target="$HOME" --simulate --verbose --no-folding --ignore='settings\.ini$' gtk
    show stow --dir="$DOTFILES_DIR" --target="$HOME" --simulate --verbose \
        "${common[@]}" colors-neo gtk-neo kitty-neo waybar-neo gtklock-neo eww-neo mango-vm-neo
    icon_theme=Bughunt-Neo
else
    show stow --dir="$DOTFILES_DIR" --target="$HOME" --simulate --verbose \
        "${common[@]}" colors gtk kitty waybar gtklock eww mango
    icon_theme=Bughunt
fi
printf '\nUnstow the opposite theme first if it is already installed. After Stow, in your desktop session:\n'
show gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
printf 'See README.md for NetworkManager/Bluetooth/MPD services, SwayNC, polkit, and portal setup.\n'
if "$dry_run"; then
    printf '\nDry run complete; no installation commands executed.\n'
else
    printf '\nDependencies installed; configuration installation remains a separate Stow step.\n'
fi
