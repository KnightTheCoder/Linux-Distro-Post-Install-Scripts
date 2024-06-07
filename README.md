# Post install script for Linux

## Supported distros
* [OpenSUSE][1]
* [Fedora][2]
* [Debian][3]
* [Arch linux][4]

Tested distros:
* OpenSUSE Tumbleweed
* Fedora
* Debian
* Ubuntu
* Linux Mint
* ZorinOS
* Pop!_OS
* MX Linux
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

## Requirements
- systemd (recommended but not required for some parts of the scripts)
- bash
- whiptail (optional, the script will install it if not found)

## Motivation
This project's motivation is to quickly setup a system with the same configuration/software across multiple distros.
The scripts are meant to be reproducable and allow you to get to using your new system/virtual machine rather than try to replicate your already existing setup.
You only need to configure apps and configuration files once when changing the project to suit your own needs and be able to use it afterwards.

## Steps the script runs:
- Find package manager
-  Check for whiptail and install it if it's not found
- Find Distro, ask if distro is correct, if distro and package manager don't match stop script
- Start distro specific script
- Select programs/tools to install
- Add list of recommended packages (bat, eza, git, etc.)
- Select shells to setup
- Select neovim configuration
- Break down programs/tools into setup steps (packages, services, usergroups, setups, etc.)
- Distro specific setup (add repos, install codecs, etc.)
- Add user to usergroups listed before
- Run setups for selected apps
- Start listed services
- Ask for hostname (optional)

# Project breakdown

## Project structure:
```bash
.
├── config
│   ├── firefox
│   │   └── policies.json
│   ├── fish
│   │   ├── config_debian.fish
│   │   └── config.fish
│   └── vscode
│       ├── keybindings.json
│       └── settings.json
├── distros
│   ├── arch
│   │   ├── README.md
│   │   └── setup.sh
│   ├── debian
│   │   ├── README.md
│   │   └── setup.sh
│   ├── fedora
│   │   ├── README.md
│   │   └── setup.sh
│   └── opensuse
│       ├── README.md
│       └── setup.sh
├── LICENSE
├── post_install.sh
├── README.md
└── shared
    ├── setup.fish
    ├── setup.zsh
    └── shared_scripts.sh
```

### Config
Pre-made configuration files, these are meant to be copied and not changed

### Distros
Distro specific setups that will execute the specific steps for them:
example: using the distro's package manager and approprioate package names, repos

### Shared:
Shared scripts between all distro setups, these include shell setup and program specific setups like installing hack nerd fonts, setting up scripts with plugin managers, neovim configurations, flatpaks, etc.

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

[1]: distros/opensuse#readme
[2]: distros/fedora#readme
[3]: distros/debian#readme
[4]: distros/arch#readme