#!/bin/bash

cd "$(dirname "$0")" || exit

# shellcheck source=./functions.sh
source "./functions.sh"

#######################################
# Entry point for fedora's setup
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

    packages+=" vim neovim eza bat curl wget cabextract xorg-x11-font-utils fontconfig p7zip p7zip-plugins unrar git dnf-plugins-core ffmpeg-libs libva libva-utils openh264 gstreamer1-plugin-openh264 mozilla-openh264 \*appstream-data"

    local shells
    shells=$(choose_shells)

    packages="$shells $cli_packages $packages"

    # Remove new lines
    packages=$(echo "$packages" | tr "\n" " ")

    # Add defaults
    local services=()
    local setups=(hacknerd)
    local usergroups=()
    local groups=(c-development multimedia sound-and-video)
    local packages_to_remove="anaconda\* akregator dragon elisa-player kaddressbook kmahjongg kmail kontact kmines konversation kmouth korganizer kpat kolourpaint qt5-qdbusviewer pim-sieve-editor neochat rhythmbox"

    # Install NVIDIA drivers
    local drivers
    drivers=$(get_nvidia_drivers)

    packages+=" $drivers"

    local nvim_config
    nvim_config=$(choose_nvim_config)
    setups+=("$nvim_config")

    handle_packages packages services setups usergroups groups

    # Remove extra whitespace
    packages=$(echo "$packages" | xargs)

    get_remove_discover packages_to_remove

    modify_configurations

    add_rpm_fusion_repos

    add_terra_repos

    # Install dnf5 if it's an older system
    sudo dnf install -y dnf5 dnf5-plugins

    # Update system
    sudo dnf5 upgrade -y --refresh

    # Remove unneccessary packages
    # shellcheck disable=SC2086
    sudo dnf5 remove -y $packages_to_remove

    # Install groups
    sudo dnf4 group install -y "${groups[@]}" --allowerasing

    swap_free_to_rpm_fusion_packages

    # Install packages
    # shellcheck disable=SC2086
    sudo dnf5 install -y $packages

    install_ms_core_fonts

    add_user_to_groups "${usergroups[@]}"

    handle_setups setups

    start_systemd_services "${services[@]}"

    perform_post_script_actions
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    main
fi
