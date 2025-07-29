#!/bin/bash

set -e
set -o pipefail



# This script updates the NVIDIA modules in a configuration file for Hyprland.
nvidia_modules() {

NVIDIA_MODULES=("nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm")
CONF_FILE_NVIDIA="/etc/mkinitcpio.conf"
BACKUP_FILE_NVIDIA="${CONF_FILE_NVIDIA}.bak"

sudo cp "$CONF_FILE_NVIDIA" "$BACKUP_FILE_NVIDIA"


new_content=""
found=0

while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*MODULES= ]]; then
        found=1

        # Extract current content inside the parentheses
        current_modules=$(echo "$line" | sed -E 's/^[[:space:]]*MODULES=\((.*)\)/\1/')
        read -ra existing <<< "$current_modules"

        # Insert into associative array to avoid duplicates
        declare -A module_map
        for mod in "${existing[@]}"; do
            module_map["$mod"]=1
        done

        for mod in "${NVIDIA_MODULES[@]}"; do
            module_map["$mod"]=1
        done

        # Assemble new list
        updated_modules=()
        for mod in "${!module_map[@]}"; do
            updated_modules+=("$mod")
        done

        # Sorting (optional)
        IFS=$'\n' sorted=($(sort <<<"${updated_modules[*]}"))
        unset IFS

        # New MODULES line
        new_line="MODULES=(${sorted[*]})"
        new_content+="$new_line"$'\n'
    else
        new_content+="$line"$'\n'
    fi
done < "$CONF_FILE_NVIDIA"

# If no MODULES line was found, append it to the end
if [[ $found -eq 0 ]]; then
    new_line="MODULES=(${NVIDIA_MODULES[*]})"
    new_content+="$new_line"$'\n'
fi

# Write new content to file
echo "$new_content" | sudo tee "$CONF_FILE_NVIDIA" > /dev/null

echo "✅ NVIDIA-MODULES successfully updated."
echo "📝 Backup saved: $BACKUP_FILE_NVIDIA"
}

update_hyprconfig() {
    # Update Hyprland configuration
    echo "Updating Hyprland configuration..."

    # Target file
    TARGET_FILE_HYPR="$HOME/.config/hypr/hyprland.conf"

    # Create backup if file exists
    if [ -f "$TARGET_FILE_HYPR" ]; then
        BACKUP_FILE_HYPR="${TARGET_FILE_HYPR}.bak"
        echo "Existing file found. Creating backup: $BACKUP_FILE_HYPR"
        sudo cp "$TARGET_FILE_HYPR" "$BACKUP_FILE_HYPR"
    else
        echo "File does not exist. A new one will be created."
    fi


    sudo bash -c "cat << EOF > $TARGET_FILE_HYPR
    # Hyprland configuration
    LIBVA_DRIVER_NAME=nvidia
    __GLX_VENDOR_LIBRARY_NAME=nvidia
    XDG_SESSION_TYPE=wayland
    GBM_BACKEND=nvidia-drm
    NVD_BACKEND=direct
    ELECTRON_OZONE_PLATFORM_HINT=auto
    # Autostart applications
    exec-once=/usr/lib/polkit-kde-authentication-agent-1 # Polkit for privilege management
    exec-once=/usr/bin/dunst
    EOF"

    echo "✅ Hyprland configuration updated."
}

pacman -S --noconfirm --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si # builds with makepkg
pacman -S --noconfirm \
    pipewire \
    wireplumber \
    linux-headers \
    hyprland \
    nvidia-dkms \
    nvidia-utils \
    lib32-nvidia-utils \
    egl-wayland \
    xorg-xwayland \
    curl \
    sddm \
    firefox \
    kitty \
    xdg-desktop-portal-hyprland \
    polkit-kde-agent \
    qt5-wayland \
    qt6-wayland \
    dunst \

systemctl enable sddm.service
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)"
nvidia_modules
update_hyprconfig
