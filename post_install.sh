#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=./shared/shared_scripts.sh
source "./shared/shared_scripts.sh"

function resolve_distro() {
  case $1 in
  "opensuse")
    echo "OpenSUSE"
    ;;
  "fedora")
    echo "Fedora"
    ;;
  "arch")
    echo "Arch linux"
    ;;
  "debian")
    echo "Debian"
    ;;
  *)
    echo "Unknown"
    ;;
  esac
}

# Auto detect the package manager
function get_package_manager() {
  if [[ -x "/usr/bin/zypper" ]]; then
    echo "zypper"
  elif [[ -x "/usr/bin/dnf" ]]; then
    echo "dnf"
  elif [[ -x "/usr/bin/pacman" ]]; then
    echo "pacman"
  elif [[ -x "/usr/bin/apt" ]]; then
    echo "apt"
  else
    echo "unknown"
  fi
}

function get_execution_path() {
  local distro=$1

  echo "./distros/${distro}/setup.sh"
}

if [[ "$EUID" == 0 ]]; then
  echo -e "${RED}Please run without root!${NC}"
  exit 1
fi

package_manager=$(get_package_manager)

# check if whiptail is installed and install it
if [[ ! -x "/usr/bin/whiptail" ]]; then
  echo -e "${RED}whiptail is not installed! Please install newt to proceed!${NC}"

  case $package_manager in
  "zypper")
    sudo zypper install --details -y newt
    ;;
  "dnf")
    sudo dnf install -y newt
    ;;
  "pacman")
    sudo pacman -S --noconfirm whiptail
    ;;
  "apt")
    sudo apt install -y whiptail
    ;;
  *)
    echo -e "${RED}Couldn't detect package manager!${NC}"
    exit 1
    ;;
  esac

fi

whiptail --title "Linux Post-Install Script" --msgbox "Welcome to the post install script!\nFirst we'll need to gather some info about your system" 0 0
# Auto detect distro

# shellcheck disable=SC2154
if grep -iq opensuse "$distro_release"; then
  chosen_distro="opensuse"
elif grep -iq fedora "$distro_release"; then
  chosen_distro="fedora"
elif grep -iq "arch" "$distro_release"; then
  chosen_distro="arch"
elif grep -iq debian "$distro_release"; then
  chosen_distro="debian"
else
  chosen_distro="unknown"
fi

distro_fullname=$(resolve_distro "$chosen_distro")

echo -e "${GREEN}${distro_fullname} and ${package_manager} detected!${NC}"

if [[ "$chosen_distro" != "unknown" ]]; then
  whiptail --title "Autodetection" --yesno "${distro_fullname} detected with ${package_manager} as your package manager!\nIs this correct?" 0 0
  correct=$?
else
  echo -e "${RED}Unknown distro detected!${NC}"
  
  # shellcheck disable=SC1090
  echo -e "${RED}Detected distro: $(. "$distro_release" && echo "$NAME")${NC}"

  # shellcheck disable=SC1090
  whiptail --title "Unknown distro" --msgbox "Can't continue!\nUnknown distro detected!\nDistro: $(. "$distro_release" && echo "$NAME")\nPackage manager: ${package_manager}" 0 0
  exit 1
fi

if [[ "$correct" != "0" ]]; then
  chosen_distro=$(
    whiptail --title "Select distro" --notags --menu "Please select your distro" --ok-button "Select" 0 0 40 \
      "1" "OpenSUSE" \
      "2" "Fedora" \
      "3" "Arch linux" \
      "4" "Debian" \
      3>&2 2>&1 1>&3
  )

  if [[ -z "$chosen_distro" ]]; then
    echo -e "${RED}User canceled, Aborting...${NC}"
    exit
  fi
fi

echo -e "${GREEN}Your chosen distro is ${distro_fullname}${NC}"

if [[ $1 == "--copy-firefox-policy" ]]; then
  setup_firefox
fi

echo -e "${GREEN}Checking package manager and distro combination...${NC}"

if [[ $chosen_distro = "opensuse" && $package_manager = "zypper" ]]; then
  :
elif [[ $chosen_distro = "fedora" && $package_manager = "dnf" ]]; then
  :
elif [[ $chosen_distro = "arch" && $package_manager = "pacman" ]]; then
  :
elif [[ $chosen_distro = "debian" && $package_manager = "apt" ]]; then
  :
else
  echo -e "${RED}Can't continue! Mismatched package manager and distro!${NC}"
  echo -e "${RED}Chosen distro: ${distro_fullname}${NC}"
  echo -e "${RED}Detected package manager: $package_manager${NC}"
  whiptail --title "Mismatched!" --msgbox "Can't continue! Mismatched package manager and distro!\nChosen distro: ${distro_fullname}\nDetected package manager: $package_manager" 0 0
  exit 1
fi

echo -e "${GREEN}${package_manager} found for ${distro_fullname}!${NC}"
bash "$(get_execution_path "$chosen_distro")"

# Set hostname
if hostname=$(whiptail --title "Hostname" --inputbox "Type in your hostname\nLeave empty to not change it" 0 0 3>&1 1>&2 2>&3); then
  # Check if hostname is not empty
  if [[ -n "$hostname" ]]; then
    sudo hostnamectl hostname "$hostname"
  fi
fi

echo -e "${YELLOW}Please reboot for flatpak's path and QEMU to work${NC}"
echo -e "${YELLOW}Please run 'gh auth login' to start using GitHub CLI${NC}"
echo -e "${GREEN}Post install complete, enjoy your new distro!${NC}"
