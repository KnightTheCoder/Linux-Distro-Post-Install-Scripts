#!/usr/bin/env bash

# Global colors 
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

# Install the itch desktop app
function setup_itch_app() {
    # Check if itch is installed
    if [ -x "$HOME/.itch/itch" ]; then
        echo -e "${YELLOW}Itch desktop app is already installed!${NC}"
        return
    fi

    wget -O itch-setup "https://itch.io/app/download?platform=linux"
    chmod +x "./itch-setup"
    ./itch-setup
    rm -vf "./itch-setup"
}

# Install vscode extensions and copy keybindings
function setup_vscode() {
    code_editor=$1 # code or codium

    if [ -z "$code_editor" ] || [ "$code_editor" == code ]; then
        code_editor="code"
    fi

    local extensions=(
        "adpyke.codesnap"
        "adriano-markovic.c-cpp-makefile-project"
        "ardenivanov.svelte-intellisense"
        "bradlc.vscode-tailwindcss"
        "christian-kohler.path-intellisense"
        "codezombiech.gitignore"
        "vunguyentuan.vscode-postcss"
        "dannyconnell.split-html-attributes"
        "dbaeumer.vscode-eslint"
        "eamodio.gitlens"
        "esbenp.prettier-vscode"
        "formulahendry.auto-close-tag"
        "formulahendry.auto-rename-tag"
        "formulahendry.code-runner"
        "github.github-vscode-theme"
        "github.vscode-github-actions"
        "github.vscode-pull-request-github"
        "mads-hartmann.bash-ide-vscode"
        "mhutchie.git-graph"
        "ms-vscode.cpptools"
        "ms-vscode.makefile-tools"
        "pkief.material-icon-theme"
        "rust-lang.rust-analyzer"
        "rvest.vs-code-prettier-eslint"
        "steoates.autoimport"
        "svelte.svelte-vscode"
        "tamasfe.even-better-toml"
        "timonwong.shellcheck"
        "ultram4rine.vscode-choosealicense"
        "usernamehw.errorlens"
        "vadimcn.vscode-lldb"
        "visualstudioexptteam.intellicode-api-usage-examples"
        "visualstudioexptteam.vscodeintellicode"
        "vue.volar"
        "zignd.html-css-class-completion"
        "ms-azuretools.vscode-docker"
        "ritwickdey.LiveServer"
    )

    # Install extensions
    for ext in "${extensions[@]}"; do
        $code_editor --force --install-extension "$ext"
    done

    # Copy key bindings
    cp -fv "../../config/keybindings.json" "$HOME/.config/Code/User"
}

function setup_hacknerd_fonts() {
    if [ -d "$HOME/.local/share/fonts/hacknerdfonts" ]; then
        echo -e "${YELLOW}Hack nerd fonts already installed!${NC}"
        return
    fi

    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip
    unzip ./Hack.zip -d Hack
    mkdir -p "$HOME/.local/share/fonts/hacknerdfonts"
    cp -fv ./Hack/*.ttf "$HOME/.local/share/fonts/hacknerdfonts"
    fc-cache -fv
    # Delete all fonts in the directory after caching
    rm -rfv ./Hack Hack.zip
}

# Install oh my fish and copy fish config
function setup_fish() {
    echo -e "${GREEN}Installing oh my fish!...${NC}"
    if [ -d "$HOME/.local/share/omf" ]; then
        echo -e "${YELLOW}oh my fish is already installed!${NC}"
    else
        echo -e "${YELLOW}Please run 'exit' to exit from fish and install the bobthefish theme${NC}"
        curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
        fish "../../shared/setup.fish"
    fi

    echo -e "${GREEN}Copying fish config...${NC}"

    # Need to use a different config for debian based systems because it's called batcat and not bat on them
    if grep -iq debian /etc/os-release; then
        cp -fv "../../config/fish/config_debian.fish" "$HOME/.config/fish/config.fish"
    else
        cp -fv "../../config/fish/config.fish" "$HOME/.config/fish/config.fish"
    fi
}

function setup_zsh() {
    if [ -d "$HOME/.zprezto" ]; then
        echo -e "${GREEN}prezto already setup${NC}"
        return
    fi

    # Add prezto as plugin manager
    git clone --depth 1 -b master --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"
    
    zsh "../../shared/setup.zsh"

    # Add zsh-abbr for fish-like abbreviations
    git clone --depth 1 -b main https://github.com/olets/zsh-abbr.git "$HOME/.zprezto/modules/zsh-abbr"

    # Add to the 40th line
    sed -i "40i 'autosuggestions' \\\\" "$HOME/.zpreztorc"
    sed -i "41i 'syntax-highlighting' \\\\" "$HOME/.zpreztorc"
    sed -i "42i 'zsh-abbr' \\\\" "$HOME/.zpreztorc"

    mkdir -p "$HOME/.config/zsh-abbr"

    bat_fullname=bat
    if grep -iq debian /etc/os-release; then
        bat_fullname=batcat
    fi
    printf "abbr cat=%s\nabbr ls=eza" $bat_fullname > "$HOME/.config/zsh-abbr/user-abbreviations"

    chsh -s /bin/zsh
}

function setup_starship_install() {
     if [[ ! -x "$(command -v starship)" ]]; then
        curl -sS https://starship.rs/install.sh | sh
    fi
}

function setup_starship() {
    if [[ ! -x "$(command -v starship)" ]]; then
        echo -e "${GREEN}Starship is already setup${NC}"
        return
    fi

    if [[ -x "$(command -v bash)" ]] && ! grep -iq starship "$HOME/.bashrc"; then
        printf "\neval \"\$(starship init bash)\"" | tee -a "$HOME/.bashrc"
    fi

    if [[ -x "$(command -v fish)" ]] && ! grep -iq starship "$HOME/.config/fish/config.fish"; then
        printf "\nstarship init fish | source" | tee -a "$HOME/.config/fish/config.fish"
    fi

    if [[ -x "$(command -v zsh)" ]] && ! grep -iq starship "$HOME/.zshrc"; then
        printf "\neval \"\$(starship init zsh)\"" | tee -a "$HOME/.zshrc"
    fi

    starship preset tokyo-night -o ~/.config/starship.toml
}

function choose_nvim_config() {
    # Since neovim versions are too old for either config to work, don't ask when using them
    if grep -iq debian /etc/os-release; then
        return
    fi

    nvim_config=$(whiptail --notags --menu "Choose a neovim configuration (choose nvchad if unsure)" 0 0 0 \
        "" "Default" \
        "nvchad" "NVChad" \
        "astrovim" "Astrovim" \
        3>&1 1>&2 2>&3
    )

    if [ -n "$nvim_config" ]; then
        # Clean neovim config folder
        rm -rf ~/.config/nvim

        # Clean neovim folders
        rm -rf ~/.local/share/nvim
        rm -rf ~/.local/state/nvim
        rm -rf ~/.cache/nvim 
        
        echo "$nvim_config"
    fi
}

function choose_shells() {
    shells=$(
        whiptail --title "Shells" --separate-output --checklist "Select the shells you'd like to install" 0 0 0 \
            "fish" "Fish shell" ON \
            "zsh" "zsh shell" OFF \
            "starship" "Starship prompt" ON \
            3>&1 1>&2 2>&3
    )

    echo "$shells"
}

function setup_nvchad() {
    git clone https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1 && nvim
}

function setup_astrovim() {
    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
    # remove template's git connection to set up your own later
    rm -rf ~/.config/nvim/.git
    nvim
}

function setup_npm() {
    sudo npm -g install npm npm-check
}

function setup_rust() {
    # Create fish directory for the script to run
    mkdir -p "$HOME/.config/fish/conf.d"

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

function setup_xampp() {
    wget -O xampp-linux-installer.run https://sourceforge.net/projects/xampp/files/XAMPP%20Linux/8.2.12/xampp-linux-x64-8.2.12-0-installer.run/download
    chmod +x ./xampp-linux-installer.run
    sudo ./xampp-linux-installer.run
    rm -rv ./xampp-linux-installer.run
}

function setup_flatpak() {
    local extra_apps=("$@")

    local apps
    apps=$(
        whiptail --title "Flatpaks to install" --separate-output --checklist "Choose what to install for flatpak" 0 0 0 \
        "io.missioncenter.MissionCenter" "MissionCenter" ON \
        "com.github.tchx84.Flatseal" "Flatseal" ON \
        "com.valvesoftware.Steam" "Steam" OFF \
        "io.itch.itch" "Itch desktop app" OFF \
        "com.heroicgameslauncher.hgl" "Heroic Games Launcher" OFF \
        "net.davidotek.pupgui2" "ProtonUp-QT" OFF \
        "com.obsproject.Studio" "OBS Studio" OFF \
        "com.dec05eba.gpu_screen_recorder" "GPU screen recoder" OFF \
        "io.podman_desktop.PodmanDesktop" "Podman Desktop" OFF \
        "com.github.unrud.VideoDownloader" "Video Downloader" ON \
        "org.gimp.GIMP" "GIMP" OFF \
        "org.kde.kdenlive" "Kdenlive" OFF \
        "org.keepassxc.KeePassXC" "KeePassXC" OFF \
        "com.discordapp.Discord" "Discord" OFF \
        "io.github.spacingbat3.webcord" "Webcord" OFF \
        "dev.vencord.Vesktop" "Vesktop" OFF \
        "de.shorsh.discord-screenaudio " "Discord-screenaudio" OFF \
        "io.gitlab.librewolf-community" "Librewolf" OFF \
        "one.ablaze.floorp" "Floorp" OFF \
        "com.google.Chrome" "Google Chrome" OFF \
        "com.brave.Browser" "Brave browser" OFF \
        "net.mullvad.MullvadBrowser" "Mullavad Browser" OFF \
        "org.libreoffice.LibreOffice" "Libreoffice" OFF \
        "org.onlyoffice.desktopeditors" "ONLYOFFICE Desktop Editors" OFF \
        "org.qbittorrent.qBittorrent" "qbittorrent bittorrent client" OFF \
        "com.transmissionbt.Transmission" "Transmission bittorrent client" OFF \
        3>&1 1>&2 2>&3
    )

    for app in "${extra_apps[@]}"; do
        apps+=" $app"
    done

    # Setup flathub
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Install flatpaks
    # shellcheck disable=SC2086
    flatpak install -y $apps
}

# Export reusable colors
export RED
export GREEN
export YELLOW
export NC