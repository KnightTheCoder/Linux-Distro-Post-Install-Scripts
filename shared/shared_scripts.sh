#!/usr/bin/env bash

# Global colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

readonly distro_release=/etc/os-release

function remove_package() {
    package_list="$1"
    package="$2"

    result_package_list=${package_list//"$package"/}

    echo "$result_package_list"
}

# Copy policies and install extensions for firefox
function setup_firefox() {
    echo -e "${GREEN}Setting up firefox...${NC}"

    extension_sets=$(
        whiptail --title "Firefox extension sets" --separate-output --notags --checklist "Choose what set of extensions to install\nWill open the extension's page to install manually\nClose to progress install" 0 0 0 \
            "youtube" "Youtube" OFF \
            "steam" "Steam" OFF \
            "utilities" "Utilities" OFF \
            3>&1 1>&2 2>&3
    )

    # Remove new lines
    extension_sets=$(echo "$extension_sets" | tr "\n" " ")
    extensions=()

    firefox_policy_directory=/etc/firefox/policies

    if [ ! -f "${firefox_policy_directory}/policies.json" ]; then
        sudo mkdir -pv "${firefox_policy_directory}"
        sudo cp -fv config/firefox/policies.json "${firefox_policy_directory}"
    fi

    for extension_set in $extension_sets; do

        case $extension_set in
        youtube)
            extensions+=("https://addons.mozilla.org/en-US/firefox/addon/enhancer-for-youtube/")
            extensions+=("https://addons.mozilla.org/en-US/firefox/addon/dearrow/")
            extensions+=("https://addons.mozilla.org/en-US/firefox/addon/return-youtube-dislikes/")
            extensions+=("https://addons.mozilla.org/en-US/firefox/addon/sponsorblock/")
            ;;

        steam)
            extensions+=("https://addons.mozilla.org/en-US/firefox/addon/augmented-steam/")
            extensions+=("https://addons.mozilla.org/en-US/firefox/addon/protondb-for-steam/")
            ;;

        utilities)
            extensions+=("https://addons.mozilla.org/en-US/firefox/addon/darkreader/")
            extensions+=("https://addons.mozilla.org/en-US/firefox/addon/save-webp-as-png-or-jpeg/")
            ;;
        esac

    done

    if [ ${#extensions[@]} -ne 0 ]; then
        firefox "${extensions[@]}"
    fi
}

# Install the itch desktop app
function setup_itch_app() {
    echo -e "${GREEN}Installing itch desktop app...${NC}"

    # Check if itch is installed
    if [ -x "$HOME/.itch/itch" ]; then
        echo -e "${YELLOW}Itch desktop app is already installed${NC}"
        return
    fi

    wget -O itch-setup "https://itch.io/app/download?platform=linux"
    chmod +x "./itch-setup"
    ./itch-setup
    rm -vf "./itch-setup"
}

# Install vscode extensions and copy keybindings
function setup_vscode() {
    local code_editor=$1 # code or codium

    if [ -z "$code_editor" ] || [ "$code_editor" == code ]; then
        code_editor="code"
    fi

    echo -e "${GREEN}Installing extensions for VS${code_editor}...${NC}"

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
        "foxundermoon.shell-format"
        "ultram4rine.vscode-choosealicense"
        "usernamehw.errorlens"
        "vadimcn.vscode-lldb"
        "vue.volar"
        "burkeholland.simple-react-snippets"
        "Angular.ng-template"
        "zignd.html-css-class-completion"
        "ms-azuretools.vscode-docker"
        "ritwickdey.LiveServer"
        "WallabyJs.quokka-vscode"
        "YoavBls.pretty-ts-errors"
        "nrwl.angular-console"
    )

    # Install extensions
    for ext in "${extensions[@]}"; do
        $code_editor --force --install-extension "$ext"
    done

    local code_folder="Code"
    if [[ $code_editor = "codium" ]]; then
        code_folder="VSCodium"
    fi

    # Copy key bindings
    cp -fv "../../config/vscode/keybindings.json" "$HOME/.config/${code_folder}/User"

    # Copy settings
    cp -fv "../../config/vscode/settings.json" "$HOME/.config/${code_folder}/User"
}

function setup_hacknerd_fonts() {
    hacknerdfont_directory="$HOME/.local/share/fonts/hacknerdfonts"

    if [ -d "${hacknerdfont_directory}" ]; then
        echo -e "${YELLOW}Hack nerd fonts are already installed${NC}"
        return
    fi

    echo -e "${GREEN}Installing hack nerd fonts...${NC}"

    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.zip
    unzip ./Hack.zip -d Hack
    mkdir -p "${hacknerdfont_directory}"
    cp -fv ./Hack/*.ttf "${hacknerdfont_directory}"
    fc-cache -fv
    # Delete all fonts in the directory after caching
    rm -rfv ./Hack Hack.zip
}

# Install blesh and add aliases
function setup_bash() {
    if [ -d ~/.local/share/blesh ]; then
        echo -e "${YELLOW}blesh is already setup${NC}"
        return
    fi

    echo -e "${GREEN}Installing blesh...${NC}"

    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
    make -C ble.sh install PREFIX=~/.local
    # echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc

    bat_fullname=bat
    if grep -iq debian "$distro_release"; then
        bat_fullname=batcat
    fi

    {
        echo 'source ~/.local/share/blesh/ble.sh'
        echo "alias ls=\"eza\""
        echo "alias cat=\"$bat_fullname\""
    } >>~/.bashrc

    rm -rfv ./ble.sh
}

# Install oh my fish and copy fish config
function setup_fish() {
    if [ -d "$HOME/.local/share/omf" ]; then
        echo -e "${YELLOW}oh my fish is already installed${NC}"
    else
        echo -e "${YELLOW}Please run 'exit' to exit from fish and install the bobthefish theme${NC}"
        curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
        fish "../../shared/setup.fish"
    fi

    echo -e "${GREEN}Copying fish config...${NC}"

    config_input=../../config/fish
    config_output="$HOME/.config/fish/config.fish"

    # Need to use a different config for debian based systems because it's called batcat and not bat on them
    if grep -iq debian "$distro_release"; then
        cp -fv "${config_input}/config_debian.fish" "${config_output}"
    else
        cp -fv "${config_input}/config.fish" "${config_output}"
    fi
}

# Install prezto and add plugins and abbreviations
function setup_zsh() {
    if [ -d "$HOME/.zprezto" ]; then
        echo -e "${GREEN}prezto already setup!  ${NC}"
        return
    fi

    echo -e "${GREEN}Installing prezto...${NC}"

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
    if grep -iq debian "$distro_release"; then
        bat_fullname=batcat
    fi
    printf "abbr cat=%s\nabbr ls=eza" $bat_fullname >"$HOME/.config/zsh-abbr/user-abbreviations"

    echo -e "${GREEN}Changing login shell for ${USER}...${NC}"
    chsh -s /bin/zsh
}

function setup_starship_install() {
    if [[ ! -x "$(command -v starship)" ]]; then
        curl -sS https://starship.rs/install.sh | sh
    fi
}

function setup_starship() {
    if [[ -x "$(command -v bash)" ]] && ! grep -iq starship "$HOME/.bashrc"; then
        printf "\neval \"\$(starship init bash)\"" | tee -a "$HOME/.bashrc"
    fi

    if [[ -x "$(command -v fish)" ]] && ! grep -iq starship "$HOME/.config/fish/config.fish"; then
        printf "\nstarship init fish | source" | tee -a "$HOME/.config/fish/config.fish"
    fi

    if [[ -x "$(command -v zsh)" ]] && ! grep -iq starship "$HOME/.zshrc"; then
        printf "\neval \"\$(starship init zsh)\"" | tee -a "$HOME/.zshrc"
    fi

    starship_config_file=~/.config/starship.toml

    if [[ -d "$starship_config_file" ]]; then
        echo -e "${YELLOW}Starship is already setup${NC}"
        return
    fi

    # Add icon based on distro
    distro_icon=

    if grep -iq fedora "$distro_release"; then
        distro_icon=
    fi

    if grep -iq opensuse "$distro_release"; then
        distro_icon=
    fi

    if grep -iq arch "$distro_release"; then
        distro_icon=
    fi

    if grep -iq debian "$distro_release"; then
        if grep -iq ID=debian "$distro_release"; then
            distro_icon=
        fi

        if grep -iq ID=ubuntu "$distro_release"; then
            distro_icon=
        fi

        if grep -iq ID=linuxmint "$distro_release"; then
            distro_icon=󰣭
        fi
    fi

    starship preset tokyo-night -o "${starship_config_file}"

    starship_config_content=$(cat "${starship_config_file}")

    starship_config_content=${starship_config_content//${distro_icon}}

    echo "${starship_config_content}" >"${starship_config_file}"
}

function choose_nvim_config() {
    # Since neovim versions are too old for either config to work, don't ask when using them
    if grep -iq debian /etc/os-release; then
        return
    fi

    nvim_config=$(
        whiptail --notags --menu "Choose a neovim configuration (choose nvchad if unsure)" 0 0 0 \
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
        whiptail --title "Shells" --separate-output --notags --checklist "Select the shells you'd like to install" 0 0 0 \
            "bash" "Bash shell" ON \
            "fish" "Fish shell" ON \
            "zsh" "zsh shell" OFF \
            "starship" "Starship prompt" ON \
            3>&1 1>&2 2>&3
    )

    echo "$shells"
}

function setup_nvchad() {
    echo -e "${GREEN}Setting up NVchad...${NC}"

    git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
}

function setup_astrovim() {
    echo -e "${GREEN}Setting up astrovim...${NC}"

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
    xampp_executable=xampp-linux-installer.run

    wget -O "${xampp_executable}" https://sourceforge.net/projects/xampp/files/XAMPP%20Linux/8.2.12/xampp-linux-x64-8.2.12-0-installer.run/download
    chmod +x "./${xampp_executable}"
    sudo "./${xampp_executable}"
    rm -rv "./${xampp_executable}"
}

function setup_virtualbox_extension() {
    echo -e "${GREEN}Installing virtualbox extension pack...${NC}"

    manage="vboxmanage"
    extension_link="https://download.virtualbox.org/virtualbox/7.0.12/Oracle_VM_VirtualBox_Extension_Pack-7.0.12.vbox-extpack"

    if grep -iq arch "$distro_release" || grep -iq fedora "$distro_release"; then
        extension_link="https://download.virtualbox.org/virtualbox/7.1.0/Oracle_VirtualBox_Extension_Pack-7.1.0.vbox-extpack"
    fi

    if grep -iq opensuse "$distro_release"; then
        manage="VBoxManage"
    fi

    wget "$extension_link"
    sudo "${manage}" extpack install Oracle*.vbox-extpack
    rm -fv Oracle*.vbox-extpack
}

function setup_flatpak() {
    local extra_apps=("$@")

    local apps
    apps=$(
        whiptail --title "Flatpaks to install" --separate-output --notags --checklist "Choose what to install for flatpak" 0 0 0 \
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

export distro_release
