#!/usr/bin/env bash

wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip
unzip ./Hack.zip -d Hack
mkdir -p "$HOME/.local/share/fonts/hacknerdfonts"
cp -fv ./Hack/*.ttf "$HOME/.local/share/fonts/hacknerdfonts"
fc-cache -fv
# Delete all fonts in the directory after caching
rm -rfv ./Hack Hack.zip