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

    echo -e "${GREEN}Do you want to make a snapshot ${prompt_tag} the setup?${NC} "
    select yn in "Yes" "No"; do
        case $yn in
            Yes )
                sudo snapper -v create --description "${snapshot_tag}-Install script snapshot"
                break;;
            No )
                break;;
        esac
    done
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

packages+=" opi fish neofetch kwrite htop btop neovim lynis gh eza bat fetchmsttfonts"

# Remove extra whitespace
packages=$(echo "$packages" | xargs)

echo "${setups[@]}"

create_snapshot 0

echo -e "${GREEN}Refreshing repositories...${NC}"
sudo zypper refresh

echo -e "${GREEN}Upgrading system...${NC}"
sudo zypper -vv dist-upgrade -y

echo -e "${GREEN}Checking the internet connection...${NC}"

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
sudo zypper -vv install -y "$packages"

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
    usermod -a -G "$group" "$USER"
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
hostname=$(whiptail --title "Hostname" --inputbox "Type in your hostname\n Leavy empty to not change it" 0 0 3>&1 1>&2 2>&3)
# Check if hostname is not empty
if $?; then
    sudo hostnamectl hostname "$hostname"
fi

# Ask for audit
whiptail --yesno "Would you like to run an audit?" 0 0
if $?; then
    sudo lynis audit system
fi

create_snapshot 1

# echo -e "${GREEN}Installing codecs...${NC}"
# opi will do the same as packman so no need to install

# sudo zypper -vv install -y opi
# sudo opi -n codecs

# echo -e "${GREEN}Removing unnecessary packages and installing extra ones...${NC}"
# sudo zypper -vv remove -y --clean-deps discover kmail kontact kmines akregator kaddressbook korganizer kompare konversation kleopatra kmahjongg kpat kreversi ksudoku xscreensaver
# sudo zypper -vv remove -y --clean-deps patterns-kde-kde_pim patterns-games-games patterns-kde-kde_games
# sudo zypper -vv install -y fish neofetch kwrite btop neovim lynis gh eza bat

# # Tools for gaming

# echo -e "${GREEN}Installing gaming and other extra apps...${NC}"
# sudo zypper -vv install -y lutris goverlay mangohud gamemode transmission-gtk haruna celluloid strawberry audacious steam steam-devices gimp kdenlive

# echo -e "${GREEN}Installing itch.io desktop app${NC}"
# setup_itch_app

# # Tools for development

# echo -e "${GREEN}Installing build tools...${NC}"
# sudo zypper -vv install -y -t pattern devel_basis

# echo -e "${GREEN}Installing visual studio code...${NC}"
# # install microsoft's vscode instead of the open source one, so the official packages can be used
# sudo opi -n vscode

# setup_vscode

# echo -e "${GREEN}Installing nodejs...${NC}"
# sudo zypper -vv install -y nodejs20
# sudo npm -g install npm npm-check

# echo -e "${GREEN}Installing .Net...${NC}"
# sudo opi -n dotnet

# echo -e "${GREEN}Installing rust...${NC}"
# sudo zypper -vv install -y rustup
# rustup toolchain install stable

# # Fonts

# echo -e "${GREEN}Installing microsoft fonts...${NC}"
# sudo zypper -vv install -y fetchmsttfonts

# echo -e "${GREEN}Installing nerd fonts...${NC}"
# setup_hacknerd_fonts

# # Configurations

# setup_fish

# echo -e "${GREEN}Installing nvchad...${NC}"
# git clone https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1 && nvim

# echo -e "${GREEN}Settinng up zram...${NC}"
# sudo zypper -vv install -y systemd-zram-service
# sudo systemctl enable --now zramswap.service

# echo -e "${GREEN}Configuring flatpak and installing flatpak apps...${NC}"
# sudo zypper -vv install -y flatpak
# sudo usermod -a -G wheel "$USER"

# setup_flatpak

# echo -e "${GREEN}Ask for hostname and set it${NC}"
# echo -e "${YELLOW}Leave empty to not change it${NC}"
# echo -en "${GREEN}Hostname: ${NC}"
# read -r hostname
# # Check if hostname is not empty
# if [ -n "$hostname" ]; then
#     sudo hostnamectl hostname "$hostname"
# fi

# # QEMU/KVM
# # Reference https://github.com/sysadmin-info/kvm/blob/main/kvm-opensuse.sh

# echo -en "${GREEN}Would you like to install QEMU/KVM? ${NC}"
# select yn in "Yes" "No"; do
#     case $yn in
#         Yes )
#             echo -e "${GREEN}Installing QEMU/KVM...${NC}"
#             sudo zypper -vv install -yt pattern kvm_tools kvm_server
#             sudo zypper -vv install -y libvirt bridge-utils

#             sudo systemctl start kvm_stat.service
#             sudo systemctl enable kvm_stat.service

#             sudo systemctl start libvirtd.service
#             sudo systemctl enable libvirtd.service

#             sudo usermod -a -G libvirt "$USER"

#             break;;
#         No )
#             break;;
#     esac
# done

# echo -e "${GREEN}Would you like to run an audit?${NC}"
# select yn in "Yes" "No"; do
#     case $yn in
#         Yes )
#             sudo lynis audit system
#             break;;
#         No )
#             break;;
#     esac
# done

# create_snapshot 1