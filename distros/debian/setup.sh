#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

packages=$(
    whiptail --title "Debian/Ubuntu app installer" --separate-output --notags --checklist "Choose which apps to install" 0 0 0 \
        "lutris" "Lutris" OFF \
        "wine" "Wine" OFF \
        "gaming-overlay" "Gaming overlay" OFF \
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
        "virtualbox" "Oracle Virtualbox" OFF \
        3>&1 1>&2 2>&3
)

cli_packages=$(
    whiptail --title "CLI install" --separate-output --notags --checklist "Select cli applications to install" 0 0 0 \
        "neofetch" "neofetch" ON \
        "htop" "htop" ON \
        "btop" "btop++" ON \
        "gh" "github cli" OFF \
        3>&1 1>&2 2>&3
)

packages+=" $cli_packages"

packages+=" git build-essential neovim bat curl wget gpg ttf-mscorefonts-installer fontconfig p7zip p7zip-rar unrar rar"

shells=$(choose_shells)

if [[ $shells == *"starship"* ]]; then
    shells="starship-install $shells"
fi

packages+=" $shells"

# Remove new lines
packages=$(echo "$packages" | tr "\n" " ")

# Add defaults
services=()
setups=(hacknerd eza)
usergroups=()
packages_to_remove="elisa dragonplayer akregator kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat kolourpaint thunderbird"

nvim_config=$(choose_nvim_config)
setups+=("$nvim_config")

# Add packages to the correct categories
for package in $packages; do
    case $package in
    bash)
        packages+=" gawk"

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

    gaming-overlay)
        packages=$(remove_package "$packages" "$package")

        packages+=" goverlay mangohud gamemode"
        ;;

    wine)
        packages+=" wine32 winetricks"
        ;;

    qemu)
        packages=$(remove_package "$packages" "$package")

        packages+=" libvirt-clients libvirt-daemon-system bridge-utils virtinst libvirt-daemon virt-manager"

        # shellcheck disable=SC2154
        if grep -iq ID=debian "$distro_release"; then
            packages+=" qemu-system-x86"
        else
            packages+=" qemu-kvm"
        fi

        services+=(libvirtd.service)

        usergroups+=(libvirt)
        ;;

    virtualbox)
        packages=$(remove_package "$packages" "$package")

        packages+=" dkms build-essential linux-headers-$(uname -r) curl wget apt-transport-https gnupg2"

        setups+=(virtualbox)

        usergroups+=(vboxusers)
        ;;

    steam)
        # steam package has a different name for debian
        if grep -iq ID=debian "$distro_release"; then
            packages=$(remove_package "$packages" "$package")

            packages+=" steam-installer"
        fi

        packages+=" steam-devices"
        ;;

    lutris)
        packages=$(remove_package "$packages" "$package")

        setups+=(lutris)

        packages+=" wine"
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
        packages+=" apt-transport-https"
        ;;

    vscodium)
        packages=$(remove_package "$packages" "$package")

        setups+=(vscodium)
        ;;

    dotnet)
        packages=$(remove_package "$packages" "$package")

        if grep -iq "ID=debian" "$distro_release"; then
            setups+=(dotnet)
        else
            packages+=" dotnet-sdk-8.0"
        fi
        ;;

    rustup)
        packages=$(remove_package "$packages" "$package")

        setups+=(rust)
        ;;

    nodejs)
        setups+=(npm)

        packages+=" npm"
        ;;

    golang)
        if grep -iq ubuntu "$distro_release"; then
            packages=$(remove_package "$packages" "$package")

            packages+=" golang-go"
        fi
        ;;

    java)
        packages=$(remove_package "$packages" "$package")

        packages+=" default-jdk"
        ;;

    xampp)
        packages=$(remove_package "$packages" "$package")

        setups+=(xampp)
        ;;

    docker)
        packages=${packages/"$package"/}

        packages+=" ca-certificates"
        setups+=(docker)
        services+=(docker.service)
        usergroups+=(docker)
        ;;

    docker-desktop)
        packages=$(remove_package "$packages" "$package")

        setups+=(docker-desktop)
        packages+=" gnome-terminal"
        ;;

    distrobox)
        packages=$(remove_package "$packages" "$package")

        setups+=(distrobox)
        ;;

    flatpak)
        setups+=(flatpak)
        ;;

    *) ;;
    esac
done

# Remove extra whitespace
packages=$(echo "$packages" | xargs)

# Ask if you want to remove discover
if whiptail --title "Remove discover" --yesno "Would you like to remove discover?" 0 0; then
    packages_to_remove+=" plasma-discover"
fi

if grep -iq "kde neon" "$distro_release"; then
    echo -e "${GREEN}Installing nala...${NC}"
    # Download files for installing nala
    wget -O 'volian-keyring.deb' "https://gitlab.com/volian/volian-archive/uploads/d9473098bc12525687dc9aca43d50159/volian-archive-keyring_0.2.0_all.deb"
    sudo apt install ./volian-keyring.deb

    wget -O 'volian-nala.deb' "https://gitlab.com/volian/volian-archive/uploads/d00e44faaf2cc8aad526ca520165a0af/volian-archive-nala_0.2.0_all.deb"
    sudo apt install ./volian-nala.deb

    rm -v "volian-*.deb"
elif grep -iq ID=debian "$distro_release"; then
    echo -e "${GREEN}Adding extra repositories...${NC}"
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
sudo nala remove -y $packages_to_remove

# Install packages
# shellcheck disable=SC2086
sudo nala install -y $packages

echo -e "${GREEN}Adding user to groups...${NC}"
# Add user to groups
for group in "${usergroups[@]}"; do
    sudo groupadd "$group"
    sudo usermod -a -G "$group" "$USER"
done

# Run setups
for app in "${setups[@]}"; do
    case $app in
    lutris)
        wget -O 'lutris.deb' "https://github.com/lutris/lutris/releases/download/v0.5.17/lutris_0.5.17_all.deb"
        sudo apt install -y ./lutris.deb
        rm -v ./lutris.deb
        ;;

    heroic)
        wget -O heroic.deb https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.14.0/heroic_2.14.0_amd64.deb
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

        sudo nala update
        sudo nala install -y code

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

        sudo nala update && sudo nala install codium -y

        setup_vscode codium
        ;;

    hacknerd)
        setup_hacknerd_fonts
        ;;

    rust)
        setup_rust
        ;;

    npm)
        setup_npm
        ;;

    dotnet)
        wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb
        rm -v packages-microsoft-prod.deb

        sudo nala update && sudo nala install -y dotnet-sdk-8.0
        ;;

    xampp)
        setup_xampp
        ;;

    docker)
        sudo apt-get update
        sudo install -m 0755 -d /etc/apt/keyrings

        if grep -iq ID=debian "$distro_release"; then
            # Debian

            # Add Docker's official GPG key:
            if [ ! -e /etc/apt/keyrings/docker.asc ]; then
                sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
            fi

            sudo chmod a+r /etc/apt/keyrings/docker.asc

            # Add the repository to Apt sources:

            # shellcheck disable=SC1091
            echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
                $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
                sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        else
            # Ubuntu based

            # Add Docker's official GPG key:
            if [ ! -e /etc/apt/keyrings/docker.asc ]; then
                sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
            fi

            sudo chmod a+r /etc/apt/keyrings/docker.asc

            # Add the repository to Apt sources:
            if grep -iq ID=linuxmint "$distro_release"; then
                # Linux Mint

                # shellcheck disable=SC1091
                echo \
                    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                    $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" |
                    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
            else
                # Ubuntu

                # shellcheck disable=SC1091
                echo \
                    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
                    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
                    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
            fi
        fi

        sudo nala update
        sudo nala install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        ;;

    docker-desktop)
        wget -O docker-desktop.deb "https://desktop.docker.com/linux/main/amd64/139021/docker-desktop-4.28.0-amd64.deb?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-linux-amd64"
        sudo apt-get update
        sudo apt-get install -y ./docker-desktop.deb
        rm -v docker-desktop.deb
        ;;

    distrobox)
        curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sudo sh
        ;;

    virtualbox)
        if [ ! -e /etc/apt/trusted.gpg.d/vbox.gpg ]; then
            curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/vbox.gpg
        fi

        echo deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/vbox.gpg] http://download.virtualbox.org/virtualbox/debian jammy contrib | sudo tee /etc/apt/sources.list.d/virtualbox.list

        sudo nala update

        vb_name="virtualbox"

        if grep -iq ID=debian "$distro_release"; then
            vb_name="virtualbox-7.0"
        fi

        sudo nala install ${vb_name} -y

        setup_virtualbox_extension
        ;;

    eza)
        if [ ! -x /usr/bin/eza ]; then
            sudo mkdir -p /etc/apt/keyrings

            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg

            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

            sudo nala update
            sudo nala install -y eza
        else
            echo -e "${YELLOW}eza is already installed${NC}"
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
        setup_starship_install
        ;;

    starship)
        setup_starship
        ;;
    esac
done

echo -e "${GREEN}Starting services...${NC}"
# Start services
for serv in "${services[@]}"; do
    sudo systemctl enable --now "$serv"
done
