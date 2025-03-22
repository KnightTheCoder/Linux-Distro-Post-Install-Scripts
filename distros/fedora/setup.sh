#!/bin/bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

#######################################
# Entry point for fedora's setup
# Globals:
#   GREEN
#   YELLOW
#   NC
# Arguments:
#   None
# Outputs:
#   Logs for steps performed
#   whiptail screen
#######################################
function main() {
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

    local cli_packages
    cli_packages=$(
        whiptail --title "CLI install" --separate-output --notags --checklist "Select cli applications to install" 0 0 0 \
            "fastfetch" "fastfetch" ON \
            "btop" "btop++" ON \
            "fzf" "fzf" ON \
            "gh" "github cli" OFF \
            3>&1 1>&2 2>&3
    )

    packages+=" vim neovim eza bat curl wget cabextract xorg-x11-font-utils fontconfig p7zip p7zip-plugins unrar git dnf-plugins-core ffmpeg-libs libva libva-utils openh264 gstreamer1-plugin-openh264 mozilla-openh264 \*appstream-data"

    local shells
    shells=$(choose_shells)

    if [[ $shells == *"starship"* ]]; then
        shells="starship-install $shells"
    fi

    packages="$packages $shells $cli_packages"

    # Remove new lines
    packages=$(echo "$packages" | tr "\n" " ")

    # Add defaults
    local services=()
    local setups=(hacknerd)
    local usergroups=()
    local groups=(c-development multimedia sound-and-video)
    local packages_to_remove="anaconda\* akregator dragon elisa-player kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat kolourpaint qt5-qdbusviewer pim-sieve-editor neochat rhythmbox"

    # Install NVIDIA drivers
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

    packages+=" $drivers"

    local nvim_config
    nvim_config=$(choose_nvim_config)
    setups+=("$nvim_config")

    # Add packages to the correct categories
    for package in $packages; do
        case $package in
        bash)
            setups+=(bash)
            ;;

        fish)
            setups+=(fish)
            ;;

        zsh)
            setups+=(zsh)
            ;;

        starship-install)
            packages=$(remove_package "$packages" "$package")

            setups+=(starship-install)
            ;;

        starship)
            packages=$(remove_package "$packages" "$package")

            setups+=(starship)
            ;;

        fzf)
            setups+=(fzf)
            ;;

        btop)
            packages+=" rocm-smi"
            ;;

        vlc)
            packages=$(remove_package "$packages" "$package")

            groups+=(vlc)
            ;;

        gaming-overlay)
            packages=$(remove_package "$packages" "$package")

            packages+=" goverlay mangohud gamemode"
            ;;

        wine)
            packages+=" wine-mono winetricks"
            ;;

        vivaldi)
            packages=$(remove_package "$packages" "$package")

            packages+=" dnf-utils"
            setups+=(vivaldi)
            ;;

        brave)
            packages=$(remove_package "$packages" "$package")

            setups+=(brave)
            ;;

        librewolf)
            packages=$(remove_package "$packages" "$package")

            setups+=(librewolf)
            ;;

        zen-browser)
            packages=$(remove_package "$packages" "$package")

            setups+=(zen-browser)
            ;;

        qemu)
            groups+=(virtualization)
            packages+=" libvirt guestfs-tools libayatana-appindicator-gtk3"
            usergroups+=(libvirt)
            setups+=(qemu)
            ;;

        cockpit)
            packages+=" cockpit-machines"
            services+=(cockpit.socket)
            ;;

        VirtualBox)
            setups+=(virtualbox)
            usergroups+=(vboxusers)
            ;;

        heroic)
            packages=$(remove_package "$packages" "$package")

            setups+=(heroic)
            ;;

        itch)
            packages=$(remove_package "$packages" "$package")

            setups+=("$package")
            ;;

        vscode)
            packages=$(remove_package "$packages" "$package")

            setups+=(vscode)
            ;;

        vscodium)
            packages=$(remove_package "$packages" "$package")

            setups+=(vscodium)
            ;;

        rustup)
            setups+=(rust)
            ;;

        nodejs)
            setups+=(npm)
            ;;

        java)
            packages=$(remove_package "$packages" "$package")

            packages+=" java-latest-openjdk"
            ;;

        dotnet)
            packages=$(remove_package "$packages" "$package")

            packages+=" dotnet-sdk-8.0"
            ;;

        xampp)
            packages=$(remove_package "$packages" "$package")

            setups+=(xampp)
            ;;

        docker)
            packages=$(remove_package "$packages" "$package")

            setups+=(docker)
            services+=(docker.service)
            usergroups+=(docker)
            ;;

        docker-desktop)
            packages=$(remove_package "$packages" "$package")

            setups+=(docker-desktop)
            packages+=" gnome-terminal"
            ;;

        flatpak)
            setups+=(flatpak)
            ;;

        esac
    done

    # Remove extra whitespace
    packages=$(echo "$packages" | xargs)

    # Ask if you want to remove discover
    if [[ -x $(command -v plasma-discover) ]] && whiptail --title "Remove discover" --yesno "Would you like to remove discover?" --defaultno 0 0; then
        packages_to_remove+=" plasma-discover"
    fi

    echo -e "${GREEN}Modifying dnf configuration...${NC}"
    # Modify dnf config file
    # Set parallel downloads and default to yes, if it hasn't been set yet
    if grep -iq "max_parallel_downloads=20" /etc/dnf/dnf.conf && grep -iq "defaultyes=True" /etc/dnf/dnf.conf; then
        echo -e "${YELLOW}Config was already modified!${NC}"
    else
        printf "max_parallel_downloads=20\ndefaultyes=True\n" | sudo tee -a /etc/dnf/dnf.conf
    fi

    echo -e "${GREEN}Increasing the inotify watch count...${NC}"
    if grep -iq fs.inotify.max_user_watches=10000000 /etc/sysctl.conf || grep -iq "fs.inotify.max_user_instances = 256" /etc/sysctl.conf; then
        echo -e "${YELLOW}inotify watch count already modified!${NC}"
    else
        printf "\nfs.inotify.max_user_watches=10000000\nfs.inotify.max_user_instances = 256\n" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
    fi

    echo -e "${GREEN}Adding rpm fusion repositories...${NC}"
    # Add rpm fusion repositories

    # shellcheck disable=SC2046
    sudo rpm -Uvh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    # shellcheck disable=SC2046
    sudo rpm -Uvh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    # Add the eza copr repo for fedora 42 and later
    if [[ $(rpm -E %fedora) -ge 42 ]]; then
        sudo dnf copr enable alternateved/eza -y
    fi

    # Install dnf5 if it's an older system
    sudo dnf install -y dnf5 dnf5-plugins

    # Update system
    sudo dnf5 upgrade -y --refresh

    # Remove unneccessary packages
    # shellcheck disable=SC2086
    sudo dnf5 remove -y $packages_to_remove

    # Install groups
    sudo dnf4 group install -y "${groups[@]}" --allowerasing

    # Swap mesa drivers to freeworld ones
    local mesa_drivers=(mesa-va-drivers mesa-vdpau-drivers)
    for mesa_driver in "${mesa_drivers[@]}"; do
        sudo dnf swap "$mesa_driver" "${mesa_driver}-freeworld" -y
    done

    sudo dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing -y

    # Install packages
    # shellcheck disable=SC2086
    sudo dnf5 install -y $packages

    # Install msfonts
    echo -e "${GREEN}Installing microsoft core fonts...${NC}"
    sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

    add_user_to_groups "${usergroups[@]}"

    # Run setups
    for app in "${setups[@]}"; do
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
            download_file docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/139021/docker-desktop-4.28.0-x86_64.rpm?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64"
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

    start_systemd_services "${services[@]}"

    # Update system after setup
    sudo dnf5 upgrade -y --refresh
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    main
fi
