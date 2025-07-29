#!/bin/bash
set -e
TIMESTAMP=$(date +%Y%m%d-%H%M%S)


RC=''
RED=''
YELLOW=''
CYAN=''
GREEN=''

reinstallgrub() {
    echo "Reinstall Grub"
    sudo rm -rf /efi/grub && \
    sudo grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=Arch && \
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}


yayinstall() {
    echo "yay Install"
    sudo pacman -S --needed git base-devel && \
    git clone https://aur.archlinux.org/yay.git /tmp/yay && \
    cd /tmp/yay && \
    makepkg -si 
    cd ~
}

osprober() {
    sudo pacman -S --noconfirm os-prober
    echo "Enable os-prober for Grub"
    sudo sed -i 's/GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
    echo "Generate grub.cfg"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}


snapper() {
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
}

    

reinstallgrub
yayinstall
osprober
snapper









