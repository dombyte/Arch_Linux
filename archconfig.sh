#!/bin/bash

set -e
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "Reinstall Grub"
sudo rm -rf /efi/grub && \
sudo grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=Arch && \
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "yay Install"
sudo pacman -S --needed git base-devel && \
git clone https://aur.archlinux.org/yay.git /tmp/yay && \
cd /tmp/yay && \
makepkg -si 
cd ~

echo "Install additional Packages"
yay -S --noconfirm \
    localsend-bin \
    brave-bin \
    1password \
    filen-desktop-bin \
    visual-studio-code-bin \
    solaar \
    onlyoffice-bin \
    betterbird-bin \
    cryptomator-bin 

echo "Install Snapper"
sudo pacman -S --noconfirm \
    snapper \
    snap-pac \
    grub-btrfs \
    inotify-tools
    
echo "Install BTRFS Assistant"
yay -S --noconfirm btrfs-assistant

echo "Create Snapper Config for Root"
sudo snapper -c root create-config /

echo "allow user snapshot edit"
sudo snapper -c root set-config ALLOW_USER="$USER" SYNC_ACL=yes

echo "update updatedb.conf"
sudo sed -i -E '
/^PRUNENAMES[[:space:]]*=/ {
  s/[[:space:]]*=[[:space:]]*/ = /
  /[[:space:]]\.snapshot/! s/^(PRUNENAMES = ".*)"/\1 .snapshot"/
}
' /etc/updatedb.conf

echo "enable overlayfs"
sudo sed -i -E '/^HOOKS=\(/ {
  /grub-btrfs-overlayfs/! s/\)/ grub-btrfs-overlayfs)/
}' /etc/mkinitcpio.conf
sudo mkinitcpio -P
sudo systemctl enable --now grub-btrfsd.service 

echo "Install Ohmybash"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended

echo "Install Powerline Fonts"
git clone https://github.com/powerline/fonts.git /tmp/fonts
sh /tmp/fonts/install.sh


echo "Backup .bashrc"
cp "$HOME/.bashrc" "$HOME/.bashrc_$TIMESTAMP.bak"
echo "Copy .bashrc"
cp "src/.bashrc" "$HOME/.bashrc"

echo "Backup .gitconfig"
cp "$HOME/.gitconfig" "$HOME/.gitconfig_$TIMESTAMP.bak"
echo "Copy .gitconfig"
cp "src/.gitconfig" "$HOME/.gitconfig"

echo "Backup kcminputrc"
cp "$HOME/.config/kcminputrc" "$HOME/.config/kcminputrcg_$TIMESTAMP.bak"
echo "Copy kcminputrc"
cp "src/.config/kcminputrc" "$HOME/.config/kcminputrc"