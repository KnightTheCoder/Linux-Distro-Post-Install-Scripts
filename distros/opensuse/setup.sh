#!/bin/bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

#######################################
# Creates a snapshot with snapper
# Arguments:
#   Snapshot type, 0 or 1
# Outputs:
#   Whiptail screen
#######################################
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

    if whiptail --yesno "Do you want to make a snapshot ${prompt_tag} the setup?" --defaultno 0 0; then
        sudo snapper -v create --description "${snapshot_tag}-Install script snapshot"
    fi
}

#######################################
# Entry point for opensuse's setup
# Arguments:
#   None
# Outputs:
#   Logs for steps performed
#   whiptail screen
#######################################
function main() {
    local packages
    packages=$(
        whiptail --title "OpenSUSE app installer" --separate-output --notags --checklist "Choose which apps to install" 0 0 0 \
            "lutris" "Lutris" OFF \
            "wine" "Wine" OFF \
            "gaming-overlay" "Gaming overlay" OFF \
            "steam" "Steam" OFF \
            "steam-devices" "Steam devices (for the steam flatpak)" OFF \
            "itch" "Itch desktop app" OFF \
            "MozillaFirefox" "Firefox web browser" ON \
            "librewolf" "Librewolf web browser" OFF \
            "chromium" "Chromium web browser" OFF \
            "vivaldi" "Vivaldi web browser" OFF \
            "brave" "Brave web browser" OFF \
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
            "calibre" "Calibre E-book manager" OFF \
            "keepassxc" "KeePassXC" OFF \
            "vscode" "Visual Studio Code" OFF \
            "vscodium" "VSCodium" OFF \
            "nodejs" "Nodejs" OFF \
            "dotnet" ".NET SDK" OFF \
            "rustup" "Rust" OFF \
            "golang" "Golang" OFF \
            "java" "Java OpenJDK" OFF \
            "xampp" "XAMPP" OFF \
            "docker" "Docker engine" OFF \
            "podman" "Podman" OFF \
            "distrobox" "Distrobox" OFF \
            "flatpak" "Flatpak" ON \
            "qemu" "QEMU/KVM" OFF \
            "virtualbox" "Oracle Virtualbox" OFF \
            "OpenRGB" "OpenRGB" OFF \
            3>&1 1>&2 2>&3
    )

    local cli_packages
    cli_packages=$(
        whiptail --title "CLI install" --separate-output --notags --checklist "Select cli applications to install" 0 0 0 \
            "fastfetch" "fastfetch" ON \
            "btop" "btop++" ON \
            "gh" "github cli" OFF \
            3>&1 1>&2 2>&3
    )

    packages+=" $cli_packages"

    packages+=" opi neovim eza bat curl wget fetchmsttfonts systemd-zram-service 7zip unrar"

    local shells
    shells=$(choose_shells)

    packages+=" $shells"

    # Remove new lines
    packages=$(echo "$packages" | tr "\n" " ")

    # Add defaults
    local opi=(codecs)
    local patterns=(devel_basis)
    local services=(zramswap.service)
    local setups=(hacknerd)
    local usergroups=()
    local packages_to_remove="kmail kontact kmines akregator kaddressbook korganizer kompare konversation kleopatra kmahjongg kpat kreversi ksudoku xscreensaver"
    local patterns_to_remove="kde_games games kde_pim"

    local nvim_config
    nvim_config=$(choose_nvim_config)
    setups+=("$nvim_config")

    # Install NVIDIA drivers
    local driver
    driver=$(
        whiptail --notags --title "Drivers" --menu "Choose a driver" 0 0 0 \
            "" "None/Don't install" \
            "nvidia" "NVIDIA driver" \
            3>&1 1>&2 2>&3
    )

    if [[ "$driver" == "nvidia" ]]; then
        setups+=(nvidia)
    fi

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

            packages+=" goverlay mangohud mangohud-32bit gamemode"
            ;;

        wine)
            packages+=" wine-mono winetricks"
            ;;

        vivaldi)
            packages=$(remove_package "$packages" "$package")

            opi+=(vivaldi)
            ;;

        brave)
            packages=$(remove_package "$packages" "$package")

            opi+=(brave)
            ;;

        librewolf)
            packages=$(remove_package "$packages" "$package")

            setups+=(librewolf)
            ;;

        qemu)
            patterns+=(kvm_tools)
            patterns+=(kvm_server)

            packages+=" libvirt bridge-utils"

            services+=(kvm_stat.service)
            services+=(libvirtd.service)

            usergroups+=(libvirt)
            ;;

        virtualbox)
            setups+=(virtualbox)

            usergroups+=(vboxusers)
            ;;

        itch)
            packages=$(remove_package "$packages" "$package")

            setups+=("$package")
            ;;

        vscode)
            packages=$(remove_package "$packages" "$package")

            setups+=(vscode)

            opi+=(vscode)
            ;;

        vscodium)
            packages=$(remove_package "$packages" "$package")

            opi+=(vscodium)
            setups+=(vscodium)
            ;;

        dotnet)
            packages=$(remove_package "$packages" "$package")

            opi+=(dotnet)
            ;;

        rustup)
            setups+=(rust)
            ;;

        nodejs)
            packages=$(remove_package "$packages" "$package")

            packages+=" nodejs-default"

            setups+=(npm)
            ;;

        golang)
            packages=$(remove_package "$packages" "$package")

            packages+=" go go-doc"
            ;;

        java)
            packages=$(remove_package "$packages" "$package")

            packages+=" java-devel"
            ;;

        xampp)
            packages=$(remove_package "$packages" "$package")

            setups+=(xampp)
            ;;

        docker)
            packages+=" docker-compose docker-compose-switch"
            services+=(docker.service)
            usergroups+=(docker)
            ;;

        flatpak)
            setups+=(flatpak)
            usergroups+=(wheel)
            ;;

        esac
    done

    # Remove extra whitespace
    packages=$(echo "$packages" | xargs)

    # Ask if you want to remove discover
    if whiptail --title "Remove discover" --yesno "Would you like to remove discover?" --defaultno 0 0; then
        packages_to_remove+=" discover"
    fi

    create_snapshot 0

    # Refresh repositories
    sudo zypper refresh

    # Update system
    sudo zypper -vv dist-upgrade -y

    echo -e "${GREEN}Checking connection...${NC}"

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
    sudo zypper -vv addlock -t pattern $patterns_to_remove

    # Install packages
    # Don't use quotes, zypper won't recognize the packages
    # shellcheck disable=SC2086
    sudo zypper install --details -y $packages

    # Install patterns
    sudo zypper install --details -yt pattern "${patterns[@]}"

    # Install opi packages
    opi -nm "${opi[@]}"

    echo -e "${GREEN}Refreshing new repos...${NC}"

    # Set new repos to refresh
    repos=$(sudo zypper lr)
    for repo in $repos; do
        case $repo in
        vscode | dotnet)
            sudo zypper mr --refresh "$repo"
            ;;

        esac
    done

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

        librewolf)
            sudo rpm --import https://rpm.librewolf.net/pubkey.gpg

            sudo zypper ar -ef https://rpm.librewolf.net librewolf

            sudo zypper ref

            sudo zypper install --details -y librewolf
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
            rustup toolchain install stable
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

        nvidia)
            sudo zypper install openSUSE-repos-Tumbleweed-NVIDIA -y
            sudo zypper install-new-recommends --repo repo-non-free -y
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

    create_snapshot 1
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    main
fi
