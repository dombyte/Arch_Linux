# Custom Arch

Arch with btrfs and Snapper

## archinstall script

### Disk configuration

- /efi fat32
- / btrfs

#### btrfs subvolume

- @ in /
- @home in /home
- @opt in /opt
- @srv in /srv
- @cache in /var/cache
- @log in /var/log
- @spool in /var/spool
- @tmp in /var/tmp

### Addition packages

- amd-ucode
- bash-completion
- git
- plocale

## Automatic Config via Script

```shell
git clone https://github.com/dombyte/Arch_Linux.git
```

```shell
cd Arch_Linux/
```

```shell
sh archconfig.sh
```

## Manual Steps

```shell
git clone https://github.com/dombyte/Arch_Linux.git
```

```shell
cd Arch_Linux/
```

#### Reinstall Grub

```shell
rm -rf /efi/grub
```

```shell
grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=Arch
```

```shell
grub-mkconfig -o /boot/grub/grub.cfg
```

#### yay install

```shell
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

#### custom packages

```shell
yay -S localsend-bin brave-bin 1password filen-desktop-bin visual-studio-code-bin solaar onlyoffice-bin betterbird-bin cryptomator-bin
```

#### Snapper

Video Guide:

- Part 1: https://www.youtube.com/watch?v=FiK1cGbyaxs
- Part 2: https://www.youtube.com/watch?v=rl-VasRoUe4
- Part 3: https://www.youtube.com/watch?v=aCy5kdSlHmY

```shell
sudo pacman -S snapper snap-pac grub-btrfs inotify-tools
```

```shell
yay -S btrfs-assistant
```

Create snapper config for root

```shell
sudo snapper -c root create-config /
```

allow user to edit snapshots

```shell
sudo snapper -c root set-config ALLOW_USER="$USER" SYNC_ACL=yes
```

update `/etc/updatedb.conf` to not index .snapshot (add .snapshot to PRUNENAMES) \
\
enable overlayfs in `/etc/mkinitcpio.conf` (add grub-btrfs-overlayfs to HOOKS) \

```shell
sudo mkinitcpio -P
```

```shell
sudo systemctl enable --now grub-btrfsd.service
```

#### Logitech Keyboard not working

**Solution:** `enable=true` in `~/.config/kcminputrc`

## Grub Reinstall after boot fail

### 1. Boot Arch Iso

### Mount Root Partition

`sudo mount -o subvol=@ /dev/sdX2 /mnt`

### Mount EFI Partition

```
sudo mkdir -p /mnt/efi
sudo mount /dev/sdX1 /mnt/efi
```

### Mount System Partitions

```
sudo mount --bind /dev /mnt/dev
sudo mount --bind /proc /mnt/proc
sudo mount --bind /sys /mnt/sys
sudo mount --bind /run /mnt/run
sudo mount --bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars
```

### Chroot into System

`sudo arch-chroot /mnt`

### Reinstall Grub

`grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=Arch`

### Generate Grub Config

`grub-mkconfig -o /boot/grub/grub.cfg`

### Exit

```
exit
sudo umount -R /mnt
sudo reboot
```
