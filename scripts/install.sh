

#!/usr/bin/env bash

#!/usr/bin/env bash

file="/etc/pacman.conf"
key="3056513887B78AEB"

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
	noctalia
	cliphist
	swayidle
)
## UPDATE AND INSTALL NECESSARY STUFF
cd ~
sudo pacman --needed -Syu "${packages[@]}"
## INSTALL GTKLOCK MODULES
#git clone https://gitlab.com/wef/gtklock-runshell-module.git
#cd gtklock-runshell-module
#meson setup build --prefix=/usr
#ninja -C build
#sudo ninja -C build install
#cd ..
#sudo rm -r gtklock-runshell-module
## CREATE DOWNLOADS SUBVOLUME
#rm -r ~/Downloads
#sudo btrfs subvolume create Downloads
#sudo snapper -c Downloads create-config Downloads
