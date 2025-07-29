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
    sudo grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=Arch-Linux && \
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
    update_prunenames
    echo "enable overlayfs"
    update_hooks_grub_btrfs
    sudo mkinitcpio -P
    sudo systemctl enable --now grub-btrfsd.service 
}

update_prunenames() {
    PRUNE_ADD_ITEMS=(".snapshot")
    CONF_FILE="/etc/updatedb.conf"
    BACKUP_FILE="${CONF_FILE}.bak"

    # Backup original config
    sudo cp "$CONF_FILE" "$BACKUP_FILE"

    new_content=""
    found=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*PRUNENAMES[[:space:]]*= ]]; then
            found=1

            # Normalize and extract value
            current_line=$(echo "$line" | sed -E 's/[[:space:]]*=[[:space:]]*/ = /')
            value=$(echo "$current_line" | sed -E 's/^PRUNENAMES = "(.*)"/\1/')

            # Convert to array
            read -ra existing <<< "$value"

            # Append new items only if not present
            for add_item in "${PRUNE_ADD_ITEMS[@]}"; do
                skip=0
                for existing_item in "${existing[@]}"; do
                    if [[ "$existing_item" == "$add_item" ]]; then
                        skip=1
                        break
                    fi
                done
                if [[ $skip -eq 0 ]]; then
                    existing+=("$add_item")
                fi
            done

            # Build new line
            IFS=' ' value="${existing[*]}"
            new_line="PRUNENAMES = \"$value\""
            new_content+="$new_line"$'\n'
        else
            new_content+="$line"$'\n'
        fi
    done < "$CONF_FILE"

    # Add line if not found
    if [[ $found -eq 0 ]]; then
        IFS=' ' value="${PRUNE_ADD_ITEMS[*]}"
        new_content+="PRUNENAMES = \"$value\""$'\n'
    fi

    # Write back
    echo "$new_content" | sudo tee "$CONF_FILE" > /dev/null

    echo "✅ PRUNENAMES successfully updated."
    echo "📝 Backup saved: $BACKUP_FILE"
}

update_hooks_grub_btrfs() {
    HOOKS_ADD_ITEMS=("grub-btrfs-overlayfs")
    CONF_FILE="/etc/mkinitcpio.conf"
    BACKUP_FILE="${CONF_FILE}.bak"

    # Backup original config
    sudo cp "$CONF_FILE" "$BACKUP_FILE"

    new_content=""
    found=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*HOOKS=\(.*\) ]]; then
            found=1

            # Extract hook array
            current_hooks=$(echo "$line" | sed -E 's/^[[:space:]]*HOOKS=\((.*)\)/\1/')
            read -ra hook_array <<< "$current_hooks"

            # Add missing hooks
            for new_hook in "${HOOKS_ADD_ITEMS[@]}"; do
                skip=0
                for existing_hook in "${hook_array[@]}"; do
                    if [[ "$existing_hook" == "$new_hook" ]]; then
                        skip=1
                        break
                    fi
                done
                if [[ $skip -eq 0 ]]; then
                    hook_array+=("$new_hook")
                fi
            done

            # Rebuild line
            new_line="HOOKS=(${hook_array[*]})"
            new_content+="$new_line"$'\n'
        else
            new_content+="$line"$'\n'
        fi
    done < "$CONF_FILE"

    # Add HOOKS line if not found
    if [[ $found -eq 0 ]]; then
        new_line="HOOKS=(${HOOKS_ADD_ITEMS[*]})"
        new_content+="$new_line"$'\n'
    fi

    # Write back
    echo "$new_content" | sudo tee "$CONF_FILE" > /dev/null

    echo "✅ HOOKS successfully updated."
    echo "📝 Backup saved: $BACKUP_FILE"
}


    

reinstallgrub
yayinstall
osprober
snapper









