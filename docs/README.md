# Welcome to the Linux Post install documentation

## 📃 Steps the script runs:
* Find package manager
* Check for whiptail and install it if it's not found
* Find Distro, ask if distro is correct, if distro and package manager don't match stop script
* Start distro specific script
* Select programs/tools to install
* Add list of recommended packages (bat, eza, git, etc.)
* Select shells to setup
* Select neovim configuration
* Break down programs/tools into setup steps (packages, services, usergroups, setups, etc.)
* Distro specific setup (add repos, install codecs, etc.)
* Add user to usergroups listed before
* Run setups for selected apps
* Start listed services
* Ask for hostname (optional)

## 🌐 Firefox policy (optional)
A firefox policy is included for increased privacy.

> [!NOTE]
> Can be found at ``config/firefox/policies.json`` <br />
> Manually edit to customize, then copy to ``/etc/firefox/policies/`` for it to work

### 📖 Included policy has the following changes
* Disable telemetry
* Disable firefox studies
* Disable pocket
* Disable form history
* Disable feedback commands
* Enable all tracking protection
* Don't offer to save logins
* Block requests for notifications
* Block audio and video autoplay
* Disable picture in picture
* Always ask for download location
* Disable autofill address
* Disable autofill creditcard
* No default bookmarks (only works if you copied the policies.json before opening firefox for the first time)

## 🌐 Firefox policy
A firefox policy is included for increased privacy.

> [!NOTE]
> The policy is applied automatically when running the script with --copy-firefox-policy <br />
> Can be found at ``config/firefox/policies.json`` <br />
> Manually edit to customize, then copy to ``/etc/firefox/policies/`` for it to work

### 📖 Included policy has the following changes
* Disable telemetry
* Disable firefox studies
* Disable pocket
* Disable form history
* Disable feedback commands
* Enable all tracking protection
* Don't offer to save logins
* Block requests for notifications
* Block audio and video autoplay
* Disable picture in picture
* Always ask for download location
* Disable autofill address
* Disable autofill creditcard
* No default bookmarks (only works if you copied the policies.json before opening firefox for the first time)

### 📦 Installs basic extensions for privacy (can be removed anytime)
* [uBlock Origin][5]
* [Privacy Badger][6]
* [CanvasBlocker][7]
* [User-Agent Switcher and Manager][8]
* [LocalCDN][9]
* [ClearURLs][10]
* [Skip Redirect][11]

### Optional extensions

#### Youtube
* [Enhancer for YouTube][12]
* [DeArrow][13]
* [Return YouTube Dislike][14]
* [SponsorBlock][15]

#### Steam
* [Augmented Steam][16]
* [ProtonDB for Steam][17]

#### Utilities
* [Dark Reader][18]
* [Save webP as PNG or JPEG (Converter)][19]


## 📂 Project breakdown

### Project structure
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
├── images
│   └── preview.png
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

### Optional extensions

#### Youtube
* [Enhancer for YouTube][12]
* [DeArrow][13]
* [Return YouTube Dislike][14]
* [SponsorBlock][15]

#### Steam
* [Augmented Steam][16]
* [ProtonDB for Steam][17]

#### Utilities
* [Dark Reader][18]
* [Save webP as PNG or JPEG (Converter)][19]


## 📂 Project breakdown

### Project structure
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
├── images
│   └── preview.png
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