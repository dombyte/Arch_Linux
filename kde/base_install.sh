#!/bin/bash
set -e
TIMESTAMP=$(date +%Y%m%d-%H%M%S)


RC=''
RED=''
YELLOW=''
CYAN=''
GREEN=''
additional_packages() {
    echo "Install additional Packages"
    yay -S --noconfirm \
    localsend-bin \
    firefox \
    1password \
    filen-desktop-bin \
    visual-studio-code-bin \
    solaar \
    onlyoffice-bin \
    betterbird-bin \
    ufw \
    fish \
    fastfetch \
    kitty \
    obsidian \
    curl \
    unzip
}

additional_fonts() {
    cd "$HOME" 
    echo "Install JetBrains Mono Fonts"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JetBrains/JetBrainsMono/master/install_manual.sh)"
}


dotfiles() {
    cd "$HOME" 
    cp -r "${HOME}/.config/" "${HOME}/.config-bak"
    git clone https://github.com/dombyte/dotfiles.git dotfiles
    cp -r dotfiles/kde/.config/* "$HOME/.config/"
    sudo rm -rf $HOME/dotfiles
}



additional_packages
additional_fonts
dotfiles