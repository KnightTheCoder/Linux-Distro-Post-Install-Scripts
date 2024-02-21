#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=.../../shared/shared_scripts.sh
source "../../shared/shared_scripts.sh"

function create_snapshot() {
    local snapshot_type=$1 # 0 or anything else
    local prompt_tag='before'
    local snapshot_tag='Pre'

    case $snapshot_type in
        0)
            prompt_tag='before'
            snapshot_tag='Pre'
            ;;

        *)
            prompt_tag='after'
            snapshot_tag='Post'
            ;;
    esac

    if whiptail --yesno "Do you want to make a snapshot ${prompt_tag} the setup?" 0 0; then
        sudo snapper -v create --description "${snapshot_tag}-Install script snapshot"
    fi
}

whiptail --title "OpenSUSE" --msgbox "Welcome to the OpenSUSE script!" 0 0

packages=$(
    whiptail --title "Install List" --separate-output --checklist "Choose what to install/configure" 0 0 0 \
    "lutris" "Lutris" OFF \
    "goverlay mangohud gamemode" "Gaming overlay" OFF \
    "haruna celluloid" "Media players" ON \
    "strawberry" "Strawberry music player" ON \
    "audacious" "Audacious music player" OFF \
    "transmission-gtk" "Transmission bittorrent client" ON \
    "steam steam-devices" "Steam" OFF \
    "gimp" "GIMP" ON \
    "kdenlive" "Kdenlive" ON \
    "itch" "Itch desktop app" OFF \
    "vscode" "Visual Studio Code" OFF \
    "nodejs20" "Nodejs" OFF \
    "dotnet" ".NET sdk" OFF \
    "rustup" "Rust" OFF \
    "flatpak" "Flatpak" ON \
    "qemu" "QEMU/KVM" OFF \
    3>&1 1>&2 2>&3
)

# Remove new lines
packages=$(echo "$packages"| tr "\n" " ")

# Add defaults
opi=(codecs)
patterns=(devel_basis)
services=(zramswap.service)
setups=(hacknerd fish nvchad)
usergroups=()

# Add packages to the correct categories
for package in $packages; do
    case $package in
        itch|qemu )
            if [ "$package" == itch ]; then
                setups+=("$package")
            fi

            if [ "$package" == qemu ]; then
                patterns+=(kvm_tools)
                patterns+=(kvm_server)

                packages+=" libvirt bridge-utils"

                services+=(kvm_stat.service)
                services+=(libvirtd.service)

                usergroups+=(libvirt)
            fi

            # Remove package
            packages=${packages//"$package"/}
            ;;

        vscode|dotnet )
            if [ "$package" == vscode ]; then
                setups+=(vscode)
            fi

            opi+=("$package")

            # Remove package
            packages=${packages//"$package"/}
            ;;

        rustup )
            setups+=(rust)
            ;;

        nodejs20 )
            setups+=(npm)
            ;;

        flatpak )
            setups+=(flatpak)
            usergroups+=(wheel)
            ;;

        * ) ;;
    esac
done

packages+=" opi fish neofetch kwrite htop btop neovim lynis gh eza bat fetchmsttfonts systemd-zram-service"

# Remove extra whitespace
packages=$(echo "$packages" | xargs)

create_snapshot 0

echo -e "${GREEN}Refreshing repositories...${NC}"
sudo zypper refresh

echo -e "${GREEN}Upgrading system...${NC}"
sudo zypper -vv dist-upgrade -y

if wget -q --spider http://google.com; then
    echo -e "${GREEN}Online${NC}"
else
    echo -e "${RED}Offline"
    echo -e "Please restart to progress the post install script!${NC}"
    exit 0
fi

# Remove unncessary packages
sudo zypper -vv remove -y --clean-deps discover kmail kontact kmines akregator kaddressbook korganizer kompare konversation kleopatra kmahjongg kpat kreversi ksudoku xscreensaver
sudo zypper -vv remove -y --clean-deps patterns-kde-kde_pim patterns-games-games patterns-kde-kde_games

# Install packages
# Don't use quotes, zypper won't recognize the packages
# shellcheck disable=SC2086
sudo zypper -vv install -y $packages

# Install patterns
sudo zypper -vv install -yt pattern "${patterns[@]}"

# Install opi packages
opi -nm "${opi[@]}"

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
            rustup toolchain install stable
            ;;

        npm )
            sudo npm -g install npm npm-check
            ;;

        flatpak )
            setup_flatpak
            ;;
    esac
done

# Set hostname
# Check if hostname is not empty
if hostname=$(whiptail --title "Hostname" --inputbox "Type in your hostname\nLeave empty to not change it" 0 0 3>&1 1>&2 2>&3); then
    sudo hostnamectl hostname "$hostname"
fi

# Ask for audit
if whiptail --yesno "Would you like to run an audit?" 0 0; then
    sudo lynis audit system
fi

create_snapshot 1