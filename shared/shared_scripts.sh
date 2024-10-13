#!/usr/bin/env bash

# Global colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

readonly DISTRO_RELEASE=/etc/os-release

#######################################
# Remove provided package from a list
# Arguments:
#   Package list, string
#   Package to remove
# Outputs:
#   Remaining packages
#######################################
function remove_package() {
    local package_list="$1"
    local package="$2"

    local result_package_list=${package_list//"$package"/}

    echo "$result_package_list"
}

#######################################
# Get distro icon based on distro
# Arguments:
#   None
# Outputs:
#   Distro's icon, otherwise default tux icon
#######################################
function get_current_distro_icon() {
    # Add icon based on distro
    local distro_icon=

    if grep -iq fedora "$DISTRO_RELEASE"; then
        distro_icon=
    fi

    if grep -iq opensuse "$DISTRO_RELEASE"; then
        distro_icon=
    fi

    if grep -iq arch "$DISTRO_RELEASE"; then
        distro_icon=
    fi

    if grep -iq debian "$DISTRO_RELEASE"; then
        if grep -iq ID=debian "$DISTRO_RELEASE"; then
            distro_icon=
        fi

        if grep -iq ID=ubuntu "$DISTRO_RELEASE"; then
            distro_icon=
        fi

        if grep -iq ID=linuxmint "$DISTRO_RELEASE"; then
            distro_icon=󰣭
        fi
    fi

    echo "$distro_icon"
}

#######################################
# Copy policies and install extensions for firefox
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   whiptail screen
#######################################
function setup_firefox() {
    echo -e "${GREEN}Setting up firefox...${NC}"

    local policy_filename="policies.json"
    local policy_template

    policy_template=$(
        whiptail --title "Firefox policy template" --notags --menu "Choose which firefox policy template you'd like to use" 0 0 0 \
            "none" "No policy" \
            "basic" "Basic policy" \
            "default" "Default policy" \
            "full" "Full policy" \
            3>&1 1>&2 2>&3
    )

    case $policy_template in

    none)
        return
        ;;

    basic)
        policy_filename="basic_policies.json"
        ;;

    full)
        policy_filename="full_policies.json"
        ;;

    esac

    local firefox_policy_directory=/etc/firefox/policies

    if [[ ! -f "${firefox_policy_directory}/policies.json" ]]; then
        sudo mkdir -p "${firefox_policy_directory}"
    fi

    sudo cp -fv config/firefox/${policy_filename} "${firefox_policy_directory}/policies.json"

    if [[ $policy_template == "default" ]]; then
        local extension_sets

        extension_sets=$(
            whiptail --title "Firefox extension sets" --separate-output --notags --checklist "Choose what set of extensions to install\nWill open the extension's page to install manually\nClose to progress install" 0 0 0 \
                "youtube" "Youtube" OFF \
                "steam" "Steam" OFF \
                "utilities" "Utilities" OFF \
                3>&1 1>&2 2>&3
        )

        # Remove new lines
        extension_sets=$(echo "$extension_sets" | tr "\n" " ")
        local extensions=()

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

        if ((${#extensions[@]} != 0)); then
            firefox "${extensions[@]}"
        fi

    fi
}

#######################################
# Download and run the itch desktop app installer
# Globals:
#   GREEN
#   YELLOW
#   NC
# Arguments:
#   None
# Outputs:
#   Log if already installed
#######################################
function setup_itch_app() {
    echo -e "${GREEN}Installing itch desktop app...${NC}"

    # Check if itch is installed
    if [[ -x ~/.itch/itch ]]; then
        echo -e "${YELLOW}Itch desktop app is already installed${NC}"
        return
    fi

    wget -O itch-setup "https://itch.io/app/download?platform=linux"
    chmod +x "./itch-setup"
    ./itch-setup
    rm -vf "./itch-setup"
}

#######################################
# Install vscode extensions, copy settings and copy keybindings
# Globals:
#   HOME
#   GREEN
#   YELLOW
#   RED
#   NC
# Arguments:
#   Code editor, either code or codium
# Outputs:
#   Log for which one is being installed
#   Log if code/codium is not installed
#######################################
function setup_vscode() {
    local code_editor=$1 # code or codium

    if [[ -z "$code_editor" ]]; then
        code_editor="code"
    fi

    if [[ ! -x "$(command -v "$code_editor")" ]]; then
        echo -e "${RED}${code_editor} is not installed!${NC}"
        return
    fi

    local vscode_config_directory=../../config/vscode

    if [[ -f "${vscode_config_directory}/extensions.txt" ]]; then

        whiptail --yesno "Would you like to install extensions from extensions.txt for VS${code_editor}?" 0 0

        local skip_extensions=$?
        if (("$skip_extensions" == 0)); then
            local extensions
            extensions=$(cat "${vscode_config_directory}/extensions.txt")

            echo -e "${GREEN}Installing extensions for VS${code_editor}...${NC}"

            # Install extensions
            for ext in $extensions; do
                $code_editor --force --install-extension "$ext"
            done
        else
            echo -e "${YELLOW}Skipping extensions for VS${code_editor}...${NC}"
        fi

    else
        echo -e "${YELLOW}extensions.txt not found!${NC}"
    fi

    local code_folder="Code"

    if [[ $code_editor == "codium" ]]; then
        code_folder="VSCodium"
    fi

    local vscode_user_directory
    vscode_user_directory="$HOME/.config/${code_folder}/User"

    mkdir -p "$vscode_user_directory"

    # Copy key bindings
    cp -fv "${vscode_config_directory}/keybindings.json" "$vscode_user_directory"

    # Copy settings
    cp -fv "${vscode_config_directory}/settings.json" "$vscode_user_directory"
}

#######################################
# Install Hack Nerd Fonts
# Globals:
#   GREEN
#   YELLOW
#   NC
# Arguments:
#   None
# Outputs:
#   Log if already installed
#######################################
function setup_hacknerd_fonts() {
    local hacknerdfont_directory=~/.local/share/fonts/hacknerdfonts

    if [[ -d "${hacknerdfont_directory}" ]]; then
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

#######################################
# Install blesh and add aliases
# Globals:
#   GREEN
#   YELLOW
#   NC
# Arguments:
#   None
# Outputs:
#   Log if already installed
#######################################
function setup_bash() {
    if [[ -d ~/.local/share/blesh ]]; then
        echo -e "${YELLOW}blesh is already setup${NC}"
        return
    fi

    echo -e "${GREEN}Installing blesh...${NC}"

    git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
    make -C ble.sh install PREFIX=~/.local
    # echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc

    local bat_fullname=bat

    if grep -iq debian "$DISTRO_RELEASE"; then
        bat_fullname=batcat
    fi

    {
        echo 'source ~/.local/share/blesh/ble.sh'
        echo "alias ls=\"eza\""
        echo "alias cat=\"$bat_fullname\""
    } >>~/.bashrc

    rm -rfv ./ble.sh
}

#######################################
# Install oh my fish and copy fish config
# Globals:
#   HOME
#   GREEN
#   YELLOW
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Log if already installed
#######################################
function setup_fish() {
    if [[ ! -x "$(command -v fish)" ]]; then
        echo -e "${RED}Fish is not installed!${NC}"
        return
    fi

    if [[ -d "$HOME/.local/share/omf" ]]; then
        echo -e "${YELLOW}Oh my fish is already installed${NC}"
    else
        echo -e "${YELLOW}Please run 'exit' to exit from fish and install the bobthefish theme${NC}"
        curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
        fish "../../shared/setup.fish"
    fi

    echo -e "${GREEN}Copying fish config...${NC}"

    local config_input=../../config/fish
    local config_output="$HOME/.config/fish/config.fish"

    # Need to use a different config for debian based systems because it's called batcat and not bat on them
    if grep -iq debian "$DISTRO_RELEASE"; then
        cp -fv "${config_input}/config_debian.fish" "${config_output}"
    else
        cp -fv "${config_input}/config.fish" "${config_output}"
    fi
}

#######################################
# Install prezto and add plugins and abbreviations
# Globals:
#   HOME
#   GREEN
#   YELLOW
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Log if already installed
#######################################
function setup_zsh() {
    if [[ ! -x "$(command -v zsh)" ]]; then
        echo -e "${RED}Zsh is not installed!${NC}"
        return
    fi

    if [[ -d "$HOME/.zprezto" ]]; then
        echo -e "${YELLOW}Prezto already setup!${NC}"
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

    local bat_fullname=bat

    if grep -iq debian "$DISTRO_RELEASE"; then
        bat_fullname=batcat
    fi

    printf "abbr cat=%s\nabbr ls=eza" $bat_fullname >"$HOME/.config/zsh-abbr/user-abbreviations"
}

#######################################
# Install starship prompt
# Globals:
#   YELLOW
#   NC
# Arguments:
#   None
# Outputs:
#   Log if already installed
#######################################
function setup_starship_install() {
    if [[ -x "$(command -v starship)" ]]; then
        echo -e "${YELLOW}Starship is already installed!${NC}"
    else
        curl -sS https://starship.rs/install.sh | sh
    fi
}

#######################################
# Setup starship prompt for bash, fish and zsh with custom distro icons
# Globals:
#   GREEN
#   YELLOW
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Log for starting step
#   Log if already installed
#######################################
function setup_starship() {
    echo -e "${GREEN}Setting up starship for shells...${NC}"

    if [[ ! -x "$(command -v starship)" ]]; then
        echo -e "${RED}Starship is not installed!${NC}"
        return
    fi

    local bash_config=~/.bashrc
    local fish_config=~/.config/fish/config.fish
    local zsh_config=~/.zshrc

    if [[ -x "$(command -v bash)" ]] && ! grep -iq starship $bash_config; then
        printf "\neval \"\$(starship init bash)\"" >>$bash_config
    fi

    if [[ -x "$(command -v fish)" ]] && ! grep -iq starship $fish_config; then
        printf "\nstarship init fish | source" >>$fish_config
    fi

    if [[ -x "$(command -v zsh)" ]] && ! grep -iq starship $zsh_config; then
        printf "\neval \"\$(starship init zsh)\"" >>$zsh_config
    fi

    local starship_config_file=~/.config/starship.toml

    if [[ -d "$starship_config_file" ]]; then
        echo -e "${YELLOW}Starship is already setup${NC}"
        return
    fi

    echo -e "${GREEN}Setting up starship configuration...${NC}"

    local distro_icon
    distro_icon=$(get_current_distro_icon)

    starship preset tokyo-night -o "${starship_config_file}"

    local starship_config_content
    starship_config_content=$(cat "${starship_config_file}")

    starship_config_content=${starship_config_content//${distro_icon}}

    echo "${starship_config_content}" >"${starship_config_file}"
}

#######################################
# Choose a neovim configuration
# Arguments:
#   None
# Outputs:
#   whiptail screen
#   Chosen neovim configuration
#######################################
function choose_nvim_config() {
    local nvim_config
    nvim_config=$(
        whiptail --notags --menu "Choose a neovim configuration (choose default to keep current)" 0 0 0 \
            "" "Default" \
            "nvchad" "NVChad" \
            "astronvim" "AstroNvim" \
            3>&1 1>&2 2>&3
    )

    if [[ -n "$nvim_config" ]]; then
        # Clean neovim config folder
        rm -rf ~/.config/nvim

        # Clean neovim folders
        rm -rf ~/.local/share/nvim
        rm -rf ~/.local/state/nvim
        rm -rf ~/.cache/nvim

        echo "$nvim_config"
    fi
}

#######################################
# Choose which shells to install and set up
# Arguments:
#   None
# Outputs:
#   whiptail screen
#   Chosen shells
#######################################
function choose_shells() {
    local shells
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

#######################################
# Setup NvChad for neovim
# Globals:
#   GREEN
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Log for starting step
#######################################
function setup_nvchad() {
    if [[ ! -x "$(command -v nvim)" ]]; then
        echo -e "${RED}neovim is not installed!${NC}"
        return
    fi

    echo -e "${GREEN}Setting up NVchad...${NC}"

    git clone https://github.com/NvChad/starter ~/.config/nvim && nvim
}

#######################################
# Setup AstroNvim for neovim
# Globals:
#   GREEN
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Log for starting step
#######################################
function setup_astronvim() {
    if [[ ! -x "$(command -v nvim)" ]]; then
        echo -e "${RED}neovim is not installed!${NC}"
        return
    fi

    echo -e "${GREEN}Setting up AstroNvim...${NC}"

    git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim

    # remove template's git connection to set up your own later
    rm -rf ~/.config/nvim/.git
    nvim
}

#######################################
# Install the latest npm and npm-check packages
# Globals:
#   GREEN
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Log for starting step
#   Log for npm not being installed
#######################################
function setup_npm() {
    if [[ ! -x "$(command -v npm)" ]]; then
        echo -e "${RED}npm is not installed!${NC}"
        return
    fi

    echo -e "${GREEN}Updating npm and installing npm-check...${NC}"

    sudo npm -g install npm npm-check
}

#######################################
# Install the latest rust toolchain
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Log for starting step
#######################################
function setup_rust() {
    if [[ -x "$(command -v fish)" ]]; then
        # Create fish directory for the script to run
        mkdir -pv ~/.config/fish/conf.d
    fi

    echo -e "${GREEN}Installing rust...${NC}"

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

#######################################
# Download and run xampp installer
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Log for starting step
#######################################
function setup_xampp() {
    echo -e "${GREEN}Installing xampp...${NC}"

    local xampp_executable=xampp-linux-installer.run

    wget -O "${xampp_executable}" https://sourceforge.net/projects/xampp/files/XAMPP%20Linux/8.2.12/xampp-linux-x64-8.2.12-0-installer.run/download
    chmod +x "./${xampp_executable}"
    sudo "./${xampp_executable}"
    rm -rv "./${xampp_executable}"
}

#######################################
# Install extension pack for virtualbox based on distro
# Globals:
#   GREEN
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Log for starting step
#   Log if virtualbox manager is not installed
#######################################
function setup_virtualbox_extension() {
    echo -e "${GREEN}Installing virtualbox extension pack...${NC}"

    local manage="vboxmanage"
    local extension_link="https://download.virtualbox.org/virtualbox/7.0.12/Oracle_VM_VirtualBox_Extension_Pack-7.0.12.vbox-extpack"

    if grep -iq arch "$DISTRO_RELEASE" || grep -iq fedora "$DISTRO_RELEASE"; then
        extension_link="https://download.virtualbox.org/virtualbox/7.1.0/Oracle_VirtualBox_Extension_Pack-7.1.0.vbox-extpack"
    fi

    if grep -iq opensuse "$DISTRO_RELEASE"; then
        manage="VBoxManage"
    fi

    if [[ ! -x "$(command -v ${manage})" ]]; then
        echo -e "${RED}Virtualbox manager is not installed!${NC}"
        return
    fi

    wget "$extension_link"
    sudo "${manage}" extpack install Oracle*.vbox-extpack
    rm -fv Oracle*.vbox-extpack
}

#######################################
# Select and install flatpak applications and remove default fedora repo
# Arguments:
#   None
# Outputs:
#   whiptail screen
#######################################
function setup_flatpak() {
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
            "org.mozilla.firefox" "Firefox web browser" OFF \
            "io.gitlab.librewolf-community" "Librewolf web browser" OFF \
            "one.ablaze.floorp" "Floorp web browser" OFF \
            "com.google.Chrome" "Google Chrome web browser" OFF \
            "com.brave.Browser" "Brave web browser" OFF \
            "com.vivaldi.Vivaldi" "Vivaldi web browser" OFF \
            "net.mullvad.MullvadBrowser" "Mullavad Browser" OFF \
            "org.libreoffice.LibreOffice" "Libreoffice" OFF \
            "org.onlyoffice.desktopeditors" "ONLYOFFICE Desktop Editors" OFF \
            "org.qbittorrent.qBittorrent" "qbittorrent bittorrent client" OFF \
            "com.transmissionbt.Transmission" "Transmission bittorrent client" OFF \
            3>&1 1>&2 2>&3
    )

    # Remove fedora remote if it exists
    if grep -iq fedora $DISTRO_RELEASE && flatpak remotes | grep -iq fedora; then
        sudo flatpak remote-delete fedora
    fi

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

export DISTRO_RELEASE
