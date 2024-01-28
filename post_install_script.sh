#!/usr/bin/env bash

# Made based on https://www.techhut.tv/opensuse-5-things-you-must-do-after-installing/

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

create_snapshot() {
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

    echo -e "${GREEN}Do you want to make a snapshot ${prompt_tag} the setup?(y/n)${NC} "
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) sudo snapper -v create -d "${snapshot_tag}-Install script snapshot"; break;;
            No ) break;;
        esac
    done
}

if [ $EUID -eq 0 ]; then
    echo -e "${RED}Please run without root!${NC}"
    exit 1
fi

create_snapshot 0

echo -e "${GREEN}Ask for hostname and set it${NC}"
read -p "Hostname: " hostname
# Check if hostname is empty
if [ -z $hostname ]; then
    hostname="${USER}PC"
fi
sudo hostnamectl hostname $hostname

echo -e "${GREEN}Refreshing repositories...${NC}"
sudo zypper ref

echo -e "${GREEN}Upgrading system...${NC}"
sudo zypper -vv dup -y

echo -e "${GREEN}Checking the internet connection...${NC}"
wget -q --spider http://google.com

if [ $? -eq 0 ]; then
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

echo -e "${GREEN}Removing unnecessary packages and installing extra ones...${NC}"
sudo zypper -vv rm -y --clean-deps discover kmail kontact kmines akregator kaddressbook korganizer kompare konversation tigervnc kleopatra kmahjongg kpat kreversi ksudoku
sudo zypper -vv in -y fish neofetch htop kwrite btop nvim python311-pipx

echo -e "${GREEN}Installing trash-cli...${NC}"
pipx install trash-cli

echo -e "${GREEN}Installing build tools...${NC}"
sudo zypper -vv in -y -t pattern devel_basis

echo -e "${GREEN}Installing microsoft fonts...${NC}"
sudo zypper -vv in -y fetchmsttfonts

echo -e "${GREEN}Installing gaming and other extra apps...${NC}"
sudo zypper -vv in -y lutris goverlay mangohud gamemode transmission-gtk haruna celluloid strawberry steam steam-devices

echo -e "${GREEN}Installing visual studio code...${NC}"
# install microsoft's vscode instead of the open source one, so the official packages can be used
sudo opi -n vscode

echo -e "${GREEN}Installing nodejs...${NC}"
sudo zypper -vv in -y nodejs20
sudo npm -g i npm npm-check

echo -e "${GREEN}Installing .Net...${NC}"
sudo opi -n dotnet

echo -e "${GREEN}Configuring flatpak and installing flatpak apps...${NC}"
sudo zypper -vv in -y flatpak

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo usermod -a -G wheel $USER

flatpak install -y io.missioncenter.MissionCenter com.github.tchx84.Flatseal org.gimp.GIMP org.kde.kdenlive net.davidotek.pupgui2 com.obsproject.Studio com.github.unrud.VideoDownloader

echo -e "${GREEN}Installing oh my fish!...${NC}"
echo -e "${YELLOW}Please run omf install bobthefish and exit from fish once it's done so the install can continue${NC}"
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

echo -e "${GREEN}Copying fish config...${NC}"
cp ./config.fish ~/.config/fish/config.fish -vf

echo -e "${GREEN}Installing nvchad...${NC}"
git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1 && nvim

echo -e "${GREEN}Installing nerd fonts...${NC}"
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip
unzip ./Hack.zip -d Hack
cp -fv ./Hack/*.ttf ~/.local/share/fonts
fc-cache -fv
# Delete all fonts in the directory after caching
rm -rfv ./Hack

create_snapshot 1

echo -e "${YELLOW}Please reboot for flatpak's path to work${NC}"
echo -e "${GREEN}Post install complete, enjoy your new distro!${NC}"
