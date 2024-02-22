#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

whiptail --title "Fedora" --msgbox "Welcome to the fedora script!" 0 0

packages=$(
    whiptail --title "Install List" --separate-output --checklist "Choose what to install/configure" 0 0 0 \
    "lutris" "Lutris" OFF \
    "goverlay mangohud gamemode" "Gaming overlay" OFF \
    "haruna celluloid vlc" "Media players" ON \
    "strawberry" "Strawberry music player" ON \
    "audacious" "Audacious music player" OFF \
    "transmission-gtk" "Transmission bittorrent client" OFF \
    "steam steam-devices" "Steam" OFF \
    "gimp" "GIMP" OFF \
    "kdenlive" "Kdenlive" OFF \
    "itch" "Itch desktop app" OFF \
    "vscode" "Visual Studio Code" ON \
    "nodejs" "Nodejs" OFF \
    "dotnet" ".NET sdk" OFF \
    "rustup" "Rust" OFF \
    "flatpak" "Flatpak" ON \
    "qemu" "QEMU/KVM" OFF \
    3>&1 1>&2 2>&3
)

# Remove new lines
packages=$(echo "$packages"| tr "\n" " ")

# Add defaults
services=()
setups=(hacknerd fish nvchad)
usergroups=()

# Add packages to the correct categories
for package in $packages; do
    case $package in
        itch )
            if [ "$package" == itch ]; then
                setups+=("$package")
            fi

            # Remove package
            packages=${packages//"$package"/}
            ;;

        qemu )
            services+=(libvirtd.service)

            usergroups+=(libvirt)
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

# Add console apps
packages+=" fish neofetch kwrite htop btop neovim lynis gh eza bat"

# Add latest dnf
packages+=" dnf5 dnf5-plugins"

# Remove extra whitespace
packages=$(echo "$packages" | xargs)

# Modify dnf config file
# Set parallel downloads and default to yes
printf "max_parallel_downloads=20\ndefaultyes=True" | sudo tee -a /etc/dnf/dnf.conf

# Add rpm fusion repositories

# shellcheck disable=SC2046
sudo rpm -Uvh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
# shellcheck disable=SC2046
sudo rpm -Uvh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Update system
sudo dnf upgrade -y --refresh

# Remove unneccessary packages
sudo dnf remove -y akregator plasma-discover dragon elisa-player kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat qt5-qdbusviewer

# Install codecs
sudo dnf install -y gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-plugin-libav --exclude=gstreamer1-plugins-bad-free-devel lame* --exclude=lame-devel 

# Install packages
# shellcheck disable=SC2086
sudo dnf install -y $packages

# Run setups
for app in "${setups[@]}"; do
    case $app in
        itch )
            setup_itch_app
            ;;

        vscode )
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo dnf check-update -y
            sudo dnf install -y code

            setup_vscode
            ;;

        hacknerd )
            setup_hacknerd_fonts
            ;;

        fish )
            setup_fish
            ;;

        nvchad )
            setup_nvchad
            ;;

        rust )
            setup_rust
            ;;

        npm )
            setup_npm
            ;;

        flatpak )
            setup_flatpak
            ;;
    esac
done

# Start services
for serv in "${services[@]}"; do
    sudo systemctl enable --now "$serv"
done

# Add user to groups
for group in "${usergroups[@]}"; do
    sudo usermod -a -G "$group" "$USER"
done

# Ask for audit
if whiptail --yesno "Would you like to run an audit?" 0 0; then
    sudo lynis audit system
fi