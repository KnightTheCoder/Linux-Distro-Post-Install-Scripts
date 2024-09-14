#!/usr/bin/env bash

rm -rf "$(xdg-user-dir DOWNLOAD)/post-install-scripts.zip" "$(xdg-user-dir DOWNLOAD)/Linux-Distro-Post-Install-Scripts-master"

wget -O "$(xdg-user-dir DOWNLOAD)/post-install-scripts.zip" "https://github.com/KnightTheCoder/Linux-Distro-Post-Install-Scripts/archive/refs/heads/master.zip"
cd "$(xdg-user-dir DOWNLOAD)" && unzip post-install-scripts.zip && cd Linux-Distro-Post-Install-Scripts-master
bash ./post_install.sh --copy-firefox-policy