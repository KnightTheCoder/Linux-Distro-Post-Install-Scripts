# Post install script for Linux

## Supported distros
* OpenSUSE
* Fedora
* Debian
* Arch linux

Tested distros:
* OpenSUSE Tumbleweed
* Fedora
* Debian
* Ubuntu
* Linux Mint
* ZorinOS
* Arch Linux
* EndeavourOS

## Features
* Choose the apps and configurations you need
* Updates the system
* Sets up flatpak and install apps
* Downloads and installs microsoft and hack nerd fonts
* Installs Visual Studio Code and Codium extensions and copies the keybindings
* Installs gaming launchers such as Steam, lutris, itch desktop app
* Adds the following command line utilities: neofetch, htop, btop, neovim, eza, bat
* Installs wine and Protonup-Qt to run windows games
* Sets up fish and zsh
* Installs NvChad or Astrovim for neovim
* Installs the GitHub CLI
* Installs docker, podman and distrobox for containers
* Optionally sets hostname

## How to run

### Stable

#### Download scripts
```console
wget -O "$(xdg-user-dir DOWNLOAD)/post-install-scripts.zip" "https://github.com/KnightTheCoder/Linux-Distro-Post-Install-Scripts/archive/refs/heads/master.zip"
```

#### Navigate and unzip
```console
cd "$(xdg-user-dir DOWNLOAD)" && unzip post-install-scripts.zip && cd Linux-Distro-Post-Install-Scripts-master
```

#### Run
```console
bash ./post_install.sh
```

### Experimental

#### Download scripts
```console
wget -O "$(xdg-user-dir DOWNLOAD)/post-install-scripts.zip" "https://github.com/KnightTheCoder/Linux-Distro-Post-Install-Scripts/archive/refs/heads/maintanence.zip"
```

#### Navigate and unzip
```console
cd "$(xdg-user-dir DOWNLOAD)" && unzip post-install-scripts.zip && cd Linux-Distro-Post-Install-Scripts-maintanence
```

#### Run
```console
bash ./post_install.sh
```

### To copy the firefox policy
#### Run with
```console
bash ./post_install.sh --copy-firefox-policy
```