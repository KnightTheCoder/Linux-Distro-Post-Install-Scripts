#!/bin/bash
#
# Entry point for project

cd "$(dirname "$0")" || exit

# shellcheck source=./shared/shared_scripts.sh
source "./shared/shared_scripts.sh"

#######################################
# Turn distro tag into readable text form
# Arguments:
#   Distro tag
# Outputs:
#   Distro name in readable text form
#######################################
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

#######################################
# Auto detect package manager
# Arguments:
#   None
# Outputs:
#   Package manager's name
#######################################
function get_package_manager() {
  if [[ -x "$(command -v zypper)" ]]; then
    echo "zypper"
  elif [[ -x "$(command -v dnf)" ]]; then
    echo "dnf"
  elif [[ -x "$(command -v pacman)" ]]; then
    echo "pacman"
  elif [[ -x "$(command -v apt)" ]]; then
    echo "apt"
  else
    echo "unknown"
  fi
}

#######################################
# Returns setup execution path for the selected distro
# Arguments:
#   Distro tag
# Outputs:
#   Setup's path
#######################################
function get_execution_path() {
  local distro=$1

  echo "./distros/${distro}/setup.sh"
}

# Stop script from running with root
if [[ "$EUID" == 0 ]]; then
  echo -e "${RED}Please run without root!${NC}"
  exit 1
fi

#######################################
# Entry point for the project
# Arguments:
#   None
# Outputs:
#   Logs for steps performed
#   Logs if package manager not detected, mismatched distro and package manager
#   whiptail screen
#######################################
function main() {
  local package_manager
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

  local chosen_distro="unknown"
  # shellcheck disable=SC2154
  if grep -iq opensuse "$DISTRO_RELEASE"; then
    chosen_distro="opensuse"
  elif grep -iq fedora "$DISTRO_RELEASE"; then
    chosen_distro="fedora"
  elif grep -iq "arch" "$DISTRO_RELEASE"; then
    chosen_distro="arch"
  elif grep -iq debian "$DISTRO_RELEASE"; then
    chosen_distro="debian"
  fi

  local distro_fullname
  distro_fullname=$(resolve_distro "$chosen_distro")

  local distro_realname
  # shellcheck disable=SC1090
  distro_realname=$(. "$DISTRO_RELEASE" && echo "$NAME")

  echo -e "${GREEN}${distro_fullname} and ${package_manager} detected!${NC}"

  if [[ "$chosen_distro" != "unknown" ]]; then
    whiptail --title "Autodetection" --yesno "${distro_fullname} detected with ${package_manager} as your package manager!\nIs this correct?" 0 0
    local correct=$?
  else
    echo -e "${RED}Unknown distro detected!${NC}"

    # shellcheck disable=SC1090
    echo -e "${RED}Detected distro ${distro_realname} with ${package_manager}${NC}"

    correct=1
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
  echo -e "${GREEN}Your real distro is ${distro_realname}${NC}"
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

  setup_firefox

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
}

if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
  main "$@"
fi
