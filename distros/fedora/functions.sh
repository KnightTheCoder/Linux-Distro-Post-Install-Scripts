#!/bin/bash

#######################################
# Choose from packages
# Arguments:
#   None
# Outputs:
#   Package names in a string, seperated by a new line
#######################################
function get_main_packages() {
    local packages
    packages=$(
        whiptail --title "Fedora app installer" --separate-output --checklist --notags "Choose which apps to install" 0 0 0 \
            "lutris" "Lutris" OFF \
            "wine" "Wine" OFF \
            "gaming-overlay" "Gaming overlay (goverlay, mangohud, gamemode)" OFF \
            "steam" "Steam" OFF \
            "steam-devices" "Steam devices (for the steam flatpak)" OFF \
            "itch" "Itch desktop app" OFF \
            "heroic" "Heroic Games Launcher" OFF \
            "firefox" "Firefox web browser" ON \
            "librewolf" "Librewolf web browser" OFF \
            "zen-browser" "Zen web browser" OFF \
            "chromium" "Chromium web browser" OFF \
            "vivaldi" "Vivaldi web browser" OFF \
            "brave" "Brave web browser" OFF \
            "haruna" "Haruna media player" ON \
            "celluloid" "Celluloid media player" ON \
            "vlc" "VLC media player" ON \
            "strawberry" "Strawberry music player" OFF \
            "audacious" "Audacious music player" ON \
            "transmission-qt" "Transmission bittorrent client" OFF \
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
            "docker-desktop" "Docker desktop" OFF \
            "podman" "Podman" OFF \
            "distrobox" "Distrobox" OFF \
            "flatpak" "Flatpak" ON \
            "qemu" "QEMU/KVM" OFF \
            "cockpit" "Cockpit (needs qemu)" OFF \
            "VirtualBox" "Oracle Virtualbox" OFF \
            "openrgb" "OpenRGB" OFF \
            3>&1 1>&2 2>&3
    )

    echo "$packages"
}

#######################################
# Choose from cli packages
# Arguments:
#   None
# Outputs:
#   Package names in a string, seperated by a new line
#######################################
function get_cli_packages() {
    local cli_packages
    cli_packages=$(
        whiptail --title "CLI install" --separate-output --notags --checklist "Select cli applications to install" 0 0 0 \
            "fastfetch" "fastfetch" ON \
            "btop" "btop++" ON \
            "fzf" "fzf" ON \
            "gh" "github cli" OFF \
            3>&1 1>&2 2>&3
    )

    echo "$cli_packages"
}

#######################################
# Choose from nvidia driver packages
# Arguments:
#   None
# Outputs:
#   Package names in a string, seperated by spaces
#######################################
function get_nvidia_drivers() {
    local drivers
    local driver

    driver=$(
        whiptail --notags --title "Drivers" --menu "Choose an NVIDIA driver" 0 0 0 \
            "" "None/Don't install" \
            "current" "Current GeForce/Quadro/Tesla" \
            "legacy1" "Legacy GeForce 600/700" \
            "legacy2" "Legacy GeForce 400/500" \
            "legacy3" "Legacy GeForce 8/9/200/300" \
            3>&1 1>&2 2>&3
    )

    case "$driver" in

    current)
        drivers="akmod-nvidia xorg-x11-drv-nvidia-cuda"
        ;;

    legacy1)
        drivers="xorg-x11-drv-nvidia-470xx akmod-nvidia-470xx xorg-x11-drv-nvidia-470xx-cuda"
        ;;

    legacy2)
        drivers="xorg-x11-drv-nvidia-390xx akmod-nvidia-390xx xorg-x11-drv-nvidia-390xx-cuda"
        ;;

    legacy3)
        drivers="xorg-x11-drv-nvidia-340xx akmod-nvidia-340xx xorg-x11-drv-nvidia-340xx-cuda"
        ;;

    *) ;;

    esac

    if [[ -n "$drivers" ]]; then
        drivers+=" libva-nvidia-driver"
    fi

    echo "$drivers"
}

function get_remove_discover() {
    if [[ -x $(command -v plasma-discover) ]] && whiptail --title "Remove discover" --yesno "Would you like to remove discover?" --defaultno 0 0; then
        packages_to_remove+=" plasma-discover"
    fi
}

function modify_configurations() {
    echo -e "${GREEN}Modifying dnf configuration...${NC}"

    # Set parallel downloads and default to yes, if it hasn't been set yet
    if grep -iq "max_parallel_downloads=20" /etc/dnf/dnf.conf && grep -iq "defaultyes=True" /etc/dnf/dnf.conf; then
        echo -e "${YELLOW}Config was already modified!${NC}"
    else
        printf "max_parallel_downloads=20\ndefaultyes=True\n" | sudo tee -a /etc/dnf/dnf.conf
    fi

    echo -e "${GREEN}Increasing the inotify watch count...${NC}"

    if grep -iq fs.inotify.max_user_watches=10000000 /etc/sysctl.conf || grep -iq fs.inotify.max_user_instances=256 /etc/sysctl.conf; then
        echo -e "${YELLOW}inotify watch count already modified!${NC}"
    else
        printf "\nfs.inotify.max_user_watches=10000000\nfs.inotify.max_user_instances=256\n" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
    fi
}

function add_rpm_fusion_repos() {
    echo -e "${GREEN}Adding rpm fusion repositories...${NC}"

    # shellcheck disable=SC2046
    sudo rpm -Uvh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    # shellcheck disable=SC2046
    sudo rpm -Uvh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

function post_script_dnf_actions() {
    sudo dnf check-update --refresh

    sudo dnf5 update @multimedia -y

    sudo dnf5 autoremove -y

    sudo dnf5 upgrade -y
}
