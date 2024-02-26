#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

whiptail --title "Arch linux" --msgbox "Welcome to the arch linux script!" 0 0

packages=$(
    whiptail --title "Install List" --separate-output --checklist "Choose what to install/configure" 0 0 0 \
    "lutris" "Lutris" OFF \
    "goverlay mangohud gamemode" "Gaming overlay" OFF \
    "haruna celluloid vlc" "Media players" ON \
    "strawberry" "Strawberry music player" ON \
    "audacious" "Audacious music player" OFF \
    "transmission-gtk" "Transmission bittorrent client" OFF \
    "steam steam-devices" "Steam" OFF \
    "gimp" "GIMP" OFF \
    "kdenlive" "Kdenlive" OFF \
    "itch" "Itch desktop app" OFF \
    "vscode" "Visual Studio Code" ON \
    "nodejs" "Nodejs" OFF \
    "dotnet" ".NET sdk" OFF \
    "rustup" "Rust" OFF \
    "flatpak" "Flatpak" ON \
    "qemu" "QEMU/KVM" OFF \
    3>&1 1>&2 2>&3
)

# Remove new lines
packages=$(echo "$packages"| tr "\n" " ")

# Add defaults
services=()
setups=(hacknerd fish nvchad)
usergroups=()

# Add packages to the correct categories
for package in $packages; do
    case $package in
        itch )
            if [ "$package" == itch ]; then
                setups+=("$package")
            fi

            # Remove package
            packages=${packages//"$package"/}
            ;;

        qemu )
            packages+=" @virtualization"

            services+=(libvirtd.service)

            usergroups+=(libvirt)

            # Remove package
            packages=${packages//"$package"/}
            ;;

        vscode )
            setups+=(vscode)
            ;;

        rustup )
            setups+=(rust)
            ;;

        nodejs )
            setups+=(npm)
            ;;

        flatpak )
            setups+=(flatpak)
            ;;

        * ) ;;
    esac
done

# Add console apps
packages+=" fish neofetch kwrite htop btop neovim lynis gh eza bat"

# Remove extra whitespace
packages=$(echo "$packages" | xargs)

# Modify dnf config file
# Set parallel downloads and default to yes, if it hasn't been set yet
if grep -iq "ParallelDownloads = 100" /etc/pacman.conf; then
    echo -e "${YELLOW}Config was already modified!${NC}"
else
    printf "ParallelDownloads = 5\n" | sudo tee -a /etc/pacman.conf
fi

# Update system
sudo dnf upgrade -y --refresh

# Remove unneccessary packages
sudo dnf remove -y akregator plasma-discover dragon elisa-player kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat qt5-qdbusviewer --exclude=flatpak

# Install packages
# shellcheck disable=SC2086
sudo dnf install -y $packages

# Start services
for serv in "${services[@]}"; do
    sudo systemctl enable --now "$serv"
done

# Add user to groups
for group in "${usergroups[@]}"; do
    sudo usermod -a -G "$group" "$USER"
done

# Run setups
for app in "${setups[@]}"; do
    case $app in
        itch )
            setup_itch_app
            ;;

        vscode )
            setup_vscode
            ;;

        hacknerd )
            setup_hacknerd_fonts
            ;;

        fish )
            setup_fish
            ;;

        nvchad )
            setup_nvchad
            ;;

        rust )
            setup_rust
            ;;

        npm )
            setup_npm
            ;;

        flatpak )
            setup_flatpak
            ;;
    esac
done