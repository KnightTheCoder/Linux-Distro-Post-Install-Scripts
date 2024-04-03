# Post install script for OpenSUSE Tumbleweed (KDE)

# About
Made based on [this blog](https://www.techhut.tv/opensuse-5-things-you-must-do-after-installing/)

This script is only intended for OpenSUSE Tumbleweed with KDE desktop, it may not work as intended with other desktops

# Features
* Updates the system
* Creates snapshots before and after the script
* Includes additional codecs (packman) and installs opi for using the Open Build Service (OBS)
* Removes unnecessary games and packages (Intended for KDE Plasma)
* Adds the following command line utilities: fish, neofetch, htop, btop, neovim
* Copies fish config
* Installs NvChad or Astrovim for neovim
* Downloads and installs Microsoft and hack nerd fonts
* Configures flatpak and installs my most used apps
* Experimental option to install QEMU/KVM
* Installs the GitHub CLI
* Optionally sets hostname