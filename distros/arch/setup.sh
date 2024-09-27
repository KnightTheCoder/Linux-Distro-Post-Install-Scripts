#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

packages=$(
    whiptail --title "Arch linux app installer" --separate-output --checklist "Choose which apps to install" 0 0 0 \
    "lutris" "Lutris" OFF \
    "wine" "Wine" OFF \
    "gaming-overlay" "Gaming overlay" OFF \
    "steam" "Steam" OFF \
    "itch" "Itch desktop app" OFF \
    "heroic" "Heroic Games Launcher" OFF \
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
    "keepassxc" "KeePassXC" OFF \
    "vscode" "Visual Studio Code" OFF \
    "vscodium" "VSCodium" OFF \
    "nodejs" "Nodejs" OFF \
    "dotnet-sdk" ".NET sdk" OFF \
    "rustup" "Rust" OFF \
    "go" "Golang" OFF \
    "java" "Java openjdk" OFF \
    "xampp" "XAMPP" OFF \
    "docker" "Docker engine" OFF \
    "docker-desktop" "Docker desktop" OFF \
    "podman" "Podman" OFF \
    "distrobox" "Distrobox" OFF \
    "flatpak" "Flatpak" ON \
    "qemu" "QEMU/KVM" OFF \
    "virtualbox" "Oracle Virtualbox" OFF \
    "openrgb" "OpenRGB" OFF \
    3>&1 1>&2 2>&3
)

cli_packages=$(
    whiptail --title "CLI install" --separate-output --checklist "Select cli applications to install" 0 0 0 \
    "neofetch" "neofetch" ON \
    "htop" "htop" ON \
    "btop" "btop++" ON \
    "github-cli" "github cli" OFF \
    3>&1 1>&2 2>&3
)

packages+=" $cli_packages"

packages+=" neovim eza bat zram-generator wget curl ark filelight git base-devel p7zip unrar rar"

shells=$(choose_shells)

packages+=" $shells"

# Remove new lines
packages=$(echo "$packages"| tr "\n" " ")

# Add defaults
services=()
setups=(hacknerd)
usergroups=()
aur=(ttf-ms-win11-auto)
packages_to_remove="akregator kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat"

nvim_config=$(choose_nvim_config)
setups+=("$nvim_config")

# Add packages to the correct categories
for package in $packages; do
    case $package in
        bash )
            packages+=" gawk"

            setups+=(bash)
            ;;

        fish )
            setups+=(fish)
            ;;

        zsh )
            setups+=(zsh)
            ;;

        starship )
            setups+=(starship)
            ;;

        gaming-overlay)
            packages=$(remove_package "$packages" "$package")

            packages+=" goverlay mangohud gamemode"
            ;;

        wine )
            packages+=" winetricks"
            ;;

        qemu )
            packages+=" virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat dmidecode"

            services+=(libvirtd.service)

            usergroups+=(libvirt)
            ;;

        virtualbox )
            setups+=(virtualbox)

            usergroups+=(vboxusers)
            ;;

        heroic )
            packages=$(remove_package "$packages" "$package")

            aur+=(heroic-games-launcher-bin)
            ;;

        itch )
            packages=$(remove_package "$packages" "$package")

            setups+=("$package")
            ;;

        vscode )
            packages=$(remove_package "$packages" "$package")

            aur+=(visual-studio-code-bin)

            setups+=(vscode)
            ;;

        vscodium )
            packages=$(remove_package "$packages" "$package")

            aur+=(vscodium-bin)
            
            setups+=(vscodium)
            ;;

        rustup )
            setups+=(rust)
            ;;

        nodejs )
            packages+=" npm"

            setups+=(npm)
            ;;

        java )
            packages=$(remove_package "$packages" "$package")

            packages+=" jdk-openjdk"
            ;;

        xampp )
            packages=$(remove_package "$packages" "$package")

            setups+=(xampp)
            ;;

        docker )
            packages+=" docker-compose"
            services+=(docker.service)
            usergroups+=(docker)
            ;;

        docker-desktop )
            packages=$(remove_package "$packages" "$package")

            aur+=(docker-desktop)
            ;;

        flatpak )
            setups+=(flatpak)
            ;;

        * ) ;;
    esac
done

# Remove extra whitespace
packages=$(echo "$packages" | xargs)

# Ask if you want to remove discover
if whiptail --title "Remove discover" --yesno "Would you like to remove discover?" 0 0; then
    packages_to_remove+=" discover"
fi

# Add multilib for steam to work
if grep -iqzoP "\n\[multilib\]\n" /etc/pacman.conf; then
    echo -e "${YELLOW}multilib is already included${NC}"
else
    printf "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" | sudo tee -a /etc/pacman.conf
fi

# Modify packman config file
# Set parallel downloads, if it hasn't been set yet
if grep -iq "ParallelDownloads = 20" /etc/pacman.conf && grep -iq "Color" /etc/pacman.conf && grep -iq "ILoveCandy" /etc/pacman.conf; then
    echo -e "${YELLOW}Config was already modified!${NC}"
else
    printf "\n[options]\nParallelDownloads = 20\nColor\nILoveCandy\n" | sudo tee -a /etc/pacman.conf
fi

# Update repos and install new keyrings
sudo pacman -Syy archlinux-keyring --noconfirm --needed

# Update system
sudo pacman -Syu --noconfirm

# TODO: list correct packages to remove
# Remove unneccessary packages
# shellcheck disable=SC2086
sudo pacman -Rns $packages_to_remove

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
    cd ..
    rm -rf yay-bin
fi

# Install AUR packages
yay -S "${aur[@]}" --needed

# Setup zram
printf "[zram0]\n zram-size = ram / 2\n compression-algorithm = zstd\n swap-priority = 100\n fs-type = swap\n" | sudo tee /etc/systemd/zram-generator.conf

# Add user to groups
for group in "${usergroups[@]}"; do
    sudo groupadd "$group"
    sudo usermod -a -G "$group" "$USER"
done

# Run setups
for app in "${setups[@]}"; do
    case $app in
        itch )
            setup_itch_app
            ;;

        vscode )
            setup_vscode code
            ;;

        vscodium )
            setup_vscode codium
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

        xampp )
            setup_xampp
            ;;

        virtualbox )
            setup_virtualbox_extension
            ;;

        flatpak )
            setup_flatpak
            ;;

        bash )
            setup_bash
            ;;

        fish )
            setup_fish
            ;;

        zsh )
            setup_zsh
            ;;

        starship )
            setup_starship
            ;;
    esac
done

# Start services
for serv in "${services[@]}"; do
    sudo systemctl enable --now "$serv"
done