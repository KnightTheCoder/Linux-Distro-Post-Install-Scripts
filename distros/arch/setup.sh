#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

whiptail --title "Arch linux" --msgbox "Welcome to the arch linux script!" 0 0

packages=$(
    whiptail --title "Install List" --separate-output --checklist "Choose what to install/configure" 0 0 0 \
    "lutris" "Lutris" OFF \
    "goverlay mangohud gamemode" "Gaming overlay" OFF \
    "steam" "Steam" OFF \
    "haruna" "Haruna media player" ON \
    "celluloid" "Celluloid media player" ON \
    "vlc" "VLC media player" ON \
    "strawberry" "Strawberry music player" ON \
    "audacious" "Audacious music player" OFF \
    "libreoffice-fresh" "Libreoffice" OFF \
    "transmission-gtk" "Transmission bittorrent client" OFF \
    "qbittorrent" "Qbittorrent bittorrent client" OFF \
    "gimp" "GIMP" OFF \
    "kdenlive" "Kdenlive" OFF \
    "vscode" "Visual Studio Code" OFF \
    "nodejs" "Nodejs" OFF \
    "dotnet-sdk" ".NET sdk" OFF \
    "rustup" "Rust" OFF \
    "flatpak" "Flatpak" ON \
    "qemu" "QEMU/KVM" OFF \
    "openrgb" "OpenRGB" OFF \
    3>&1 1>&2 2>&3
)

# Remove new lines
packages=$(echo "$packages"| tr "\n" " ")

# Add defaults
services=()
setups=(hacknerd fish)
usergroups=()
aur=(ttf-ms-win11-auto)

nvim_config=$(choose_nvim_config)
setups+=("$nvim_config")

# Add packages to the correct categories
for package in $packages; do
    case $package in
        qemu )
            packages+=" qemu virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat dmidecode"

            services+=(libvirtd.service)

            usergroups+=(libvirt)

            # Remove package
            packages=${packages//"$package"/}
            ;;

        vscode|flatpak )
            if [ "$package" == vscode ]; then
                aur+=(visual-studio-code-bin)

                # Remove package
                packages=${packages//"$package"/}
            fi

            setups+=("$package")
            ;;

        rustup )
            aur+=("$package")
    
            setups+=(rust)

            # Remove package
            packages=${packages//"$package"/}
            ;;

        nodejs )
            packages+=" npm"

            setups+=(npm)
            ;;

        * ) ;;
    esac
done

# Add console apps
packages+=" fish neofetch kwrite htop btop neovim lynis github-cli eza bat zram-generator wget curl ark filelight"

# Add development packages
packages+=" git base-devel"

# Remove extra whitespace
packages=$(echo "$packages" | xargs)

# TODO: fix config duplication
# Add multilib for steam to work
if grep -iqzoP "\n\[multilib\]\nInclude = /etc/pacman.d/mirrorlist\n" /etc/pacman.conf; then
    echo -e "${YELLOW}multilib is already included${NC}"
else
    printf "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" | sudo tee -a /etc/pacman.conf
fi

# TODO: fix config duplication
# Modify packman config file
# Set parallel downloads, if it hasn't been set yet
if grep -iq "ParallelDownloads = 100" /etc/pacman.conf && grep -iq "Color" /etc/pacman.conf && grep -iq "ILoveCandy" /etc/pacman.conf; then
    echo -e "${YELLOW}Config was already modified!${NC}"
else
    printf "\n[options]\nParallelDownloads = 100\nColor\nILoveCandy\n" | sudo tee -a /etc/pacman.conf
fi

# Update system
sudo pacman -Syu --noconfirm

# TODO: list correct packages to remove
# Remove unneccessary packages
sudo pacman -Rns discover akregator kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat

# Install packages
# shellcheck disable=SC2086
sudo pacman -S $packages --noconfirm --needed

# Install yay
if [ -x /usr/bin/yay ]; then
    echo -e "${YELLOW}yay is already installed${NC}"
else
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin || exit
    makepkg -si
    rm -rf yay-bin
fi

# Install AUR packages
yay -S "${aur[@]}" --needed

# Setup zram
printf "[zram0]\n zram-size = ram / 2\n compression-algorithm = zstd\n swap-priority = 100\n fs-type = swap\n" | sudo tee /etc/systemd/zram-generator.conf

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
        vscode )
            setup_vscode
            ;;

        hacknerd )
            setup_hacknerd_fonts
            ;;

        nvchad )
            setup_nvchad
            ;;

        astrovim )
            setup_astrovim
            ;;

        rust )
            rustup default stable
            ;;

        npm )
            setup_npm
            ;;

        flatpak )
            setup_flatpak
            ;;

        fish )
            setup_fish
            ;;
    esac
done