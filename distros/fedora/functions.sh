#!/bin/bash

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

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
            "bleachbit" "BleachBit" OFF \
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

#######################################
# Add packages to the correct categories
# Arguments:
#   packages: string containing the list of packages, separated by space, name of the variable
#   services: indexed array, name of the variable
#   setups: indexed array, name of the variable
#   usergroups: indexed array, name of the variable
#   groups: indexed array, name of the variable
# Outputs:
#   None
#######################################
function handle_packages() {
    # Return variables
    local -n packages_to_handle=$1
    local -n services_to_handle=$2
    local -n setups_to_handle=$3
    local -n usergroups_to_handle=$4
    local -n groups_to_handle=$5

    for package in $packages_to_handle; do
        case $package in
        bash)
            setups_to_handle+=(bash)
            ;;

        fish)
            setups_to_handle+=(fish)
            ;;

        zsh)
            setups_to_handle+=(zsh)
            ;;

        starship-install)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(starship-install)
            ;;

        starship)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(starship)
            ;;

        fzf)
            setups_to_handle+=(fzf)
            ;;

        btop)
            packages_to_handle+=" rocm-smi"
            ;;

        vlc)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            groups_to_handle+=(vlc)
            ;;

        gaming-overlay)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            packages_to_handle+=" goverlay mangohud gamemode"
            ;;

        wine)
            packages_to_handle+=" wine-mono winetricks"
            ;;

        vivaldi)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            packages_to_handle+=" dnf-utils"
            setups_to_handle+=(vivaldi)
            ;;

        brave)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(brave)
            ;;

        librewolf)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(librewolf)
            ;;

        zen-browser)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(zen-browser)
            ;;

        qemu)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            groups_to_handle+=(virtualization)
            packages_to_handle+=" libvirt guestfs-tools libayatana-appindicator-gtk3"
            usergroups_to_handle+=(libvirt)
            setups_to_handle+=(qemu)
            ;;

        cockpit)
            packages_to_handle+=" cockpit-machines"
            services_to_handle+=(cockpit.socket)
            ;;

        VirtualBox)
            setups_to_handle+=(virtualbox)
            usergroups_to_handle+=(vboxusers)
            ;;

        heroic)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(heroic)
            ;;

        itch)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=("$package")
            ;;

        vscode)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(vscode)
            ;;

        vscodium)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(vscodium)
            ;;

        rustup)
            setups_to_handle+=(rust)
            ;;

        nodejs)
            setups_to_handle+=(npm)
            ;;

        java)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            packages_to_handle+=" java-latest-openjdk"
            ;;

        dotnet)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            packages_to_handle+=" dotnet-sdk-8.0"
            ;;

        xampp)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(xampp)
            ;;

        docker)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(docker)
            services_to_handle+=(docker.service)
            usergroups_to_handle+=(docker)
            ;;

        docker-desktop)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(docker-desktop)
            packages_to_handle+=" gnome-terminal"
            ;;

        flatpak)
            setups_to_handle+=(flatpak)
            ;;

        esac
    done
}

#######################################
# Choose to keep or remove plasma discover
# Arguments:
#   packages_to_remove_list: indexed array, name of the variable
# Outputs:
#   whiptail screen
#######################################
function get_remove_discover() {
    local -n packages_to_remove_list=$1

    if [[ -x $(command -v plasma-discover) ]] && whiptail --title "Remove discover" --yesno "Would you like to remove discover?" --defaultno 0 0; then
        packages_to_remove_list+=" plasma-discover"
    fi
}

#######################################
# Max out parallel downloads and increase inotify watch count
# Globals:
#   GREEN
#   YELLOW
#   NC
# Arguments:
#   None
# Outputs:
#   Log about step being performed
#######################################
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
        echo -e "${YELLOW}inotify watch count was already modified!${NC}"
    else
        printf "\nfs.inotify.max_user_watches=10000000\nfs.inotify.max_user_instances=256\n" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
    fi
}

#######################################
# Enable rpm fusion free and nonfree repositories
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Log about step being performed
#######################################
function add_rpm_fusion_repos() {
    echo -e "${GREEN}Adding rpm fusion repositories...${NC}"

    # shellcheck disable=SC2046
    sudo rpm -Uvh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    # shellcheck disable=SC2046
    sudo rpm -Uvh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
}

#######################################
# Enable rpm fusion free and nonfree repositories
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Log about step being performed
#######################################
function add_terra_repos() {
    echo -e "${GREEN}Adding terra repositories...${NC}"

    # shellcheck disable=SC2016
    dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
}

#######################################
# Swaps free packages to rpm fusion ones
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
#######################################
function swap_free_to_rpm_fusion_packages() {
    # For Intel GPUs
    sudo dnf swap libva-intel-media-driver intel-media-driver --allowerasing -y
    sudo dnf install libva-intel-driver -y

    # For AMD GPUs
    sudo dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
    sudo dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
    sudo dnf swap mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 -y
    sudo dnf swap mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 -y

    sudo dnf swap ffmpeg-free ffmpeg --allowerasing -y
}

#######################################
# Installs microsoft core fonts
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Log about step being performed
#######################################
function install_ms_core_fonts() {
    echo -e "${GREEN}Installing microsoft core fonts...${NC}"
    sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
}

#######################################
# Handle steps for setups
# Globals:
#   GREEN
#   YELLOW
#   NC
# Arguments:
#   setups: indexed array, name of the variable
# Outputs:
#   Log about installing virtio-win drivers
#######################################
function handle_setups() {
    # shellcheck disable=SC2178
    local -n setups_to_handle=$1

    for app in "${setups_to_handle[@]}"; do
        case $app in
        vscode)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo dnf5 check-update --refresh
            sudo dnf5 install -y code

            setup_vscode code
            ;;

        vscodium)
            sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg

            printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h\n" | sudo tee -a /etc/yum.repos.d/vscodium.repo

            sudo dnf5 install codium -y

            setup_vscode codium
            ;;

        heroic)
            sudo dnf5 copr enable atim/heroic-games-launcher -y
            sudo dnf5 -y install heroic-games-launcher-bin
            ;;

        itch)
            setup_itch_app
            ;;

        vivaldi)
            sudo dnf5 config-manager addrepo --from-repofile=https://repo.vivaldi.com/archive/vivaldi-fedora.repo

            sudo dnf5 install -y vivaldi-stable

            sudo rm -fv /etc/yum.repos.d/vivaldi.repo
            ;;

        brave)
            sudo dnf5 config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

            sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

            sudo dnf5 install -y brave-browser
            ;;

        librewolf)
            curl -fsSL https://repo.librewolf.net/librewolf.repo | sudo pkexec tee /etc/yum.repos.d/librewolf.repo

            sudo dnf5 install -y librewolf
            ;;

        zen-browser)
            sudo dnf copr enable sneexy/zen-browser -y

            sudo dnf install zen-browser -y
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
            setup_rust

            rustup-init
            ;;

        npm)
            setup_npm
            ;;

        xampp)
            setup_xampp
            ;;

        docker)
            if grep -iq VERSION_ID=40 "$DISTRO_RELEASE"; then
                sudo dnf4 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            else
                sudo dnf5 config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo

            fi

            sudo dnf5 install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        docker-desktop)
            download_file docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64"
            sudo dnf5 -y install docker-desktop.rpm
            rm -v docker-desktop.rpm
            ;;

        virtualbox)
            setup_virtualbox_extension
            ;;

        qemu)
            echo -e "${GREEN}Installing virtio-win drivers for windows...${NC}"
            echo -e "${GREEN}Drivers can be found in ${YELLOW}/usr/share/virtio-win/${GREEN} after install is finished${NC}"

            sudo wget https://fedorapeople.org/groups/virt/virtio-win/virtio-win.repo \
                -O /etc/yum.repos.d/virtio-win.repo

            sudo dnf install virtio-win -y

            setup_qemu

            if ! sudo virsh pool-list | grep -iq virtio-win; then
                sudo virsh pool-define-as --name virtio-win --type dir --target /usr/share/virtio-win
                sudo virsh pool-autostart virtio-win
                sudo virsh pool-start virtio-win
            fi
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

        starship-install)
            sudo dnf copr enable atim/starship -y
            sudo dnf install starship -y
            ;;

        starship)
            setup_starship
            ;;

        fzf)
            setup_fzf
            ;;

        esac
    done
}

#######################################
# Performs various dnf actions after script
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
#######################################
function perform_post_script_actions() {
    echo -e "${GREEN}Performing post install actions...${NC}"

    sudo dnf5 check-update --refresh

    sudo dnf5 update @multimedia -y

    sudo dnf5 autoremove -y

    sudo dnf5 upgrade -y
}
