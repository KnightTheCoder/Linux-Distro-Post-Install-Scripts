#!/bin/bash

cd "$(dirname "$0")" || exit

# shellcheck source=./functions.sh
source "./functions.sh"

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
    packages=$(get_main_packages)

    local cli_packages
    cli_packages=$(get_cli_packages)

    packages+=" vim neovim eza bat curl wget cabextract xorg-x11-font-utils fontconfig p7zip p7zip-plugins unrar git dnf-plugins-core ffmpeg-libs libva libva-utils openh264 gstreamer1-plugin-openh264 mozilla-openh264 \*appstream-data"

    local shells
    shells=$(choose_shells)

    if [[ $shells == *"starship"* ]]; then
        shells="starship-install $shells"
    fi

    packages="$shells $cli_packages $packages"

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
    drivers=$(get_nvidia_drivers)

    packages+=" $drivers"

    local nvim_config
    nvim_config=$(choose_nvim_config)
    setups+=("$nvim_config")

    handle_packages packages services "setups usergroups groups

    # Add packages to the correct categories
    # for package in $packages; do
    #     case $package in
    #     bash)
    #         setups+=(bash)
    #         ;;

    #     fish)
    #         setups+=(fish)
    #         ;;

    #     zsh)
    #         setups+=(zsh)
    #         ;;

    #     starship-install)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(starship-install)
    #         ;;

    #     starship)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(starship)
    #         ;;

    #     fzf)
    #         setups+=(fzf)
    #         ;;

    #     btop)
    #         packages+=" rocm-smi"
    #         ;;

    #     vlc)
    #         packages=$(remove_package "$packages" "$package")

    #         groups+=(vlc)
    #         ;;

    #     gaming-overlay)
    #         packages=$(remove_package "$packages" "$package")

    #         packages+=" goverlay mangohud gamemode"
    #         ;;

    #     wine)
    #         packages+=" wine-mono winetricks"
    #         ;;

    #     vivaldi)
    #         packages=$(remove_package "$packages" "$package")

    #         packages+=" dnf-utils"
    #         setups+=(vivaldi)
    #         ;;

    #     brave)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(brave)
    #         ;;

    #     librewolf)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(librewolf)
    #         ;;

    #     zen-browser)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(zen-browser)
    #         ;;

    #     qemu)
    #         packages=$(remove_package "$packages" "$package")

    #         groups+=(virtualization)
    #         packages+=" libvirt guestfs-tools libayatana-appindicator-gtk3"
    #         usergroups+=(libvirt)
    #         setups+=(qemu)
    #         ;;

    #     cockpit)
    #         packages+=" cockpit-machines"
    #         services+=(cockpit.socket)
    #         ;;

    #     VirtualBox)
    #         setups+=(virtualbox)
    #         usergroups+=(vboxusers)
    #         ;;

    #     heroic)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(heroic)
    #         ;;

    #     itch)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=("$package")
    #         ;;

    #     vscode)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(vscode)
    #         ;;

    #     vscodium)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(vscodium)
    #         ;;

    #     rustup)
    #         setups+=(rust)
    #         ;;

    #     nodejs)
    #         setups+=(npm)
    #         ;;

    #     java)
    #         packages=$(remove_package "$packages" "$package")

    #         packages+=" java-latest-openjdk"
    #         ;;

    #     dotnet)
    #         packages=$(remove_package "$packages" "$package")

    #         packages+=" dotnet-sdk-8.0"
    #         ;;

    #     xampp)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(xampp)
    #         ;;

    #     docker)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(docker)
    #         services+=(docker.service)
    #         usergroups+=(docker)
    #         ;;

    #     docker-desktop)
    #         packages=$(remove_package "$packages" "$package")

    #         setups+=(docker-desktop)
    #         packages+=" gnome-terminal"
    #         ;;

    #     flatpak)
    #         setups+=(flatpak)
    #         ;;

    #     esac
    # done

    # Remove extra whitespace
    packages=$(echo "$packages" | xargs)

    get_remove_discover

    modify_configurations

    add_rpm_fusion_repos

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

    swap_free_to_rpm_fusion_packages

    # Install packages
    # shellcheck disable=SC2086
    sudo dnf5 install -y $packages

    install_ms_core_fonts

    add_user_to_groups "${usergroups[@]}"

    handle_setups "${setups[@]}"

    # Run setups
    # for app in "${setups[@]}"; do
    #     case $app in
    #     vscode)
    #         sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    #         sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
    #         sudo dnf5 check-update --refresh
    #         sudo dnf5 install -y code

    #         setup_vscode code
    #         ;;

    #     vscodium)
    #         sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg

    #         printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h\n" | sudo tee -a /etc/yum.repos.d/vscodium.repo

    #         sudo dnf5 install codium -y

    #         setup_vscode codium
    #         ;;

    #     heroic)
    #         sudo dnf5 copr enable atim/heroic-games-launcher -y
    #         sudo dnf5 -y install heroic-games-launcher-bin
    #         ;;

    #     itch)
    #         setup_itch_app
    #         ;;

    #     vivaldi)
    #         sudo dnf5 config-manager addrepo --from-repofile=https://repo.vivaldi.com/archive/vivaldi-fedora.repo

    #         sudo dnf5 install -y vivaldi-stable

    #         sudo rm -fv /etc/yum.repos.d/vivaldi.repo
    #         ;;

    #     brave)
    #         sudo dnf5 config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

    #         sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

    #         sudo dnf5 install -y brave-browser
    #         ;;

    #     librewolf)
    #         curl -fsSL https://repo.librewolf.net/librewolf.repo | sudo pkexec tee /etc/yum.repos.d/librewolf.repo

    #         sudo dnf5 install -y librewolf
    #         ;;

    #     zen-browser)
    #         sudo dnf copr enable sneexy/zen-browser -y

    #         sudo dnf install zen-browser -y
    #         ;;

    #     hacknerd)
    #         setup_hacknerd_fonts
    #         ;;

    #     nvchad)
    #         setup_nvchad
    #         ;;

    #     astronvim)
    #         setup_astronvim
    #         ;;

    #     rust)
    #         setup_rust

    #         rustup-init
    #         ;;

    #     npm)
    #         setup_npm
    #         ;;

    #     xampp)
    #         setup_xampp
    #         ;;

    #     docker)
    #         if grep -iq VERSION_ID=40 "$DISTRO_RELEASE"; then
    #             sudo dnf4 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    #         else
    #             sudo dnf5 config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo

    #         fi

    #         sudo dnf5 install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    #         ;;

    #     docker-desktop)
    #         download_file docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/139021/docker-desktop-4.28.0-x86_64.rpm?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64"
    #         sudo dnf5 -y install docker-desktop.rpm
    #         rm -v docker-desktop.rpm
    #         ;;

    #     virtualbox)
    #         setup_virtualbox_extension
    #         ;;

    #     qemu)
    #         echo -e "${GREEN}Installing virtio-win drivers for windows...${NC}"
    #         echo -e "${GREEN}Drivers can be found in ${YELLOW}/usr/share/virtio-win/${GREEN} after install is finished${NC}"

    #         sudo wget https://fedorapeople.org/groups/virt/virtio-win/virtio-win.repo \
    #             -O /etc/yum.repos.d/virtio-win.repo

    #         sudo dnf install virtio-win -y

    #         setup_qemu

    #         if ! sudo virsh pool-list | grep -iq virtio-win; then
    #             sudo virsh pool-define-as --name virtio-win --type dir --target /usr/share/virtio-win
    #             sudo virsh pool-autostart virtio-win
    #             sudo virsh pool-start virtio-win
    #         fi
    #         ;;

    #     flatpak)
    #         setup_flatpak
    #         ;;

    #     bash)
    #         setup_bash
    #         ;;

    #     fish)
    #         setup_fish
    #         ;;

    #     zsh)
    #         setup_zsh
    #         ;;

    #     starship-install)
    #         sudo dnf copr enable atim/starship -y
    #         sudo dnf install starship -y
    #         ;;

    #     starship)
    #         setup_starship
    #         ;;

    #     fzf)
    #         setup_fzf
    #         ;;

    #     esac
    # done

    start_systemd_services "${services[@]}"

    post_script_dnf_actions
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    main
fi
