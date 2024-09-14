#!/usr/bin/env bash

read -p "Stable(default) or Experimental(e)?: " script_branch

read -p "Copy firefox policies?(y/n)" firefox_policy

branch="master"
additional_arguments=""

if [ "${script_branch}" == "e" ]; then
    branch="maintanence"
fi

if [ "${firefox_policy}" ]; then
    additional_arguments="--copy-firefox-policy"
fi

wget -O "$(xdg-user-dir DOWNLOAD)/post-install-scripts.zip" "https://github.com/KnightTheCoder/Linux-Distro-Post-Install-Scripts/archive/refs/heads/${branch}.zip"
cd "$(xdg-user-dir DOWNLOAD)" && unzip post-install-scripts.zip && cd Linux-Distro-Post-Install-Scripts-${branch}
bash ./post_install.sh ${additional_arguments}