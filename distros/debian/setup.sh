#!/bin/bash

cd "$(dirname "$0")" || exit

# shellcheck source=./functions.sh
source "./functions.sh"

#######################################
# Entry point for debian's setup
# Globals:
#   GREEN
#   YELLOW
#   NC
# Arguments:
#   None
# Outputs:
#   Logs for steps performed
#   whiptail screen
#######################################
function main() {
    local packages
    packages=$(get_main_packages)

    local cli_packages
    cli_packages=$(get_cli_packages)

    packages+=" git build-essential neovim bat curl wget gpg ttf-mscorefonts-installer fontconfig p7zip p7zip-rar unrar rar"

    local shells
    shells=$(choose_shells)

    if [[ $shells == *"starship"* ]]; then
        shells="starship-install $shells"
    fi

    packages="$shells $cli_packages $packages"

    # Remove new lines
    packages=$(echo "$packages" | tr "\n" " ")

    # Add defaults
    local services=()
    local setups=(hacknerd eza)
    local usergroups=()
    local snaps=()
    local packages_to_remove="elisa dragonplayer akregator kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat kolourpaint thunderbird konqueror rhythmbox"

    local drivers
    drivers=$(get_nvidia_drivers setups)

    packages+=" $drivers"

    handle_packages packages services setups usergroups snaps

    # Remove extra whitespace
    packages=$(echo "$packages" | xargs)

    get_remove_discover packages_to_remove

    perform_distro_setups

    add_32bit_support

    sudo apt update

    # Update system
    sudo apt upgrade -y

    # Update snaps
    if [[ -x "$(command -v snap)" ]]; then
        sudo snap refresh
    fi

    # Remove unnecessary packages
    # shellcheck disable=SC2086
    sudo apt remove -y $packages_to_remove

    # Install packages

    # shellcheck disable=SC2086
    sudo apt install -y $packages

    install_snaps "${snaps[@]}"

    add_user_to_groups "${usergroups[@]}"

    handle_setups setups

    start_systemd_services "${services[@]}"

    perform_post_script_actions
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    main
fi
