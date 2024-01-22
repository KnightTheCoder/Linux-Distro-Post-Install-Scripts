# Post install script for OpenSUSE Tumbleweed (KDE)

Made based on [this blog](https://www.techhut.tv/opensuse-5-things-you-must-do-after-installing/)

* Installs update
* Creates snapshots before and after the script
* Includes additional codecs (packman and opi)
* Removes unnecessary packages (Intended for KDE Plasma)
* Adds command line utilities like htop and fish
* Copies fish config
* Configures flatpak and installs my most used apps

run with ``` sh ./post_install_script.sh ```