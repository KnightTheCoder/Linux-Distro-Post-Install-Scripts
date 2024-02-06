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

# Check the package manager
get_package_manager() {
    if [ -x "/usr/bin/zypper" ]; then
     echo "zypper"
  elif [ -x "/usr/bin/dnf" ]; then
    echo "dnf"
  elif [ -x "/usr/bin/pacman" ]; then
    echo "pacman"
  elif [ -x "/usr/bin/apt" ]; then
    echo "apt"
  else
    echo "unknown"
  fi
}

package_manager=$(get_package_manager)

# check if whiptail is installed and install it
if [ ! -x "/usr/bin/whiptail" ]; then
  echo -e "${RED}whiptail is not installed! Please install newt to proceed!${NC}"

  case $package_manager in
    "zypper") sudo zypper -vv in -y newt;;
    "dnf") sudo dnf in -y newt;;
    "pacman") sudo pacman -S --noconfirm whiptail;;
    "apt") sudo apt install -y whiptail;;
    *) echo -e "${RED}Couldn't detect package manager!${NC}"
       exit 1;;
  esac

fi

whiptail --title "Linux Post-Install Script" --msgbox "Welcome to the post install script!\nFirst we'll need to gather some info about your system" 0 0

# Auto detect distro
if grep -iq opensuse /etc/os-release; then
  chosen_distro="1"
elif grep -iq fedora /etc/os-release; then
  chosen_distro="2"
elif grep -iq "arch linux" /etc/os-release; then
  chosen_distro="3"
elif grep -iq debian /etc/os-release; then
  chosen_distro="4"
else
  chosen_distro="-1"
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
if [[ $chosen_distro = "1" && $package_manager = "zypper" ]]; then
  echo -e "${GREEN}zypper found for OpenSUSE!${NC}"
  sh "./distros/opensuse/setup.sh"
elif [[ $chosen_distro = "2" && $package_manager = "dnf" ]]; then
  echo -e "${GREEN}dnf found for Fedora!${NC}"
  sh "./distros/fedora/setup.sh"
elif [[ $chosen_distro = "3" && $package_manager = "pacman" ]]; then
  echo -e "${GREEN}pacman found for Arch linux!${NC}"
  sh "./distros/arch/setup.sh"
elif [[ $chosen_distro = "4" && $package_manager = "apt" ]]; then
  echo -e "${GREEN}apt found for Debian!${NC}"
  sh "./distros/debian/setup.sh"
else
  echo -e "${RED}Can't continue! Mismatched package manager and distro!${NC}"
  exit 1
fi