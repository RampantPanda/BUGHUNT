#!/usr/bin/env bash
# variables
file="/etc/pacman.conf"
key="3056513887B78AEB"
packages=(
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
	audacity
	yazi
	ghostwriter
	kate
	thunderbird
	github-cli
	stow
	thunar
	gtklock
	meson
	ninja
	pkgconf
	gtk3
	cliphist
	swayidle
	htop
	starship
	ttf-iosevka
	ttf-iosevkatermslab-nerd
	ttf-iosevkaterm-nerd
	ttf-iosevka-nerd
	brightnessctl
	wpctl
	freetype2
	harfbuzz
	cairo
	pango
	libxkbcommon
	wayland-protocols
	scdoc
	swaync
	tigervnc
	remmina
	freerdp
	libvncserver
	kitty
	yad
	waybar-git
	ark
	thunar-archive-plugin
	plasma-integration
)

# Add/sign Chaotic-AUR key if necessary
if ! sudo pacman-key --list-keys "$key" > /dev/null 2>&1; then
    sudo pacman-key --recv-key "$key" --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key "$key"
	sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
fi

# Add repository configuration if necessary
if ! grep -qxF '[chaotic-aur]' "$file"; then
    sudo tee -a "$file" > /dev/null <<'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
fi

## put Terminus Font to its place
sudo cp ../fonts/.local/share/fonts/terminus-ttf-4.49.3/*.ttf /usr/share/fonts/TTF/
## UPDATE AND INSTALL NECESSARY STUFF
cd ~ &
sudo pacman --needed -Syyu "${packages[@]}" &

## Install tofi
	git clone https://github.com/philj56/tofi.git &
	cd tofi &
	# Install
	meson build && ninja -C build install &

	#clean up
	cd .. &
	rm -rf tofi &

## Install gtklock modules

cd ~ &
git clone https://gitlab.com/wef/gtklock-runshell-module.git &
cd gtklock-runshell-module &
meson setup build --prefix=/usr &
ninja -C build &
sudo meson install -C build &
cd .. &
rm -rf gtklock-runshell-module &

## install markless
yay -S markless manuskript

## Stow all the things
# go to dotfiles, do a stow 

## Fix laptop lid suspend
# sudo mkdir -p /etc/systemd/logind.conf.d
# sudo nano /etc/systemd/logind.conf.d/10-lid.conf
# PUT THIS IN 10-lid.conf:
#[Login]
#HandleLidSwitch=suspend
#HandleLidSwitchExternalPower=suspend

## CREATE DOWNLOADS SUBVOLUME
#rm -r ~/Downloads
#sudo btrfs subvolume create Downloads
#sudo snapper -c Downloads create-config Downloads
