#!/usr/bin/env bash

# shellcheck source=./shared/colors.sh
source "./shared/colors.sh"

resolve_distro() {
  case $1 in
    "1") echo "OpenSUSE";;
    "2") echo "Fedora";;
    "3") echo "Arch linux";;
    "4") echo "Debian";;
    *) echo "Unknown";;
  esac
}

whiptail --title "Linux Post-Install Script" --msgbox "Welcome to the post install script!\nFirst we'll need to gather some info about your system" 0 0

if grep -iq opensuse /etc/os-release; then
  chosen_distro="1"
elif grep -iq fedora /etc/os-release; then
  chosen_distro="2"
elif grep -iq "arch linux" /etc/os-release; then
  chosen_distro="3"
elif grep -iq debian /etc/os-release; then
  chosen_distro="4"
fi

echo -e "${GREEN}$(resolve_distro "$chosen_distro") detected!${NC}"
whiptail --title "Autodetection" --yesno "$(resolve_distro "$chosen_distro") detected!\nIs this correct?" 0 0
correct=$?

if [ $correct != "0" ]; then
  chosen_distro=$(
    whiptail --title "Select distro" --menu "Please select your distro" --nocancel --ok-button "Select" 0 0 40 \
      "1" "OpenSUSE" \
      "2" "Fedora" \
      "3" "Arch linux" \
      "4" "Debian" 3>&2 2>&1 1>&3
  )
fi

echo -e "${GREEN}Your chosen distro is $(resolve_distro "$chosen_distro")${NC}"

echo -e "${GREEN}Checking package manager...${NC}"
if [[ $chosen_distro = "1" && -x "/usr/bin/zypper" ]]; then
  echo -e "${GREEN}zypper found for OpenSUSE!${NC}"
  sh "./distros/opensuse/setup.sh"
elif [[ $chosen_distro = "2" && -x "/usr/bin/dnf" ]]; then
  echo -e "${GREEN}dnf found for Fedora!${NC}"
  sh "./distros/fedora/setup.sh"
elif [[ $chosen_distro = "3" && -x "/usr/bin/pacman" ]]; then
  echo -e "${GREEN}pacman found for Arch linux!${NC}"
  sh "./distros/arch/setup.sh"
elif [[ $chosen_distro = "4" && -x "/usr/bin/apt" ]]; then
  echo -e "${GREEN}apt found for Debian!${NC}"
  sh "./distros/debian/setup.sh"
else
  echo -e "${RED}Can't continue! Mismatched package manager and distro!${NC}"
  exit 1
fi