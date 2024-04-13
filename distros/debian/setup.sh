#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

whiptail --title "Debian/Ubuntu" --msgbox "Welcome to the debian/ubuntu script!" 0 0

packages=$(
    whiptail --title "Install List" --separate-output --checklist "Choose what to install/configure" 0 0 0 \
    "lutris" "Lutris" OFF \
    "goverlay mangohud gamemode" "Gaming overlay" OFF \
    "steam" "Steam" OFF \
    "itch" "Itch desktop app" OFF \
    "heroic" "Heroic Games Launcher" OFF \
    "haruna" "Haruna media player" ON \
    "celluloid" "Celluloid media player" ON \
    "vlc" "VLC media player" ON \
    "audacious" "Audacious music player" OFF \
    "libreoffice" "Libreoffice" OFF \
    "transmission" "Transmission bittorrent client" OFF \
    "gimp" "GIMP" OFF \
    "kdenlive" "Kdenlive" OFF \
    "keepass2" "KeePass" OFF \
    "vscode" "Visual Studio Code" OFF \
    "vscodium" "VSCodium" OFF \
    "nodejs" "Nodejs" OFF \
    "dotnet" ".NET sdk" OFF \
    "rustup" "Rust" OFF \
    "docker" "Docker engine" OFF \
    "docker-desktop" "Docker desktop" OFF \
    "podman" "Podman" OFF \
    "distrobox" "Distrobox" OFF \
    "flatpak" "Flatpak" ON \
    "qemu" "QEMU/KVM" OFF \
    3>&1 1>&2 2>&3
)

# Remove new lines
packages=$(echo "$packages"| tr "\n" " ")

# Add defaults
services=()
setups=(hacknerd eza)
usergroups=()
remove_packages="elisa dragonplayer akregator kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat kolourpaint thunderbird"

nvim_config=$(choose_nvim_config)
setups+=("$nvim_config")

# Add packages to the correct categories
for package in $packages; do
    case $package in
        qemu )
            # Remove package
            packages=${packages//"$package"/}

            packages+=" libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-manager"

            if grep -iq ID=debian /etc/os-release; then
                packages+=" qemu-system-x86"
            else
                packages+=" qemu-kvm"
            fi

            services+=(libvirtd.service)

            usergroups+=(libvirt)
            ;;

        steam ) 
            # steam package has a different name for debian
            if grep -iq ID=debian /etc/os-release; then
                # Remove package
                packages=${packages//"$package"/}

                packages+=" steam-installer"
            fi

            packages+=" steam-devices"
            ;;

        lutris )
            setups+=(lutris)

            packages+=" wine"

            packages=${packages//"$package"/}
            ;;

        heroic )
            setups+=(heroic)

            packages=${packages//"$package"/}
            ;;

        itch )
            setups+=("$package")

            packages=${packages//"$package"/}
            ;;

        vscode )
            setups+=(vscode)
            packages+=" apt-transport-https"

            packages=${packages//"$package"/}
            ;;

        vscodium )
            setups+=(vscodium)

            packages=${packages//"$package"/}
            ;;

        rustup )
            setups+=(rust)

            packages=${packages//"$package"/}
            ;;

        nodejs )
            setups+=(npm)

            packages+=" npm"
            ;;

        dotnet )
            packages=${packages//"$package"/}

            if grep -iq "ID=debian" /etc/os-release; then
                setups+=(dotnet)
            else
                packages+=" dotnet-sdk-8.0"
            fi
            ;;

        docker )
            packages=${packages/"$package"/}

            packages+=" ca-certificates"
            setups+=(docker)
            services+=(docker.service)
            usergroups+=(docker)
            ;;

        docker-desktop )
            packages=${packages/"$package"/}

            setups+=(docker-desktop)
            packages+=" gnome-terminal"
            ;;

        distrobox )
            packages=${packages//"$package"/}

            setups+=(distrobox)
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
packages+=" git build-essential fish neofetch kwrite htop btop neovim gh bat curl wget gpg"

# Ms fonts installer and fontconfig
packages+=" ttf-mscorefonts-installer fontconfig"

# Remove extra whitespace
packages=$(echo "$packages" | xargs)

# Ask if you want to remove discover
if whiptail --title "Remove discover" --yesno "Would you like to remove discover?" 0 0; then
    remove_packages+=" plasma-discover"
fi

if grep -iq "kde neon" /etc/os-release; then
    # Download files for installing nala
    wget -O 'volian-keyring.deb' "https://gitlab.com/volian/volian-archive/uploads/d9473098bc12525687dc9aca43d50159/volian-archive-keyring_0.2.0_all.deb"
    sudo apt install ./volian-keyring.deb

    wget -O 'volian-nala.deb' "https://gitlab.com/volian/volian-archive/uploads/d00e44faaf2cc8aad526ca520165a0af/volian-archive-nala_0.2.0_all.deb"
    sudo apt install ./volian-nala.deb

    rm -v "volian-*.deb"
elif grep -iq ID=debian /etc/os-release; then
    # Add extra repositories to debian
    sudo apt install software-properties-common -y
    sudo apt-add-repository contrib non-free -y
fi

# Add 32 bit support if it's not available
# shellcheck disable=SC2046
if [ -z $(dpkg --print-foreign-architectures) ]; then
    sudo dpkg --add-architecture i386
fi

sudo apt update

# Install nala
sudo apt install -y nala

# Update system
sudo nala upgrade -y

# Remove unnecessary packages
# shellcheck disable=SC2086
sudo nala remove -y $remove_packages

# Install packages
# shellcheck disable=SC2086
sudo nala install -y $packages

# Build font cache for ms fonts
sudo fc-cache -f -v

# Run setups
for app in "${setups[@]}"; do
    case $app in
        lutris )
            wget -O 'lutris.deb' "https://github.com/lutris/lutris/releases/download/v0.5.16/lutris_0.5.16_all.deb"
            sudo apt install -y ./lutris.deb
            rm -v ./lutris.deb
            ;;

        
        heroic )
            wget -O heroic.deb https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.14.0/heroic_2.14.0_amd64.deb
            sudo dpkg -i heroic.deb
            rm -v heroic.deb

            packages=${packages//"$package"/}
            ;;

        itch )
            setup_itch_app
            ;;

        vscode )
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            rm -f packages.microsoft.gpg

            sudo nala update
            sudo nala install -y code

            setup_vscode code
            ;;

        vscodium )
            wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
                | gpg --dearmor \
                | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg

            echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
                | sudo tee /etc/apt/sources.list.d/vscodium.list
            
            sudo nala update && sudo nala install codium -y

            setup_vscode codium
            ;;

        hacknerd )
            setup_hacknerd_fonts
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

        docker )
            # Remove old packages
            for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

            sudo apt-get update
            sudo install -m 0755 -d /etc/apt/keyrings
           
            if grep -iq ID=debian /etc/os-release; then
                # Debian
                # Add Docker's official GPG key:
                sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
                sudo chmod a+r /etc/apt/keyrings/docker.asc

                # Add the repository to Apt sources:

                # shellcheck disable=SC1091
                echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            else
                # Ubuntu based
                # Add Docker's official GPG key:
                sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
                sudo chmod a+r /etc/apt/keyrings/docker.asc

                # Add the repository to Apt sources:
                if grep -iq ID=linuxmint /etc/os-release; then
                    # Linux Mint

                    # shellcheck disable=SC1091
                    echo \
                    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                    $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
                    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                else
                    # Ubuntu

                    # shellcheck disable=SC1091
                    echo \
                    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                fi
            fi

            sudo nala update
            sudo nala install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        docker-desktop )
            wget -O docker-desktop.deb "https://desktop.docker.com/linux/main/amd64/139021/docker-desktop-4.28.0-amd64.deb?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64"
            sudo apt-get update
            sudo apt-get install -y ./docker-desktop.deb
            rm -v docker.desktop.deb
            ;;

        distrobox )
            curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh
            ;;

        eza )
            if [ ! -x /usr/bin/eza ]; then
                sudo mkdir -p /etc/apt/keyrings
                wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
                sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

                sudo nala update
                sudo nala install -y eza
            fi
            ;;

        flatpak )
            setup_flatpak
            ;;
            
        fish )
            setup_fish
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