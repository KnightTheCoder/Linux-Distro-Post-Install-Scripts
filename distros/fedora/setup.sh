#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

whiptail --title "Fedora" --msgbox "Welcome to the fedora script!" 0 0

packages=$(
    whiptail --title "Install List" --separate-output --checklist "Choose what to install/configure" 0 0 0 \
    "lutris" "Lutris" OFF \
    "goverlay mangohud gamemode" "Gaming overlay" OFF \
    "steam" "Steam" OFF \
    "haruna" "Haruna media player" ON \
    "celluloid" "Celluloid media player" ON \
    "vlc" "VLC media player" ON \
    "strawberry" "Strawberry music player" ON \
    "audacious" "Audacious music player" OFF \
    "transmission" "Transmission bittorrent client" OFF \
    "qbittorrent" "Qbittorrent bittorrent client" OFF \
    "gimp" "GIMP" OFF \
    "kdenlive" "Kdenlive" OFF \
    "vscode" "Visual Studio Code" OFF \
    "nodejs" "Nodejs" OFF \
    "dotnet" ".NET sdk" OFF \
    "rustup" "Rust" OFF \
    "flatpak" "Flatpak" ON \
    "qemu" "QEMU/KVM" OFF \
    "openrgb" "OpenRGB" OFF \
    3>&1 1>&2 2>&3
)

# Remove new lines
packages=$(echo "$packages"| tr "\n" " ")

# Add defaults
services=()
setups=(hacknerd)
usergroups=()
remove_packages="akregator dragon elisa-player kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat kolourpaint qt5-qdbusviewer \"libreoffice*\""

nvim_config=$(choose_nvim_config)
setups+=("$nvim_config")

# Add packages to the correct categories
for package in $packages; do
    case $package in
        qemu )
            packages+=" @virtualization"

            services+=(libvirtd.service)

            usergroups+=(libvirt)

            # Remove package
            packages=${packages//"$package"/}
            ;;

        steam )
            packages+=" steam-devices"
            ;;

        vscode )
            setups+=(vscode)

            # Remove package
            packages=${packages//"$package"/}
            ;;

        rustup )
            setups+=(rust)
            ;;

        nodejs )
            setups+=(npm)
            ;;

        flatpak )
            setups+=(flatpak)
            ;;

        * ) ;;
    esac
done

# Add fish setup to be last
setups+=(fish)

# Add console apps
packages+=" fish neofetch kwrite htop btop neovim lynis gh eza bat"

# Add latest dnf
packages+=" dnf5 dnf5-plugins"

# Dependencies for ms fonts
packages+=" curl cabextract xorg-x11-font-utils fontconfig"

# Remove extra whitespace
packages=$(echo "$packages" | xargs)

# Ask if you want to remove discover
if whiptail --title "Remove discover" --yesno "Would you like to remove discover?" 0 0; then
    remove_packages+=" plasma-discover --exclude=flatpak"
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
sudo dnf remove -y $remove_packages

# Install codecs
sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-plugin-libav --exclude=gstreamer1-plugins-bad-free-devel lame* --exclude=lame-devel 

# Install packages
# shellcheck disable=SC2086
sudo dnf install -y $packages

# Install msfonts
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

# Start services
for serv in "${services[@]}"; do
    sudo systemctl enable --now "$serv"
done

# Add user to groups
for group in "${usergroups[@]}"; do
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

            setup_vscode
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

        flatpak )
            # Remove fedora remote if it exists
            if flatpak remotes | grep -iq fedora; then
                sudo flatpak remote-delete fedora
            fi
            
            setup_flatpak "org.libreoffice.LibreOffice"
            ;;

        fish )
            setup_fish
            ;;
    esac
done