#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

packages=$(
    whiptail --title "Fedora app installer" --separate-output --checklist "Choose which apps to install" 0 0 0 \
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
    "transmission" "Transmission bittorrent client" OFF \
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
    "docker-desktop" "Docker desktop" OFF \
    "podman" "Podman" OFF \
    "distrobox" "Distrobox" OFF \
    "flatpak" "Flatpak" ON \
    "qemu" "QEMU/KVM" OFF \
    "VirtualBox" "Oracle Virtualbox" OFF \
    "openrgb" "OpenRGB" OFF \
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

packages+=" neovim eza bat dnf5 dnf5-plugins curl cabextract xorg-x11-font-utils fontconfig p7zip p7zip-plugins unrar"

shells=$(choose_shells)

if [[ $shells == *"starship"* ]]; then
    shells="starship-install $shells"
fi

packages+=" $shells"

# Remove new lines
packages=$(echo "$packages"| tr "\n" " ")

# Add defaults
services=()
setups=(fish hacknerd)
usergroups=()
groups=("C Development Tools and Libraries" Multimedia)
packages_to_remove="akregator dragon elisa-player kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat kolourpaint qt5-qdbusviewer"

nvim_config=$(choose_nvim_config)
setups+=("$nvim_config")

# Add packages to the correct categories
for package in $packages; do
    case $package in
        bash )
            setups+=(bash)
            ;;

        fish )
            setups+=(fish)
            ;;

        zsh )
            setups+=(zsh)
            ;;

        starship-install )
            packages=$(remove_package "$packages" "$package")

            setups+=(starship-install)
            ;;

        starship )
            packages=$(remove_package "$packages" "$package")

            setups+=(starship)
            ;;

        btop )
            packages+=" rocm-smi"
            ;;

        gaming-overlay)
            packages=$(remove_package "$packages" "$package")

            packages+=" goverlay mangohud gamemode"
            ;;

        wine )
            packages+=" wine-mono winetricks"
            ;;

        qemu )
            packages=$(remove_package "$packages" "$package")

            packages+=" @virtualization"

            services+=(libvirtd.service)

            usergroups+=(libvirt)
            ;;

        VirtualBox )
            setups+=(virtualbox)

            usergroups+=(vboxusers)
            ;;

        steam )
            packages+=" steam-devices"
            ;;

        heroic )
            packages=$(remove_package "$packages" "$package")

            setups+=(heroic)
            ;;

        itch )
            packages=$(remove_package "$packages" "$package")

            setups+=("$package")
            ;;

        vscode )
            packages=$(remove_package "$packages" "$package")
            
            setups+=(vscode)
            ;;

        vscodium )
            packages=$(remove_package "$packages" "$package")

            setups+=(vscodium)
            ;;

        rustup )
            setups+=(rust)
            ;;

        nodejs )
            setups+=(npm)
            ;;

        java )
            packages=$(remove_package "$packages" "$package")

            packages+=" java-latest-openjdk"
            ;;

        xampp )
            packages=$(remove_package "$packages" "$package")

            setups+=(xampp)
            ;;

        docker )
            packages=${packages/"$package"/}

            setups+=(docker)
            services+=(docker.service)
            usergroups+=(docker)
            ;;

        docker-desktop )
            packages=$(remove_package "$packages" "$package")

            setups+=(docker-desktop)
            packages+=" gnome-terminal"
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
    packages_to_remove+=" plasma-discover --exclude=flatpak"
fi

# Modify dnf config file
# Set parallel downloads and default to yes, if it hasn't been set yet
if grep -iq "max_parallel_downloads=20" /etc/dnf/dnf.conf && grep -iq "defaultyes=True" /etc/dnf/dnf.conf; then
    echo -e "${YELLOW}Config was already modified!${NC}"
else
    printf "max_parallel_downloads=20\ndefaultyes=True\n" | sudo tee -a /etc/dnf/dnf.conf
fi

# Add rpm fusion repositories

# shellcheck disable=SC2046
sudo rpm -Uvh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
# shellcheck disable=SC2046
sudo rpm -Uvh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Update system
sudo dnf upgrade -y --refresh

# Remove unneccessary packages
# shellcheck disable=SC2086
sudo dnf remove -y $packages_to_remove

# Install groups
sudo dnf group install -y "${groups[@]}" --allowerasing

# Install packages
# shellcheck disable=SC2086
sudo dnf install -y $packages

# Install msfonts
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

# Add user to groups
for group in "${usergroups[@]}"; do
    sudo groupadd "$group"
    sudo usermod -a -G "$group" "$USER"
done

# Run setups
for app in "${setups[@]}"; do
    case $app in
        vscode )
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo dnf check-update --refresh
            sudo dnf install -y code

            setup_vscode code
            ;;

        vscodium )
            sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg

            printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | sudo tee -a /etc/yum.repos.d/vscodium.repo

            sudo dnf install codium -y

            setup_vscode codium
            ;;

        heroic )
            sudo dnf copr enable atim/heroic-games-launcher -y
            sudo dnf -y install heroic-games-launcher-bin
            ;;

        itch )
            setup_itch_app
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
            setup_rust
            ;;

        npm )
            setup_npm
            ;;

        xampp )
            setup_xampp
            ;;

        docker )
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo -y

            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        docker-desktop )
            wget -O docker-desktop.rpm "https://desktop.docker.com/linux/main/amd64/139021/docker-desktop-4.28.0-x86_64.rpm?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64"
            sudo dnf -y install docker-desktop.rpm
            rm -v docker-desktop.rpm
            ;;

        virtualbox )
                setup_virtualbox_extension
            ;;

        flatpak )
            # Remove fedora remote if it exists
            if flatpak remotes | grep -iq fedora; then
                sudo flatpak remote-delete fedora
            fi
            
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

        starship-install )
            setup_starship_install
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