#!/usr/bin/env bash

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