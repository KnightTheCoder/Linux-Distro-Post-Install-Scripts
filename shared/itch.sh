#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

wget -O itch-setup "https://itch.io/app/download?platform=linux"
chmod +x "./itch-setup"
./itch-setup
rm -vf "./itch-setup"