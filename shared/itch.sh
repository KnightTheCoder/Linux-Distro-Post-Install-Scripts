#!/usr/bin/env bash

wget -O itch-setup "https://itch.io/app/download?platform=linux"
chmod +x "./itch-setup"
./itch-setup
rm -vf "./itch-setup"