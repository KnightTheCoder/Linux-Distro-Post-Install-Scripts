#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

whiptail --title "Debian/Ubuntu" --msgbox "Welcome to the debian/ubuntu script!" 0 0

packages=$(
    whiptail --title "Install List" --separate-output --checklist "Choose what to install/configure" 0 0 0 \
    "lutris" "Lutris" OFF \
    "goverlay mangohud gamemode" "Gaming overlay" OFF \
    "haruna" "Haruna media player" ON \
    "celluloid" "Celluloid media player" ON \
    "vlc" "VLC media player" ON \
    "strawberry" "Strawberry music player" ON \
    "audacious" "Audacious music player" OFF \
    "transmission" "Transmission bittorrent client" OFF \
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
    "openrgb" "OpenRGB" OFF \
    3>&1 1>&2 2>&3
)

# Remove new lines
packages=$(echo "$packages"| tr "\n" " ")

# Add defaults
services=()
setups=(hacknerd fish eza)
usergroups=()

nvim_config=$(whiptail --menu "Choose a neovim configuration (choose nvchad if unsure)" 0 0 0 \
    "nvchad" "NVChad" \
    "astrovim" "Astrovim" \
    3>&1 1>&2 2>&3
)

if [ -z "$nvim_config" ]; then
    setups+=(nvchad)
else
    setups+=("$nvim_config")
fi

# Add packages to the correct categories
for package in $packages; do
    case $package in
        itch )
            setups+=("$package")

            # Remove package
            packages=${packages//"$package"/}
            ;;

        qemu )
            # Remove package
            packages=${packages//"$package"/}

            packages+=" qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-manager"

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

            # Remove package
            packages=${packages//"$package"/}
            ;;

        nodejs )
            setups+=(npm)
            ;;

        dotnet )
            # Remove package
            packages=${packages//"$package"/}

            if grep -iq "ID=debian" /etc/os-release; then
                setups+=(dotnet)
            else
                packages+=" dotnet-sdk-8.0"
            fi
            ;;

        flatpak )
            setups+=(flatpak)
            ;;

        openrgb )
            # Remove package
            packages=${packages//"$package"/}

            setups+=(openrgb)
            ;;

        * ) ;;
    esac
done

# Add console apps
packages+=" fish neofetch kwrite htop btop neovim lynis gh bat curl wget gpg"

# Ms fonts installer and fontconfig
packages+=" ttf-mscorefonts-installer fontconfig"

# Remove extra whitespace
packages=$(echo "$packages" | xargs)

sudo apt update

# Install nala
sudo apt install -y nala

# Update system
sudo nala upgrade -y

# Remove unnecessary packages
sudo nala remove -y plasma-discover elisa dragonplayer kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat kolourpaint thunderbird

# Install packages
# shellcheck disable=SC2086
sudo nala install -y $packages

# Build font cache for ms fonts
sudo fc-cache -f -v

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
        itch )
            setup_itch_app
            ;;

        vscode )
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            rm -f packages.microsoft.gpg

            sudo nala install -y apt-transport-https
            sudo nala update
            sudo nala install -y code

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

        astrovim )
            setup_astrovim
            ;;

        rust )
            setup_rust
            ;;

        npm )
            setup_npm
            ;;

        dotnet )
            wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb

            sudo nala update && sudo nala install -y dotnet-sdk-8.0
            ;;

        eza )
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            sudo apt update
            sudo apt install -y eza
            ;;

        openrgb )
            sudo add-apt-repository ppa:thopiekar/openrgb
            sudo nala update
            sudo nala install -y openrgb
            ;;

        flatpak )
            setup_flatpak
            ;;
    esac
done