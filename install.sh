cd ~ 
sudo pacman --needed -Syu nextcloud-client darktable rapid-photo-downloader protonmail-bridge proton-mail-bin proton-vpn-gtk-app proton-pass vivaldi vlc mpd rmpc drawio-desktop onlyoffice-bin audacity pencil2d micro qbittorrent fish audacity yazi ghostwriter kate thunderbird nheko github-cli stow thunar gtklock
rm -r ~/Downloads
sudo btrfs subvolume create Downloads
sudo snapper -c Downloads create-config Downloads
