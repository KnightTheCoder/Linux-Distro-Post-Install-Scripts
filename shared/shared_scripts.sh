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
        "vue.vscode-typescript-vue-plugin"
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

function setup_flatpak() {
    apps=(
        "io.missioncenter.MissionCenter"
        "com.github.tchx84.Flatseal"
        "net.davidotek.pupgui2"
        "com.obsproject.Studio"
        "com.github.unrud.VideoDownloader"
        "io.github.spacingbat3.webcord"
        "com.brave.Browser"
        "net.mullvad.MullvadBrowser"
    )

    # Setup flathub
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Install flatpaks
    flatpak install -y "${apps[@]}"
}

# Export reusable colors
export RED
export GREEN
export YELLOW
export NC