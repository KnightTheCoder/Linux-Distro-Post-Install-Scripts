#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

# shellcheck source=./shared/shared_scripts.sh
source "./shared/shared_scripts.sh"

function resolve_distro() {
  case $1 in
    "1") echo "OpenSUSE"
      ;;
    "2") echo "Fedora"
      ;;
    "3") echo "Arch linux"
      ;;
    "4") echo "Debian"
      ;;
    *) echo "Unknown"
      ;;
  esac
}

# Auto detect the package manager
function get_package_manager() {
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

if [ "$EUID" == 0 ]; then
  echo -e "${RED}Please run without root!${NC}"
  exit 1
fi

package_manager=$(get_package_manager)

# check if whiptail is installed and install it
if [ ! -x "/usr/bin/whiptail" ]; then
  echo -e "${RED}whiptail is not installed! Please install newt to proceed!${NC}"

  case $package_manager in
    "zypper") sudo zypper install --details -y newt
        ;;
    "dnf") sudo dnf install -y newt
        ;;
    "pacman") sudo pacman -S --noconfirm whiptail
        ;;
    "apt") sudo apt install -y whiptail
        ;;
    *) echo -e "${RED}Couldn't detect package manager!${NC}"
       exit 1
       ;;
  esac

fi

whiptail --title "Linux Post-Install Script" --msgbox "Welcome to the post install script!\nFirst we'll need to gather some info about your system" 0 0                                                  
# Auto detect distro
if grep -iq opensuse /etc/os-release; then
  chosen_distro="1"
elif grep -iq fedora /etc/os-release; then
  chosen_distro="2"
elif grep -iq "arch" /etc/os-release; then
  chosen_distro="3"
elif grep -iq debian /etc/os-release; then
  chosen_distro="4"
else
  chosen_distro="-1"
fi

echo -e "${GREEN}$(resolve_distro "$chosen_distro") and ${package_manager} detected!${NC}"

if [ "$chosen_distro" -gt -1 ]; then
  whiptail --title "Autodetection" --yesno "$(resolve_distro "$chosen_distro") detected with ${package_manager} as your package manager!\nIs this correct?" 0 0
  correct=$?
fi

if [ "$correct" != "0" ]; then
  chosen_distro=$(
    whiptail --title "Select distro" --notags --menu "Please select your distro" --ok-button "Select" 0 0 40 \
      "1" "OpenSUSE" \
      "2" "Fedora" \
      "3" "Arch linux" \
      "4" "Debian" \
      3>&2 2>&1 1>&3
  )

  if [ -z "$chosen_distro" ]; then
    echo -e "${RED}User canceled, Aborting...${NC}"
    exit
  fi
fi

echo -e "${GREEN}Your chosen distro is $(resolve_distro "$chosen_distro")${NC}"

if [[ $1 == "--copy-firefox-policy" ]]; then
  extension_sets=$(
    whiptail --title "Firefox extension sets" --separate-output --checklist "Choose what set of extensions to install" 0 0 0 \
    "basic" "Basic privacy" ON \
    "youtube" "Youtube" OFF \
    "steam" "Steam" OFF \
    "reader" "Dark reader" OFF \
    3>&1 1>&2 2>&3
  )

  # Remove new lines
  extension_sets=$(echo "$extension_sets"| tr "\n" " ")
  extensions=()

  for extension_set in $extension_sets; do
  
    sudo mkdir -pv "/etc/firefox/policies"
    sudo cp -fv "config/firefox/policies.json" "/etc/firefox/policies"

    case $extension_set in
      basic )
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4261710/ublock_origin-1.57.2.xpi")
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4232703/privacy_badger17-2024.2.6.xpi")
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4262820/canvasblocker-1.10.1.xpi")
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4098688/user_agent_string_switcher-0.5.0.xpi")
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4251866/localcdn_fork_of_decentraleyes-2.6.65.xpi")
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4064884/clearurls-1.26.1.xpi")
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/3920533/skip_redirect-2.3.6.xpi")
        ;;

      youtube )
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4325319/enhancer_for_youtube-2.0.126.xpi")
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4307344/dearrow-1.6.4.xpi")
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4342747/return_youtube_dislikes-3.0.0.17.xpi")
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4308094/sponsorblock-5.7.xpi")
        ;;

      steam )
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4264122/augmented_steam-3.1.1.xpi")
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4195217/protondb_for_steam-2.1.0.xpi")
        ;;

      reader )
        extensions+=("https://addons.mozilla.org/firefox/downloads/file/4341235/darkreader-4.9.89.xpi")
        ;;
    esac
  done

  firefox "${extensions[@]}"
fi

echo -e "${GREEN}Checking package manager and distro combination...${NC}"
if [[ $chosen_distro = "1" && $package_manager = "zypper" ]]; then
  echo -e "${GREEN}zypper found for OpenSUSE!${NC}"
  bash "./distros/opensuse/setup.sh"
elif [[ $chosen_distro = "2" && $package_manager = "dnf" ]]; then
  echo -e "${GREEN}dnf found for Fedora!${NC}"
  bash "./distros/fedora/setup.sh"
elif [[ $chosen_distro = "3" && $package_manager = "pacman" ]]; then
  echo -e "${GREEN}pacman found for Arch linux!${NC}"
  bash "./distros/arch/setup.sh"
elif [[ $chosen_distro = "4" && $package_manager = "apt" ]]; then
  echo -e "${GREEN}apt found for Debian!${NC}"
  bash "./distros/debian/setup.sh"
else
  echo -e "${RED}Can't continue! Mismatched package manager and distro!${NC}"
  echo -e "${RED}Chosen distro: $(resolve_distro "$chosen_distro")${NC}"
  echo -e "${RED}Detected package manager: $package_manager${NC}"
  whiptail --title "Mismatched!" --msgbox "Can't continue! Mismatched package manager and distro!\nChosen distro: $(resolve_distro "$chosen_distro")\nDetected package manager: $package_manager" 0 0
  exit 1
fi

# Set hostname
if hostname=$(whiptail --title "Hostname" --inputbox "Type in your hostname\nLeave empty to not change it" 0 0 3>&1 1>&2 2>&3); then
    # Check if hostname is not empty
    if [ -n "$hostname" ]; then
        sudo hostnamectl hostname "$hostname"
    fi
fi

echo -e "${YELLOW}Please reboot for flatpak's path and QEMU to work${NC}"
echo -e "${YELLOW}Please run 'gh auth login' to start using GitHub CLI${NC}"
echo -e "${GREEN}Post install complete, enjoy your new distro!${NC}"