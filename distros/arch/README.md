# Post install script for Arch linux with plasma desktop 👋

> [!NOTE]
> This script is only intended for Arch linux with KDE desktop, it may not work as intended with other desktops

# Disclaimer
> [!IMPORTANT]
> Upgrade the system and restart before running the script, as the microsoft fonts need the latest kernel installed

# ✨ Features
* Installs archlinux-keyring to update outdated certificates (when using an outdated iso)
* Updates the system
* Configures pacman to use multilib (for 32 bit programs, example: steam) and parallel downloads (set to 100)
* Set color and ILoveCandy for visuals
* Installs yay