#!/usr/bin/env bash

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
RESET='\033[0m'

create_spinner() {
  text="$1"
  spinner_chars=('' '' '' '' '' '')
  i=0
  while true; do
    printf "\r$CYAN${spinner_chars[i]} $text$RESET"
    sleep 0.1
    ((i=(i+1)%6))
  done &
  spinner_pid=$!
}

stop_spinner() {
  kill $spinner_pid 2>/dev/null
  wait $spinner_pid 2>/dev/null
  printf "\r$RESET"
}

check_package() {
  create_spinner "${YELLOW}Checking for required packages...${RESET}"
  local cmds=(jq chafa curl)

  for pm in pkg apt pacman dnf apk zypper brew; do
    if command -v $pm &>/dev/null; then
      case $pm in
        pkg)    INSTALL="pkg install -y" ;;
        apt)    INSTALL="sudo apt install -y" ;;
        pacman) INSTALL="sudo pacman -Sy --noconfirm" ;;
        dnf)    INSTALL="sudo dnf install -y" ;;
        apk)    INSTALL="sudo apk add" ;;
        zypper) INSTALL="sudo zypper install -y" ;;
        brew)   INSTALL="brew install" ;;
      esac
      break
    fi
  done
  stop_spinner

  [[ -z "$INSTALL" ]] && echo -e "${RED}No supported package manager found.${RESET}" && exit 1

  for cmd in "${cmds[@]}"; do
    if command -v "$cmd" &>/dev/null; then
      echo -e "${GREEN}$cmd is already installed.${RESET}"
    else
      create_spinner "${YELLOW}Installing $cmd...${RESET}"
      if $INSTALL "$cmd" &>/dev/null; then
        stop_spinner
        echo -e "${GREEN}$cmd installed successfully.${RESET}"
      else
        stop_spinner
        echo -e "${RED}Failed to install $cmd.${RESET}"
        exit 1
      fi
    fi
  done
}

fetch_instagram_profile() {
  username="$1"
  skip_image="$2"
  check_package &> /dev/null

  create_spinner "Fetching profile information for @$username..."

  response=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
    -H "x-ig-app-id: 936619743392459" \
    "https://i.instagram.com/api/v1/users/web_profile_info/?username=$username")

  stop_spinner

  data=$(echo "$response" | jq '.data')
  if [ "$data" == "null" ] || [ -z "$data" ]; then
    echo -e "$RED❌ Error: User data not found in API response.$RESET"
    return 1
  fi

  u=$(echo "$data" | jq '.user')
  if [ "$u" == "null" ] || [ -z "$u" ]; then
    echo -e "$RED❌ Error: User not found or profile is private.$RESET"
    return 1
  fi

  if [ "$skip_image" != "true" ]; then
    pic_url=$(echo "$u" | jq -r '.profile_pic_url_hd // empty')
    if [ -n "$pic_url" ]; then
      curl -s -o thisImage.png "$pic_url"
      chafa thisImage.png
      rm -f thisImage.png
    else
      echo -e "${YELLOW}No profile picture found.${RESET}"
    fi
  else
    echo -e "${YELLOW}Skipping profile picture download.${RESET}"
  fi

  echo
  echo -e "${GREEN}Profile information for 󰋾 @$username:${RESET}"
  echo -e "${RESET}User ID: $PURPLE$(echo "$u" | jq -r '.id // "N/A"')"
  echo -e "${RESET}Full Name: $GREEN$(echo "$u" | jq -r '.full_name // "N/A"')"
  echo -e "${RESET}Username: $GREEN$(echo "$u" | jq -r '.username // "N/A"')"
  echo -e "${RESET}Biography: $BLUE$(echo "$u" | jq -r '.biography // "N/A"')"
  echo -e "${RESET}Followers: $YELLOW$(echo "$u" | jq -r '.edge_followed_by.count // "N/A"')"
  echo -e "${RESET}Following: $YELLOW$(echo "$u" | jq -r '.edge_follow.count // "N/A"')"
  echo -e "${RESET}Verified: $(if [ "$(echo "$u" | jq -r '.is_verified')" = "true" ]; then echo -e "${GREEN}Yes${RESET}"; else echo -e "${RED}No${RESET}"; fi)"
  echo -e "${RESET}Private: $(if [ "$(echo "$u" | jq -r '.is_private')" = "true" ]; then echo -e "${GREEN}Yes${RESET}"; else echo -e "${RED}No${RESET}"; fi)"
  echo -e "${RESET}Profile Pic URL: $PURPLE$(echo "$u" | jq -r '.profile_pic_url_hd // "N/A"')"
  # bash ./recoverByUserName.sh "$username"
  echo
}

skip_image=false
while [[ "$1" == --* ]]; do
  case $1 in
    --no-image) skip_image=true; shift ;;
    --help)
      echo -e "${CYAN}Usage: $0 [options] username${RESET}"
      echo -e "${CYAN}Options:${RESET}"
      echo -e "${CYAN}  --no-image   Skip downloading and displaying the profile picture${RESET}"
      echo -e "${CYAN}  --help       Display this help message${RESET}"
      echo -e "${CYAN}Description:${RESET}"
      echo -e "${CYAN}  Fetch Instagram profile information for the given username.${RESET}"
      echo -e "${CYAN}  The username must be provided as a command-line argument.${RESET}"
      echo -e "${YELLOW}Note: This script uses an unofficial Instagram API endpoint and may stop working if Instagram changes their API.${RESET}"
      exit 0
      ;;
    *) echo -e "${RED}Unknown option: $1${RESET}"; echo -e "${CYAN}Usage: $0 [options] username${RESET}"; exit 1 ;;
  esac
done

username="$1"
if [ -z "$username" ]; then
  echo -e "${RED}Error: Username not provided.${RESET}"
  echo -e "${CYAN}Usage: $0 [options] username${RESET}"
  exit 1
fi

fetch_instagram_profile "$username" "$skip_image"
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to fetch profile information for @$username.${RESET}"
  exit 1
fi
