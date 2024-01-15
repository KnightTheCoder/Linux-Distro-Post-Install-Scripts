#!/usr/bin/env bash

if [ $EUID -eq 0 ]; then
    echo "Please run without root!"
    exit
fi

echo "Ask for hostname and set it"
read -p "Hostname: " hostname
sudo hostnamectl hostname $hostname

echo "Refreshing repositories..."
sudo zypper ref

echo "Upgrading system..."
sudo zypper -v dup

echo "Check the internet..."
wget -q --spider http://google.com

if [ $? -eq 0 ]; then
    echo "Online"
else
    echo "Offline"
    echo "Please restart to progress the post install script!"
    exit
fi

echo "Installing codecs..."
sudo zypper ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ packman
sudo zypper -v dup --from packman --allow-vendor-change

sudo zypper -v install opi
opi codecs

echo "Removing unnecessary packages and installing extra ones..."
sudo zypper -v rm --clean-deps discover kmail kontact kmines akregator kaddressbook korganizer kompare konversation tigervnc kleopatra kmahjongg kpat kreversi ksudoku
sudo zypper -v in fish neofetch htop kwrite

echo "Installing build tools..."
sudo zypper -v in -t pattern devel_basis

echo "Installing microsoft fonts..."
sudo zypper -v in fetchmsttfonts

echo "Installing oh my fish!..."
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

echo "Copying fish config..."
cp ./config.fish ~/.config/fish/config.fish -vf

echo "Installing gaming and other extra apps..."
sudo zypper in -v lutris goverlay mangohud transmission-gtk haruna celluloid strawberry

echo "Installing visual studio code..."
sudo zypper ar obs://devel:tools:ide:vscode devel_tools_ide_vscode
sudo zypper -v in code

echo "Configuring flatpak and installing flatpak apps..."
sudo zypper -v in flatpak

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo usermod -a -G wheel $USER

flatpak install io.missioncenter.MissionCenter com.github.tchx84.Flatseal org.gimp.GIMP org.kde.kdenlive com.valvesoftware.Steam net.davidotek.pupgui2 com.obsproject.Studio com.github.unrud.VideoDownloader

echo "Post install complete, enjoy your new distro!"
echo "Please run 'fish && omf install bobthefish' to install the omf theme"
