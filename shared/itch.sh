#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# spellcheck source=../shared/colors.sh
source "../shared/colors.sh"

# Check if itch is installed
if [ -x "$HOME/.itch/itch" ]; then
    echo -e "${YELLOW}Itch desktop app is already installed!${NC}"
    exit
fi

wget -O itch-setup "https://itch.io/app/download?platform=linux"
chmod +x "./itch-setup"
./itch-setup
rm -vf "./itch-setup"