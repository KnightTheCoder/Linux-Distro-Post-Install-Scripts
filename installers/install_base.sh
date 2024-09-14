#!/usr/bin/env bash

branch="master"
arguments=""

if [ "$1" == "experimental" ]; then
    branch="maintanence"
fi

if [[ "$1" == "firefox" || "$2" == "firefox" ]]; then
    arguments="--copy-firefox-policy"
fi

wget -O "$(xdg-user-dir DOWNLOAD)/post-install-scripts.zip" "https://github.com/KnightTheCoder/Linux-Distro-Post-Install-Scripts/archive/refs/heads/${branch}.zip"
cd "$(xdg-user-dir DOWNLOAD)" && unzip post-install-scripts.zip && cd Linux-Distro-Post-Install-Scripts-${branch}
bash ./post_install.sh "${arguments}"