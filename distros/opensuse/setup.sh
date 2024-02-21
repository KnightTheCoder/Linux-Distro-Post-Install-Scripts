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
                sudo snapper -v create -d "${snapshot_tag}-Install script snapshot"
                break;;
            No )
                break;;
        esac
    done
}

whiptail --title "OpenSUSE" --msgbox "Welcome to the OpenSUSE script!" 0 0

packages=$(
    whiptail --title "Install List" --separate-output --checklist "Choose what to install/configure" 0 0 0 \
    "nvidia" "NVIDIA drivers" OFF \
    "lutris" "Lutris" OFF \
    "goverlay mangohud gamemode" "Gaming overlay" OFF \
    "haruna celluloid" "Media players" ON \
    "strawberry audacious" "Music players" ON \
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
    3>&1 1>&2 2>&3
)

create_snapshot 0

echo -e "${GREEN}Refreshing repositories...${NC}"
sudo zypper ref

echo -e "${GREEN}Upgrading system...${NC}"
sudo zypper -vv dup -y

echo -e "${GREEN}Checking the internet connection...${NC}"

if wget -q --spider http://google.com; then
    echo -e "${GREEN}Online${NC}"
else
    echo -e "${RED}Offline"
    echo -e "Please restart to progress the post install script!${NC}"
    exit 0
fi

echo -e "${GREEN}Installing codecs...${NC}"
# opi will do the same as packman so no need to install

sudo zypper -vv in -y opi
sudo opi -n codecs

# Install NVIDIA drivers
echo -e "${GREEN}Would you like to install the NVIDIA driver?${NC} "
select yn in "Yes" "No"; do
    case $yn in
        Yes )
            echo -e "${GREEN}Installing NVIDIA driver...${NC}"
            sudo zypper -vv addrepo --refresh https://download.nvidia.com/opensuse/tumbleweed NVIDIA
            sudo zypper -vv install-new-recommends --repo NVIDIA
            break;;
        No )
            break;;
    esac
done

echo -e "${GREEN}Removing unnecessary packages and installing extra ones...${NC}"
sudo zypper -vv rm -y --clean-deps discover kmail kontact kmines akregator kaddressbook korganizer kompare konversation kleopatra kmahjongg kpat kreversi ksudoku xscreensaver
sudo zypper -vv rm -y --clean-deps patterns-kde-kde_pim patterns-games-games patterns-kde-kde_games
sudo zypper -vv in -y fish neofetch kwrite btop neovim lynis gh eza bat

# Tools for gaming

echo -e "${GREEN}Installing gaming and other extra apps...${NC}"
sudo zypper -vv in -y lutris goverlay mangohud gamemode transmission-gtk haruna celluloid strawberry audacious steam steam-devices gimp kdenlive

echo -e "${GREEN}Installing itch.io desktop app${NC}"
setup_itch_app

# Tools for development

echo -e "${GREEN}Installing build tools...${NC}"
sudo zypper -vv in -y -t pattern devel_basis

echo -e "${GREEN}Installing visual studio code...${NC}"
# install microsoft's vscode instead of the open source one, so the official packages can be used
sudo opi -n vscode

setup_vscode

echo -e "${GREEN}Installing nodejs...${NC}"
sudo zypper -vv in -y nodejs20
sudo npm -g i npm npm-check

echo -e "${GREEN}Installing .Net...${NC}"
sudo opi -n dotnet

echo -e "${GREEN}Installing rust...${NC}"
sudo zypper -vv in -y rustup
rustup toolchain install stable

# Fonts

echo -e "${GREEN}Installing microsoft fonts...${NC}"
sudo zypper -vv in -y fetchmsttfonts

echo -e "${GREEN}Installing nerd fonts...${NC}"
setup_hacknerd_fonts

# Configurations

setup_fish

echo -e "${GREEN}Installing nvchad...${NC}"
git clone https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1 && nvim

echo -e "${GREEN}Settinng up zram...${NC}"
sudo zypper -vv in -y systemd-zram-service
sudo systemctl enable --now zramswap.service

echo -e "${GREEN}Configuring flatpak and installing flatpak apps...${NC}"
sudo zypper -vv in -y flatpak
sudo usermod -a -G wheel "$USER"

setup_flatpak

echo -e "${GREEN}Ask for hostname and set it${NC}"
echo -e "${YELLOW}Leave empty to not change it${NC}"
echo -en "${GREEN}Hostname: ${NC}"
read -r hostname
# Check if hostname is not empty
if [ -n "$hostname" ]; then
    sudo hostnamectl hostname "$hostname"
fi

echo -e "${GREEN}Would you like to run an audit?${NC}"
select yn in "Yes" "No"; do
    case $yn in
        Yes )
            sudo lynis audit system
            break;;
        No )
            break;;
    esac
done

create_snapshot 1