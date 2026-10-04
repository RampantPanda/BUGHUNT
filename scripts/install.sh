#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------

PACMAN_CONF="/etc/pacman.conf"
CHAOTIC_KEY="3056513887B78AEB"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

packages=(
    # Applications
    nextcloud-client
    darktable
    rapid-photo-downloader
    protonmail-bridge
    proton-mail-bin
    proton-vpn-gtk-app
    proton-pass
    vivaldi
    vlc
    mpd
    rmpc
    drawio-desktop
    onlyoffice-bin
    audacity
    pencil2d
    micro
    qbittorrent
    fish
    yazi
    ghostwriter
    kate
    thunderbird
    github-cli
    thunar
    ark
    thunar-archive-plugin

    # Desktop / Wayland
    waybar-git
    swaync
    gtklock
    swayidle
    cliphist
    brightnessctl
    kitty
    yad

    # KDE / Qt integration
    plasma-integration

    # IMPORTANT:
    # Used by GTK/Waybar for StatusNotifier tray icons,
    # including Nextcloud state-ok/state-sync icons.
    breeze-icons

    # Remote desktop
    tigervnc
    remmina
    freerdp
    libvncserver

    # CLI tools
    stow
    htop
    starship
    git

    # Fonts
    ttf-iosevka
    ttf-iosevkatermslab-nerd
    ttf-iosevkaterm-nerd
    ttf-iosevka-nerd
    ttf-terminus-nerd
    ttf-space-mono-nerd

    # Build dependencies
    meson
    ninja
    pkgconf
    gtk3
    freetype2
    harfbuzz
    cairo
    pango
    libxkbcommon
    wayland-protocols
    scdoc

    # fonts

)

# ------------------------------------------------------------
# Chaotic-AUR
# ------------------------------------------------------------

echo "==> Configuring Chaotic-AUR"

if ! sudo pacman-key --list-keys "$CHAOTIC_KEY" >/dev/null 2>&1; then
    sudo pacman-key --recv-key "$CHAOTIC_KEY" \
        --keyserver keyserver.ubuntu.com

    sudo pacman-key --lsign-key "$CHAOTIC_KEY"

    sudo pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'

    sudo pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
fi

if ! grep -qxF '[chaotic-aur]' "$PACMAN_CONF"; then
    sudo tee -a "$PACMAN_CONF" >/dev/null <<'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
fi

# ------------------------------------------------------------
# Packages
# ------------------------------------------------------------

echo "==> Installing packages"

sudo pacman -Syu --needed "${packages[@]}"

# ------------------------------------------------------------
# Terminus font
# ------------------------------------------------------------

echo "==> Installing Terminus font"

TERMINUS_DIR="$DOTFILES_DIR/../fonts/.local/share/fonts/terminus-ttf-4.49.3"

if [[ -d "$TERMINUS_DIR" ]]; then
    sudo mkdir -p /usr/share/fonts/TTF
    sudo cp "$TERMINUS_DIR"/*.ttf /usr/share/fonts/TTF/
    sudo fc-cache -f
else
    echo "WARNING: Terminus font directory not found:"
    echo "         $TERMINUS_DIR"
fi

# ------------------------------------------------------------
# GTK / icon theme
# ------------------------------------------------------------

echo "==> Configuring GTK icon theme"

mkdir -p \
    "$HOME/.config/gtk-3.0" \
    "$HOME/.config/gtk-4.0"

set_gtk_icon_theme() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        cat > "$file" <<'EOF'
[Settings]
gtk-icon-theme-name=breeze-dark
EOF
        return
    fi

    if grep -q '^gtk-icon-theme-name=' "$file"; then
        sed -i \
            's/^gtk-icon-theme-name=.*/gtk-icon-theme-name=breeze-dark/' \
            "$file"
    elif grep -q '^\[Settings\]' "$file"; then
        sed -i \
            '/^\[Settings\]/a gtk-icon-theme-name=breeze-dark' \
            "$file"
    else
        cat >> "$file" <<'EOF'

[Settings]
gtk-icon-theme-name=breeze-dark
EOF
    fi
}

set_gtk_icon_theme "$HOME/.config/gtk-3.0/settings.ini"
set_gtk_icon_theme "$HOME/.config/gtk-4.0/settings.ini"

# This is the setting Waybar actually ended up consulting for
# StatusNotifier tray icon lookup.
if command -v gsettings >/dev/null 2>&1; then
    gsettings set \
        org.gnome.desktop.interface \
        icon-theme \
        'breeze-dark'
fi

# ------------------------------------------------------------
# Tofi
# ------------------------------------------------------------

echo "==> Installing tofi"

TOFI_BUILD="$(mktemp -d)"

git clone --depth=1 \
    https://github.com/philj56/tofi.git \
    "$TOFI_BUILD/tofi"

meson setup \
    "$TOFI_BUILD/tofi/build" \
    "$TOFI_BUILD/tofi" \
    --prefix=/usr

ninja -C "$TOFI_BUILD/tofi/build"

sudo ninja \
    -C "$TOFI_BUILD/tofi/build" \
    install

rm -rf "$TOFI_BUILD"

# ------------------------------------------------------------
# gtklock runshell module
# ------------------------------------------------------------

echo "==> Installing gtklock runshell module"

GTKLOCK_BUILD="$(mktemp -d)"

git clone --depth=1 \
    https://gitlab.com/wef/gtklock-runshell-module.git \
    "$GTKLOCK_BUILD/gtklock-runshell-module"

meson setup \
    "$GTKLOCK_BUILD/gtklock-runshell-module/build" \
    "$GTKLOCK_BUILD/gtklock-runshell-module" \
    --prefix=/usr

ninja \
    -C "$GTKLOCK_BUILD/gtklock-runshell-module/build"

sudo meson install \
    -C "$GTKLOCK_BUILD/gtklock-runshell-module/build"

rm -rf "$GTKLOCK_BUILD"

# ------------------------------------------------------------
# AUR packages
# ------------------------------------------------------------

if command -v yay >/dev/null 2>&1; then
    echo "==> Installing remaining AUR packages"
    yay -S --needed markless manuskript
else
    echo "WARNING: yay is not installed."
    echo "         Skipping: markless manuskript"
fi

# ------------------------------------------------------------
# Stow dotfiles
# ------------------------------------------------------------

echo
echo "==> Packages and supporting components installed."
echo
echo "Next step: stow the desired dotfile packages from:"
echo "  $DOTFILES_DIR"
echo

# Example:
#
# cd "$DOTFILES_DIR"
# stow -t "$HOME" waybar mango gtk fish kitty etc...
#
# Better to list the packages explicitly rather than blindly stowing
# every directory in the repository.

# ------------------------------------------------------------
# Optional: laptop lid suspend
# ------------------------------------------------------------

# sudo mkdir -p /etc/systemd/logind.conf.d
#
# sudo tee /etc/systemd/logind.conf.d/10-lid.conf >/dev/null <<'EOF'
# [Login]
# HandleLidSwitch=suspend
# HandleLidSwitchExternalPower=suspend
# EOF
#
# sudo systemctl restart systemd-logind

# ------------------------------------------------------------
# Optional: Downloads BTRFS subvolume
# ------------------------------------------------------------

# rm -rf "$HOME/Downloads"
# sudo btrfs subvolume create "$HOME/Downloads"
# sudo snapper -c Downloads create-config "$HOME/Downloads"

echo "==> Done"
