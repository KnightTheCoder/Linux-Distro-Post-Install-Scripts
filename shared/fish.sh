#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

echo -e "${GREEN}Installing oh my fish!...${NC}"
if [ -d "$HOME/.local/share/omf" ]; then
    echo -e "${YELLOW}oh my fish is already installed!${NC}"
else
    echo -e "${YELLOW}Please run omf install bobthefish and exit from fish once it's done so the install can continue${NC}"
    curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
fi

echo -e "${GREEN}Copying fish config...${NC}"
cp -fv "../../config/config.fish" "$HOME/.config/fish/config.fish"