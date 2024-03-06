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
    local extensions=(
        "adpyke.codesnap"
        "adriano-markovic.c-cpp-makefile-project"
        "ardenivanov.svelte-intellisense"
        "bradlc.vscode-tailwindcss"
        "christian-kohler.path-intellisense"
        "codezombiech.gitignore"
        "csstools.postcss"
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
    )

    # Install extensions
    for ext in "${extensions[@]}"; do
        code --force --install-extension "$ext"
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
        echo -e "${YELLOW}Please run omf install bobthefish and exit from fish once it's done so the install can continue${NC}"
        curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
    fi

    echo -e "${GREEN}Copying fish config...${NC}"
    cp -fv "../../config/config.fish" "$HOME/.config/fish/config.fish"
}

function setup_nvchad() {
    git clone https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1 && nvim
}

function setup_astrovim() {
    # Make a backup of your current nvim folder
    mv ~/.config/nvim ~/.config/nvim.bak

    # Clean neovim folders
    mv ~/.local/share/nvim ~/.local/share/nvim.bak
    mv ~/.local/state/nvim ~/.local/state/nvim.bak
    mv ~/.cache/nvim ~/.cache/nvim.bak

    # Clone the repository
    git clone --depth 1 https://github.com/AstroNvim/AstroNvim "$HOME/.config/nvim"
    nvim
}

function setup_npm() {
    sudo npm -g install npm npm-check
}

function setup_rust() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

function setup_flatpak() {
    local extra_apps=("$@")

    local apps
    apps=$(
        whiptail --title "Flatpaks to install" --separate-output --checklist "Choose what to install for flatpak" 0 0 0 \
        "io.missioncenter.MissionCenter" "MissionCenter" ON \
        "com.github.tchx84.Flatseal" "Flatseal" ON \
        "net.davidotek.pupgui2" "ProtonUp-QT" OFF \
        "com.obsproject.Studio" "OBS Studio" OFF \
        "com.github.unrud.VideoDownloader" "Video Downloader" ON \
        "dev.vencord.Vesktop" "Vesktop" OFF \
        "com.google.Chrome" "Google Chrome" OFF \
        "com.brave.Browser" "Brave browser" OFF \
        "net.mullvad.MullvadBrowser" "Mullavad Browser" OFF \
        "com.dec05eba.gpu_screen_recorder" "GPU screen recoder" OFF \
        "org.qbittorrent.qBittorrent" "qbittorrent bittorrent client" OFF \
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