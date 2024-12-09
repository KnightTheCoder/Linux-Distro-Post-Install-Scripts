# Welcome to the Linux Post install documentation 👋

## 📃 Steps the script runs:

-   Find package manager
-   Check for whiptail and install it if it's not found
-   Find Distro, ask if distro is correct, if distro and package manager don't match stop script
-   Start distro specific script
-   Select programs/tools to install
-   Add list of recommended packages (bat, eza, git, etc.)
-   Select shells to setup
-   Select NVIDIA driver
-   Select neovim configuration
-   Break down programs/tools into setup steps (packages, services, usergroups, setups, etc.)
-   Distro specific setup (add repos, install codecs, etc.)
-   Add user to usergroups listed before
-   Run setups for selected apps
-   Start listed services
-   Ask for hostname (optional)

## List of packages to install

### Mandatory install list

-   Command line utilities: bat, eza, neovim
-   Fonts: ms fonts, hack nerd fonts
-   Archives: 7zip, rar
-   Development tools: gcc, git, curl, wget

### Bloat list

-   akregator
-   dragon
-   elisa-player
-   dragonplayer
-   kaddressbook
-   kmahjongg
-   kmail
-   kontact
-   kmines
-   konversation
-   kmouth
-   korganizer
-   kpat
-   kolourpaint
-   kompare
-   kreversi
-   ksudoku
-   xscreensaver
-   qt5-qdbusviewer
-   thunderbird

### Native install list

-   Browsers: firefox, librewolf, chromium, vivaldi, brave
-   Gaming launchers: steam, lutris, heroic, itch
-   Windows compatibility: wine
-   Multimedia: haruna, celluloid, vlc, strawberry, audacious, kdenlive, gimp
-   Office apps: libreoffice, calibre ebook reader
-   Password managers: keepassxc
-   Command line utilities: fastfetch, btop, github cli, neovim, eza, bat
-   Shells: bash, fish, zsh
-   Prompts: starship
-   Containers: docker, docker-desktop, podman, distrobox
-   Virtualization: qemu, virtualbox
-   Code editors: vscode, vscodium
-   Programming languages and development environments: gcc, nodejs, dotnet, rust, go, java, xampp
-   Bittorrent clients: transmission, qbittorrent
-   RGB management: openrgb

### Flatpak install list

-   Browsers: firefox, librewolf, floorp, google chrome, brave, vivaldi, mullavad
-   Management: Flatseal(for flatpaks), Gear Lever(for appimages), Flatsweep (clean up leftover flatpak files)
-   Gaming launchers: steam, heroic, itch
-   Windows compatibility: Protonup-QT
-   Office: libreoffice, onlyoffice
-   Screen recording: obs, gpu screen recorder
-   Container GUI apps: podman desktop
-   Multimedia: gimp, kdenlive
-   Video/Audio download: video downloader
-   Password managers: keepassxc
-   Discord clients: discord, webcord, vesktop

## Shell configurations

### Bash

-   [blesh](https://github.com/akinomyoga/ble.sh)
-   cat is alias for bat
-   ls is alias for eza

### Fish

-   [oh-my-fish](https://github.com/oh-my-fish/oh-my-fish)
-   cat is alias for bat
-   ls is alias for eza

### Zsh

-   [prezto](https://github.com/sorin-ionescu/prezto)
-   Syntac highlighting
-   Autocompletion
-   Zsh abbreviation
-   cat is alias for bat
-   ls is alias for eza

### Starship

-   [Tokyo Night preset](https://starship.rs/presets/tokyo-night)
-   Prompt's logo changes to distro's logo

## 🌐 Firefox policy

3 firefox policy templates are included for increased privacy.

> [!NOTE]
> Can be found at `config/firefox/policies.json` <br />
> Manually edit to customize, then copy to `/etc/firefox/policies/` for it to work

The project provides the following policy templates:

-   Basic
-   Default
-   Full

### 📖 Difference between policies

| Changes                           |       Basic        |                      Default                      |          Full           |
| :-------------------------------- | :----------------: | :-----------------------------------------------: | :---------------------: |
| Open previous session             |                    |                         X                         |            X            |
| Disable telemetry                 |         X          |                         X                         |            X            |
| Disable firefox studies           |         X          |                         X                         |            X            |
| Disable feedback commands         |         X          |                         X                         |            X            |
| Disable pocket                    |         X          |                         X                         |            X            |
| Disable extension recommendations |         X          |                         X                         |            X            |
| Disable feature recommendations   |         X          |                         X                         |            X            |
| Disable sponsored top sites       |         X          |                         X                         |            X            |
| Disable form history              |                    |                         X                         |            X            |
| Enable all tracking protection    |         X          |                         X                         |            X            |
| Disable Offer to save logins      |                    |                         x                         |            x            |
| Block requests for notifications  |         X          |                         X                         |            X            |
| Block audio and video autoplay    |                    |                         X                         |            X            |
| Ask for download location         |                    |                         X                         |            X            |
| Disable autofill address          |                    |                         X                         |            X            |
| Disable autofill creditcard       |                    |                         X                         |            X            |
| No default bookmarks              |         X          |                         X                         |            X            |
| HTTPS-Only Mode in all windows    |         X          |                         X                         |            X            |
| DNS over HTTPS using mullvad DNS  |         X          |                         X                         |            X            |
| Extensions                        | Ublock origin only | All privacy extensions, choose from optional ones | All extensions included |

### 📦 Installs basic extensions for privacy (can be removed anytime)

-   [uBlock Origin][5]
-   [Privacy Badger][6]
-   [CanvasBlocker][7]
-   [User-Agent Switcher and Manager][8]
-   [LocalCDN][9]
-   [ClearURLs][10]
-   [Skip Redirect][11]

### Optional extensions

#### Youtube

-   [Enhancer for YouTube][12]
-   [DeArrow][13]
-   [Return YouTube Dislike][14]
-   [SponsorBlock][15]

#### Steam

-   [Augmented Steam][16]
-   [ProtonDB for Steam][17]

#### Utilities

-   [Dark Reader][18]
-   [Save webP as PNG or JPEG (Converter)][19]

## 📂 Project breakdown

### Project structure

```bash
.
├── config
│   ├── firefox
│   │   ├── basic_policies.json
│   │   ├── full_policies.json
│   │   └── policies.json
│   ├── fish
│   │   ├── config_debian.fish
│   │   └── config.fish
│   └── vscode
│       ├── extensions.txt
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
├── docs
│   ├── images
│   │   └── preview.png
│   └── README.md
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

### Shared

Shared scripts between all distro setups, these include shell setup and program specific setups like installing hack nerd fonts, setting up scripts with plugin managers, neovim configurations, flatpaks, etc.

### Docs

Project documentation

[5]: https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/
[6]: https://addons.mozilla.org/en-US/firefox/addon/privacy-badger17/
[7]: https://addons.mozilla.org/en-US/firefox/addon/canvasblocker/
[8]: https://addons.mozilla.org/en-US/firefox/addon/user-agent-string-switcher/
[9]: https://addons.mozilla.org/en-US/firefox/addon/localcdn-fork-of-decentraleyes/
[10]: https://addons.mozilla.org/en-US/firefox/addon/clearurls/
[11]: https://addons.mozilla.org/en-US/firefox/addon/skip-redirect/
[12]: https://addons.mozilla.org/en-US/firefox/addon/enhancer-for-youtube/
[13]: https://addons.mozilla.org/en-US/firefox/addon/dearrow/
[14]: https://addons.mozilla.org/en-US/firefox/addon/return-youtube-dislikes/
[15]: https://addons.mozilla.org/en-US/firefox/addon/sponsorblock/
[16]: https://addons.mozilla.org/en-US/firefox/addon/augmented-steam/
[17]: https://addons.mozilla.org/en-US/firefox/addon/protondb-for-steam/
[18]: https://addons.mozilla.org/en-US/firefox/addon/darkreader/
[19]: https://addons.mozilla.org/en-US/firefox/addon/save-webp-as-png-or-jpeg/
