#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

#######################################
# Entry point for arch's setup
# Arguments:
#   None
# Outputs:
#   Logs for steps performed
#   whiptail screen
#######################################
function main() {
    local packages
    packages=$(
        whiptail --title "Arch linux app installer" --separate-output --notags --checklist "Choose which apps to install" 0 0 0 \
            "lutris" "Lutris" OFF \
            "wine" "Wine" OFF \
            "gaming-overlay" "Gaming overlay" OFF \
            "steam" "Steam" OFF \
            "steam-devices" "Steam devices (for the steam flatpak)" OFF \
            "itch" "Itch desktop app" OFF \
            "heroic" "Heroic Games Launcher" OFF \
            "firefox" "Firefox web browser" ON \
            "librewolf" "Librewolf web browser" OFF \
            "floorp" "Floorp web browser" OFF \
            "chromium" "Chromium web browser" OFF \
            "vivaldi" "Vivaldi web browser" OFF \
            "brave" "Brave web browser" OFF \
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
            "calibre" "Calibre E-book manager" OFF \
            "keepassxc" "KeePassXC" OFF \
            "vscode" "Visual Studio Code" OFF \
            "vscodium" "VSCodium" OFF \
            "nodejs" "Nodejs" OFF \
            "dotnet-sdk" ".NET SDK" OFF \
            "rustup" "Rust" OFF \
            "go" "Golang" OFF \
            "java" "Java OpenJDK" OFF \
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

    local cli_packages
    cli_packages=$(
        whiptail --title "CLI install" --separate-output --notags --checklist "Select cli applications to install" 0 0 0 \
            "fastfetch" "fastfetch" ON \
            "btop" "btop++" ON \
            "github-cli" "github cli" OFF \
            3>&1 1>&2 2>&3
    )

    packages+=" $cli_packages"

    packages+=" neovim eza bat zram-generator wget curl ark filelight git base-devel p7zip unrar"

    local shells
    shells=$(choose_shells)

    packages+=" $shells"

    # Remove new lines
    packages=$(echo "$packages" | tr "\n" " ")

    # Add defaults
    local services=()
    local setups=(hacknerd)
    local usergroups=()
    local aur=(ttf-ms-win11-auto)
    local packages_to_remove="akregator kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat"

    local nvim_config
    nvim_config=$(choose_nvim_config)
    setups+=("$nvim_config")

    # Add packages to the correct categories
    for package in $packages; do
        case $package in

        bash)
            packages+=" gawk"

            setups+=(bash)
            ;;

        fish)
            setups+=(fish)
            ;;

        zsh)
            setups+=(zsh)
            ;;

        starship)
            setups+=(starship)
            ;;

        gaming-overlay)
            packages=$(remove_package "$packages" "$package")

            packages+=" goverlay mangohud gamemode"
            ;;

        steam-devices)
            packages=$(remove_package "$packages" "$package")

            aur+=(steam-devices-git)
            ;;

        wine)
            packages+=" winetricks"
            ;;

        brave)
            packages=$(remove_package "$packages" "$package")

            aur+=(brave-bin)
            ;;

        librewolf)
            packages=$(remove_package "$packages" "$package")

            aur+=(librewolf-bin)
            ;;

        floorp)
            packages=$(remove_package "$packages" "$package")

            aur+=(floorp-bin)
            ;;

        qemu)
            packages+=" virt-manager virt-viewer dnsmasq vde2 bridge-utils openbsd-netcat dmidecode"

            services+=(libvirtd.service)

            usergroups+=(libvirt)
            ;;

        virtualbox)
            setups+=(virtualbox)

            usergroups+=(vboxusers)
            ;;

        heroic)
            packages=$(remove_package "$packages" "$package")

            aur+=(heroic-games-launcher-bin)
            ;;

        itch)
            packages=$(remove_package "$packages" "$package")

            setups+=("$package")
            ;;

        vscode)
            packages=$(remove_package "$packages" "$package")

            aur+=(visual-studio-code-bin)

            setups+=(vscode)
            ;;

        vscodium)
            packages=$(remove_package "$packages" "$package")

            aur+=(vscodium-bin)

            setups+=(vscodium)
            ;;

        rustup)
            setups+=(rust)
            ;;

        nodejs)
            packages+=" npm"

            setups+=(npm)
            ;;

        java)
            packages=$(remove_package "$packages" "$package")

            packages+=" jdk-openjdk"
            ;;

        xampp)
            packages=$(remove_package "$packages" "$package")

            setups+=(xampp)
            ;;

        docker)
            packages+=" docker-compose"
            services+=(docker.service)
            usergroups+=(docker)
            ;;

        docker-desktop)
            packages=$(remove_package "$packages" "$package")

            aur+=(docker-desktop)
            ;;

        flatpak)
            setups+=(flatpak)
            ;;

        esac
    done

    # Remove extra whitespace
    packages=$(echo "$packages" | xargs)

    # Ask if you want to remove discover
    if whiptail --title "Remove discover" --yesno "Would you like to remove discover?" --defaultno 0 0; then
        packages_to_remove+=" discover"
    fi

    echo -e "${GREEN}Adding multilib repo...${NC}"
    # Add multilib for steam to work
    if grep -iqzoP "\n\[multilib\]\n" /etc/pacman.conf; then
        echo -e "${YELLOW}multilib is already included${NC}"
    else
        printf "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" | sudo tee -a /etc/pacman.conf
    fi

    echo -e "${GREEN}Modifying pacman config...${NC}"
    # Modify pacman config file
    # Set parallel downloads, if it hasn't been set yet
    if grep -iq "ParallelDownloads = 20" /etc/pacman.conf && grep -iq "Color" /etc/pacman.conf && grep -iq "ILoveCandy" /etc/pacman.conf; then
        echo -e "${YELLOW}Config was already modified${NC}"
    else
        printf "\n[options]\nParallelDownloads = 20\nColor\nILoveCandy\n" | sudo tee -a /etc/pacman.conf
    fi

    # Update repos and install new keyrings
    sudo pacman -Syy archlinux-keyring --noconfirm --needed

    # Update system
    sudo pacman -Syu --noconfirm

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

    echo -e "${GREEN}Setting up zram...${NC}"
    # Setup zram
    printf "[zram0]\n zram-size = ram / 2\n compression-algorithm = zstd\n swap-priority = 100\n fs-type = swap\n" | sudo tee /etc/systemd/zram-generator.conf

    echo -e "${GREEN}Adding user to groups...${NC}"
    # Add user to groups
    for group in "${usergroups[@]}"; do
        sudo groupadd "$group"
        sudo usermod -a -G "$group" "$USER"
    done

    # Run setups
    for app in "${setups[@]}"; do
        case $app in
        itch)
            setup_itch_app
            ;;

        vscode)
            setup_vscode code
            ;;

        vscodium)
            setup_vscode codium
            ;;

        hacknerd)
            setup_hacknerd_fonts
            ;;

        nvchad)
            setup_nvchad
            ;;

        astronvim)
            setup_astronvim
            ;;

        rust)
            rustup default stable
            ;;

        npm)
            setup_npm
            ;;

        xampp)
            setup_xampp
            ;;

        virtualbox)
            setup_virtualbox_extension
            ;;

        flatpak)
            setup_flatpak
            ;;

        bash)
            setup_bash
            ;;

        fish)
            setup_fish
            ;;

        zsh)
            setup_zsh
            ;;

        starship)
            setup_starship
            ;;

        esac
    done

    echo -e "${GREEN}Starting services...${NC}"
    # Start services
    for serv in "${services[@]}"; do
        sudo systemctl enable --now "$serv"
    done
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    main
fi
