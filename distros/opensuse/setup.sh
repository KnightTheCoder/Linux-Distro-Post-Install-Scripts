#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

function create_snapshot() {
    local snapshot_type=$1 # 0 or anything else
    local prompt_tag='before'
    local snapshot_tag='Pre'

    case $snapshot_type in
        0)
            prompt_tag='before'
            snapshot_tag='Pre'
            ;;

        *)
            prompt_tag='after'
            snapshot_tag='Post'
            ;;
    esac

    if whiptail --yesno "Do you want to make a snapshot ${prompt_tag} the setup?" 0 0; then
        sudo snapper -v create --description "${snapshot_tag}-Install script snapshot"
    fi
}

packages=$(
    whiptail --title "OpenSUSE app installer" --separate-output --checklist "Choose which apps to install" 0 0 0 \
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
    "libreoffice" "Libreoffice" OFF \
    "transmission-gtk" "Transmission bittorrent client" OFF \
    "qbittorrent" "Qbittorrent bittorrent client" OFF \
    "gimp" "GIMP" OFF \
    "kdenlive" "Kdenlive" OFF \
    "keepassxc" "KeePassXC" OFF \
    "vscode" "Visual Studio Code" OFF \
    "vscodium" "VSCodium" OFF \
    "nodejs" "Nodejs" OFF \
    "dotnet" ".NET sdk" OFF \
    "rustup" "Rust" OFF \
    "golang" "Golang" OFF \
    "java" "Java openjdk" OFF \
    "xampp" "XAMPP" OFF \
    "docker" "Docker engine" OFF \
    "podman" "Podman" OFF \
    "distrobox" "Distrobox" OFF \
    "flatpak" "Flatpak" ON \
    "qemu" "QEMU/KVM" OFF \
    "OpenRGB" "OpenRGB" OFF \
    3>&1 1>&2 2>&3
)

cli_packages=$(
    whiptail --title "CLI install" --separate-output --checklist "Select cli applications to install" 0 0 0 \
    "neofetch" "neofetch" ON \
    "htop" "htop" ON \
    "btop" "btop++" ON \
    "gh" "github cli" OFF \
    3>&1 1>&2 2>&3
)

packages+=" $cli_packages"

packages+=" opi kwrite neovim eza bat fetchmsttfonts systemd-zram-service"

shells=$(choose_shells)

packages+=" $shells"

# Remove new lines
packages=$(echo "$packages"| tr "\n" " ")

# Add defaults
opi=(codecs)
patterns=(devel_basis)
services=(zramswap.service)
setups=(hacknerd)
usergroups=()
packages_to_remove="kmail kontact kmines akregator kaddressbook korganizer kompare konversation kleopatra kmahjongg kpat kreversi ksudoku xscreensaver"
patterns_to_remove="kde_games games kde_pim"

nvim_config=$(choose_nvim_config)
setups+=("$nvim_config")

# Add packages to the correct categories
for package in $packages; do
    case $package in
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
            packages+=" wine-mono winetricks"
            ;;

        qemu )
            patterns+=(kvm_tools)
            patterns+=(kvm_server)

            packages+=" libvirt bridge-utils"

            services+=(kvm_stat.service)
            services+=(libvirtd.service)

            usergroups+=(libvirt)
            ;;

        steam )
            packages+=" steam-devices"
            ;;

        heroic )
            opi+=(heroic-games-launcher)

            packages=$(remove_package "$packages" "$package")
            ;;

        itch )
            setups+=("$package")

            packages=$(remove_package "$packages" "$package")
            ;;

        vscode )
            setups+=(vscode)

            opi+=(vscode)

            packages=$(remove_package "$packages" "$package")
            ;;

        vscodium )
            opi+=(vscodium)
            setups+=(vscodium)

            packages=$(remove_package "$packages" "$package")
            ;;

        dotnet )
            opi+=(dotnet)

            packages=$(remove_package "$packages" "$package")
            ;;

        rustup )
            setups+=(rust)
            ;;

        nodejs )
            packages=$(remove_package "$packages" "$package")

            packages+=" nodejs-default"

            setups+=(npm)
            ;;

        golang )
            packages=$(remove_package "$packages" "$package")

            packages+=" go go-doc"
            ;;

        java )
            packages=$(remove_package "$packages" "$package")

            packages+=" java-22-openjdk-devel"
            ;;

        xampp )
            packages=$(remove_package "$packages" "$package")

            setups+=(xampp)
            ;;

        docker )
            packages+=" docker-compose docker-compose-switch"
            services+=(docker.service)
            usergroups+=(docker)
            ;;

        flatpak )
            setups+=(flatpak)
            usergroups+=(wheel)
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

create_snapshot 0

# Refresh repositories
sudo zypper refresh

# Update system
sudo zypper -vv dist-upgrade -y

# Check internet after update
if wget -q --spider http://google.com; then
    echo -e "${GREEN}Online${NC}"
else
    echo -e "${RED}Offline"
    echo -e "Please restart to progress the post install script!${NC}"
    exit 0
fi

# Remove unncessary packages
# shellcheck disable=SC2086
sudo zypper remove --details -y --clean-deps $packages_to_remove
# shellcheck disable=SC2086
sudo zypper remove --details -y --clean-deps -t pattern $patterns_to_remove
# shellcheck disable=SC2086
sudo zypper -vv al -t pattern $patterns_to_remove

# Install packages
# Don't use quotes, zypper won't recognize the packages
# shellcheck disable=SC2086
sudo zypper install --details -y $packages

# Install patterns
sudo zypper install --details -yt pattern "${patterns[@]}"

# Install opi packages
opi -nm "${opi[@]}"

# Set new repos to refresh
repos=$(sudo zypper lr)
for repo in $repos; do
    case $repo in
        vscode|dotnet )
            sudo zypper mr --refresh "$repo"
            ;;

    esac
done

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
            rustup toolchain install stable
            ;;

        npm )
            setup_npm
            ;;

        xampp )
            setup_xampp
            ;;

        flatpak )
            setup_flatpak
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

create_snapshot 1