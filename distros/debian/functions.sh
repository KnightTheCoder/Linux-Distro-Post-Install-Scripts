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
        whiptail --title "Debian/Ubuntu app installer" --separate-output --notags --checklist "Choose which apps to install" 0 0 0 \
            "lutris" "Lutris" OFF \
            "wine" "Wine" OFF \
            "gaming-overlay" "Gaming overlay (goverlay, mangohud, gamemode)" OFF \
            "steam" "Steam" OFF \
            "steam-devices" "Steam devices (for the steam flatpak)" OFF \
            "itch" "Itch desktop app" OFF \
            "heroic" "Heroic Games Launcher" OFF \
            "firefox" "Firefox web browser" ON \
            "librewolf" "Librewolf web browser" OFF \
            "chromium" "Chromium web browser" OFF \
            "vivaldi" "Vivaldi web browser" OFF \
            "brave" "Brave web browser" OFF \
            "haruna" "Haruna media player" ON \
            "celluloid" "Celluloid media player" ON \
            "vlc" "VLC media player" ON \
            "strawberry" "Strawberry music player" OFF \
            "audacious" "Audacious music player" ON \
            "libreoffice" "Libreoffice" OFF \
            "transmission" "Transmission bittorrent client" OFF \
            "qbittorrent" "Qbittorrent bittorrent client" OFF \
            "gimp" "GIMP" OFF \
            "kdenlive" "Kdenlive" OFF \
            "calibre" "Calibre E-book manager" OFF \
            "keepass2" "KeePass" OFF \
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
            "virtualbox" "Oracle Virtualbox" OFF \
            "mullvad-vpn" "MullvadVPN" OFF \
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
            "neofetch" "neofetch" ON \
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
    # Install NVIDIA drivers only on debian
    if grep -iq ID=debian "$DISTRO_RELEASE" || grep -iq LMDE "$DISTRO_RELEASE" || grep -iq ID=pika "$DISTRO_RELEASE"; then
        local driver
        local packages
        local -n nvidia_setups=$1

        driver=$(
            whiptail --notags --title "Drivers" --menu "Choose an NVIDIA driver" 0 0 0 \
                "" "None/Don't install" \
                "nvidia" "GeForce 700 series and newer GPUs" \
                3>&1 1>&2 2>&3
        )

        if [[ "$driver" == "nvidia" ]]; then
            packages="nvidia-driver firmware-misc-nonfree"
            nvidia_setups+=(nvidia)
        fi
    fi

    echo "$packages"
}

#######################################
# Add packages to the correct categories
# Arguments:
#   packages: string containing the list of packages, separated by space, name of the variable
#   services: indexed array, name of the variable
#   setups: indexed array, name of the variable
#   usergroups: indexed array, name of the variable
#   snaps: indexed array, name of the variable
# Outputs:
#   None
#######################################
function handle_packages() {
    # Return variables
    local -n packages_to_handle=$1
    local -n services_to_handle=$2
    local -n setups_to_handle=$3
    local -n usergroups_to_handle=$4
    local -n snaps_to_handle=$5

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

        gaming-overlay)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            packages_to_handle+=" goverlay mangohud gamemode"
            ;;

        wine)
            if grep -iq ID=pika "$DISTRO_RELEASE"; then
                packages_to_handle+=" winetricks"
            else
                packages_to_handle+=" wine32 winetricks"
            fi

            ;;

        firefox)
            if grep -iq ID=debian "$DISTRO_RELEASE"; then
                packages_to_handle=$(remove_package "$packages_to_handle" "$package")

                packages_to_handle+=" firefox-esr"

            elif [[ -x "$(command -v snap)" ]]; then
                packages_to_handle=$(remove_package "$packages_to_handle" "$package")

                snaps_to_handle+=(firefox)
            fi

            ;;

        chromium)
            if [[ -x "$(command -v snap)" ]]; then
                packages_to_handle=$(remove_package "$packages_to_handle" "$package")
                snaps_to_handle+=(chromium)
            fi

            ;;

        vivaldi)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

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

        qemu)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            packages_to_handle+=" libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-manager"

            # shellcheck disable=SC2154
            if grep -iq ID=debian "$DISTRO_RELEASE" || grep -iq LMDE "$DISTRO_RELEASE" || grep -iq ID=pika "$DISTRO_RELEASE"; then
                packages_to_handle+=" qemu-system-x86"
            else
                packages_to_handle+=" qemu-kvm"
            fi

            services_to_handle+=(libvirtd.service)
            usergroups_to_handle+=(libvirt)
            ;;

        cockpit)
            packages_to_handle+=" cockpit-machines"
            services_to_handle+=(cockpit.socket)
            ;;

        virtualbox)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            packages_to_handle+=" dkms build-essential linux-headers-$(uname -r) apt-transport-https gnupg2"
            setups_to_handle+=(virtualbox)
            usergroups_to_handle+=(vboxusers)
            ;;

        haruna)
            # Skip haruna on PikaOS because it's broken
            if grep -iq ID=pika "$DISTRO_RELEASE"; then
                packages_to_handle=$(remove_package "$packages_to_handle" "$package")
                whiptail --title "Package removed" --msgbox "Haruna has been skipped because it's broken on pikaos" 0 0
            fi

            ;;

        steam)
            if ! grep -iq ID=pika "$DISTRO_RELEASE"; then
                packages_to_handle=$(remove_package "$packages_to_handle" "$package")

                packages_to_handle+=" steam-installer"
            fi

            ;;

        lutris)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(lutris)
            packages_to_handle+=" wine"
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
            packages_to_handle+=" apt-transport-https"
            ;;

        vscodium)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(vscodium)
            ;;

        dotnet)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            if grep -iq "ID=debian" "$DISTRO_RELEASE" || grep -iq LMDE "$DISTRO_RELEASE"; then
                setups_to_handle+=(dotnet)
            else
                packages_to_handle+=" dotnet-sdk-8.0"
            fi

            ;;

        rustup)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(rust)
            ;;

        nodejs)
            setups_to_handle+=(npm)
            packages_to_handle+=" npm"
            ;;

        golang)
            if grep -iq ubuntu "$DISTRO_RELEASE"; then
                packages_to_handle=$(remove_package "$packages_to_handle" "$package")

                packages_to_handle+=" golang-go"
            fi

            ;;

        java)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            packages_to_handle+=" default-jdk"
            ;;

        xampp)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(xampp)
            ;;

        docker)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            packages_to_handle+=" ca-certificates"
            setups_to_handle+=(docker)
            services_to_handle+=(docker.service)
            usergroups_to_handle+=(docker)
            ;;

        docker-desktop)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(docker-desktop)
            packages_to_handle+=" gnome-terminal"
            ;;

        distrobox)
            packages_to_handle=$(remove_package "$packages_to_handle" "$package")

            setups_to_handle+=(distrobox)
            ;;

        flatpak)
            setups_to_handle+=(flatpak)
            ;;

        mullvad-vpn)
            packages=$(remove_package "$packages" "$package")

            setups+=(mullvad-vpn)
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
# Performs setups for kde neon and debian
# configures debian
# Arguments:
#   None
# Outputs:
#   Logs for steps being performaned
#######################################
function perform_distro_setups() {
    if grep -iq ID=debian "$DISTRO_RELEASE" || grep -iq LMDE "$DISTRO_RELEASE"; then
        echo -e "${GREEN}Adding extra repositories...${NC}"
        # Add extra repositories to debian
        sudo apt install software-properties-common -y
        sudo apt-add-repository contrib non-free non-free-firmware -y
        sudo apt install libavcodec-extra -y
    fi
}

#######################################
# Adds 32 bit package support
# Arguments:
#   None
#######################################
function add_32bit_support() {
    # shellcheck disable=SC2046
    if [ -z $(dpkg --print-foreign-architectures) ]; then
        sudo dpkg --add-architecture i386
    fi
}

#######################################
# Install snap packages
# Arguments:
#   snaps: indexed array
#######################################
function install_snaps() {
    local snaps=("$1")

    if [[ -x "$(command -v snap)" ]]; then
        echo -e "${GREEN}Installing snaps...${NC}"

        for snap in "${snaps[@]}"; do
            sudo snap install "$snap"
        done
    fi
}

#######################################
# Handle steps for setups
# Arguments:
#   setups: indexed array, name of the variable
#######################################
function handle_setups() {
    # shellcheck disable=SC2178
    local -n setups_to_handle=$1

    for app in "${setups_to_handle[@]}"; do
        case $app in

        lutris)
            download_file lutris.deb "https://github.com/lutris/lutris/releases/download/v0.5.18/lutris_0.5.18_all.deb"
            sudo apt install -y ./lutris.deb
            rm -v ./lutris.deb
            ;;

        heroic)
            download_file heroic.deb "https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.16.0/Heroic-2.16.0-linux-amd64.deb"
            sudo dpkg -i heroic.deb
            rm -v heroic.deb
            ;;

        itch)
            setup_itch_app
            ;;

        vscode)
            if [ ! -e /etc/apt/keyrings/packages.microsoft.gpg ]; then
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
                sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
                rm -fv packages.microsoft.gpg
            fi

            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

            sudo apt update
            sudo apt install -y code

            setup_vscode code
            ;;

        vscodium)
            if [ ! -e /usr/share/keyrings/vscodium-archive-keyring.gpg ]; then
                wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg |
                    gpg --dearmor |
                    sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
            fi

            echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' |
                sudo tee /etc/apt/sources.list.d/vscodium.list

            sudo apt update && sudo apt install codium -y

            setup_vscode codium
            ;;

        vivaldi)
            download_file vivaldi.deb "https://downloads.vivaldi.com/stable/vivaldi-stable_7.1.3570.39-1_amd64.deb"
            sudo apt update && sudo apt install -y ./vivaldi.deb

            rm -fv ./vivaldi.deb
            ;;

        brave)
            sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

            sudo apt update && sudo apt install brave-browser -y
            ;;

        librewolf)
            sudo apt update && sudo apt install extrepo -y

            sudo extrepo enable librewolf

            sudo apt update && sudo apt install librewolf -y
            ;;

        hacknerd)
            setup_hacknerd_fonts
            ;;

        rust)
            setup_rust default
            ;;

        npm)
            setup_npm
            ;;

        dotnet)
            wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            rm -v packages-microsoft-prod.deb

            sudo apt update && sudo apt install -y dotnet-sdk-8.0
            ;;

        xampp)
            setup_xampp
            ;;

        docker)
            sudo apt-get update
            sudo install -m 0755 -d /etc/apt/keyrings

            codename=""
            system_base=""

            if grep -iq ID=debian "$DISTRO_RELEASE" || grep -iq LMDE "$DISTRO_RELEASE" || grep -iq ID=pika "$DISTRO_RELEASE"; then
                # Debian
                system_base="debian"
                if grep -iq ID=debian "$DISTRO_RELEASE"; then
                    # shellcheck disable=SC1091
                    codename=$(. "$DISTRO_RELEASE" && echo "$VERSION_CODENAME")
                elif grep -iq LMDE "$DISTRO_RELEASE"; then
                    # shellcheck disable=SC1091
                    codename=$(. "$DISTRO_RELEASE" && echo "$DEBIAN_CODENAME")
                elif grep -iq ID=pika "$DISTRO_RELEASE"; then
                    codename="bookworm"
                fi
            else
                # Ubuntu based
                system_base="ubuntu"
                if grep -iq ID=linuxmint "$DISTRO_RELEASE"; then
                    # shellcheck disable=SC1091
                    codename=$(. "$DISTRO_RELEASE" && echo "$UBUNTU_CODENAME")
                else
                    # shellcheck disable=SC1091
                    codename=$(. "$DISTRO_RELEASE" && echo "$VERSION_CODENAME")
                fi
            fi

            # Add Docker's official GPG key:
            if [ ! -e /etc/apt/keyrings/docker.asc ]; then
                sudo curl -fsSL https://download.docker.com/linux/"$system_base"/gpg -o /etc/apt/keyrings/docker.asc
            fi

            sudo chmod a+r /etc/apt/keyrings/docker.asc

            # Add the repository to Apt sources:
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${system_base} \
                    $codename stable" |
                sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        docker-desktop)
            download_file docker-desktop.deb "https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64"
            sudo apt-get update
            sudo apt-get install -y ./docker-desktop.deb
            rm -v docker-desktop.deb
            ;;

        distrobox)
            curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh
            ;;

        virtualbox)
            codename=""

            if grep -iq ID=debian "$DISTRO_RELEASE"; then
                # shellcheck disable=SC1091
                codename=$(. "$DISTRO_RELEASE" && echo "$VERSION_CODENAME")
            elif grep -iq LMDE "$DISTRO_RELEASE"; then
                # shellcheck disable=SC1091
                codename=$(. "$DISTRO_RELEASE" && echo "$DEBIAN_CODENAME")
            elif grep -iq ID=pika "$DISTRO_RELEASE"; then
                codename="bookworm"
            elif grep -iq ID=linuxmint "$DISTRO_RELEASE"; then
                # shellcheck disable=SC1091
                codename=$(. "$DISTRO_RELEASE" && echo "$UBUNTU_CODENAME")
            elif grep -iq ubuntu "$DISTRO_RELEASE"; then
                # shellcheck disable=SC1091
                codename=$(. "$DISTRO_RELEASE" && echo "$VERSION_CODENAME")
            fi

            if [ ! -e /etc/apt/trusted.gpg.d/vbox.gpg ]; then
                curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/vbox.gpg
            fi

            echo deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/vbox.gpg] http://download.virtualbox.org/virtualbox/debian "$codename" contrib | sudo tee /etc/apt/sources.list.d/virtualbox.list

            sudo apt update

            vb_name="virtualbox"

            if grep -iq ID=debian "$DISTRO_RELEASE" || grep -iq LMDE "$DISTRO_RELEASE" || grep -iq ID=linuxmint "$DISTRO_RELEASE"; then
                vb_name="virtualbox-7.1"
            fi

            sudo apt install ${vb_name} -y

            setup_virtualbox_extension
            ;;

        eza)
            if [ ! -x "$(command -v eza)" ]; then
                sudo mkdir -p /etc/apt/keyrings

                wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg

                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
                sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

                sudo apt update
                sudo apt install -y eza
            else
                echo -e "${YELLOW}eza is already installed${NC}"
            fi

            ;;

        flatpak)
            setup_flatpak
            ;;

        nvidia)
            sudo mkdir /etc/dracut.conf.d
            sudo touch /etc/dracut.conf.d/10-nvidia.conf
            echo install_items+=" /etc/modprobe.d/nvidia-blacklists-nouveau.conf /etc/modprobe.d/nvidia.conf /etc/modprobe.d/nvidia-options.conf " | sudo tee /etc/dracut.conf.d/10-nvidia.conf

            if [[ $(cat /sys/module/nvidia_drm/parameters/modeset) == "N" ]]; then
                sudo mkdir /etc/modprobe.d/
                sudo touch /etc/modprobe.d/nvidia-options.conf
                echo "options nvidia-drm modeset=1" | sudo tee -a /etc/modprobe.d/nvidia-options.conf
            fi

            ;;

        mullvad-vpn)
            sudo curl -fsSLo /usr/share/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc

            echo "deb [signed-by=/usr/share/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/stable stable main" | sudo tee /etc/apt/sources.list.d/mullvad.list

            sudo apt update
            sudo apt install mullvad-vpn -y
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
            setup_starship_install
            ;;

        starship)
            setup_starship
            ;;

        esac
    done
}

#######################################
# Performs various apt actions after script
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
#######################################
function perform_post_script_actions() {
    echo -e "${GREEN}Performing post install actions...${NC}"

    sudo apt update

    sudo apt autoremove -y

    sudo apt upgrade -y

    sudo snap refresh
}
