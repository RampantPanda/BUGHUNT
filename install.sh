## UPDATE AND INSTALL NECESSARY STUFF
cd ~ 
sudo pacman --needed -Syu nextcloud-client darktable rapid-photo-downloader protonmail-bridge proton-mail-bin proton-vpn-gtk-app proton-pass vivaldi vlc mpd rmpc drawio-desktop onlyoffice-bin audacity pencil2d micro qbittorrent fish audacity yazi ghostwriter kate thunderbird nheko github-cli stow thunar gtklock meson ninja pkgconf gtk3
## INSTALL GTKLOCK MODULES
git clone https://gitlab.com/wef/gtklock-runshell-module.git
cd gtklock-runshell-module
meson setup build --prefix=/usr
ninja -C build
sudo ninja -C build install
cd ..
sudo rm -r gtklock-runshell-module
## CREATE DOWNLOADS SUBVOLUME
rm -r ~/Downloads
sudo btrfs subvolume create Downloads
sudo snapper -c Downloads create-config Downloads
