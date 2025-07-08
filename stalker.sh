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
    ((i=(i+1)%4))
  done &
  spinner_pid=$!
}

stop_spinner() {
  kill $spinner_pid
  wait $spinner_pid 2>/dev/null
  printf "\r$RESET"
}

check_package() {
   create_spinner "${YELLOW}Checking for required packages...${RESET}"
  local cmds=(jq chafa curl wget)

  # Detect available package manager
  for pm in pkg apt pacman dnf apk zypper; do
    if command -v $pm &>/dev/null; then
      case $pm in
        pkg)    INSTALL="pkg install -y" ;;
        apt)    INSTALL="sudo apt install -y" ;;
        pacman) INSTALL="sudo pacman -Sy --noconfirm" ;;
        dnf)    INSTALL="sudo dnf install -y" ;;
        apk)    INSTALL="sudo apk add" ;;
        zypper) INSTALL="sudo zypper install -y" ;;
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
      create_spinner "${YELLOW}$cmd not found. Installing...${RESET}"
      stop_spinner
      if $INSTALL "$cmd" &>/dev/null; then
        echo -e "${GREEN}$cmd installed successfully.${RESET}"
      else
        echo -e "${RED}Failed to install $cmd.${RESET}"
        exit 1
      fi
    fi
  done
}

fetch_instagram_profile() {
  # check_package 2>/dev/null
  username="$1"
  if [ -z "$username" ]; then
    echo -e "$RED Error: Username not provided.$RESET"
    exit 1
  fi

  create_spinner "Fetching profile information for @$username..."

  response=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
    -H "x-ig-app-id: 936619743392459" \
    "https://i.instagram.com/api/v1/users/web_profile_info/?username=$username")

  stop_spinner

  data=$(echo "$response" | jq '.data')
  if [ "$data" == "null" ]; then
    echo -e "$RED❌ Error: User data not found in API response.$RESET"
    return
  fi

  u=$(echo "$data" | jq '.user')
  # install the Chafa for use the command below
  wget -qO thisImage.png "$(echo $u | jq -r '.profile_pic_url_hd')" && chafa thisImage.png --size=60x60 && rm -rf thisImage.png
  # echo "$u" | jq
  echo
  echo -e "$GREEN Profile information for @$username:$RESET"
  echo -e "$RESET  :$PURPLE $(echo "$u" | jq -r '.id // "N/A"')"
  echo -e "$RESET  :$GREEN $(echo "$u" | jq -r '.full_name // "N/A"')"
  echo -e "$RESET 󰓹 :$GREEN $(echo "$u" | jq -r '.username // "N/A"')"
  echo -e "$RESET 󰂦 :$BLUE $(echo "$u" | jq -r '.biography // "N/A"')"
  echo -e "$RESET  :$YELLOW $(echo "$u" | jq -r '.edge_followed_by.count // "N/A"')"
  echo -e "$RESET  :$YELLOW $(echo "$u" | jq -r '.edge_follow.count // "N/A"')"
  echo -e "$RESET  : $(if [ "$(echo "$u" | jq -r '.is_verified')" = "true" ]; then echo -e "${GREEN}Yes${RESET}"; else echo -e "${RED}No${RESET}"; fi)"
  echo -e "$RESET  : $(if [ "$(echo "$u" | jq -r '.is_verified')" = "true" ]; then echo -e "${GREEN}Yes${RESET}"; else echo -e "${RED}No${RESET}"; fi)"
  echo -e "$RESET  :$PURPLE $(echo "$u" | jq -r '.profile_pic_url_hd // "N/A"')"
  echo

  # echo
  # echo -e "${GREEN} Profile information for @$username:${RESET}"
  # echo -e "${CYAN}${RESET} \033[1;37mUser ID:${RESET} $PURPLE$(echo "$u" | jq -r '.id // "N/A"')"
  # echo -e "${CYAN}${RESET} \033[1;37mFull Name:${RESET} $GREEN$(echo "$u" | jq -r '.full_name // "N/A"')"
  # echo -e "${CYAN}󰓹${RESET} \033[1;37mUsername:${RESET} $GREEN$(echo "$u" | jq -r '.username // "N/A"')"
  # echo -e "${CYAN}󰂦${RESET} \033[1;37mBiography:${RESET} $BLUE$(echo "$u" | jq -r '.biography // "N/A"')"
  # echo -e "${CYAN}${RESET} \033[1;37mFollowers:${RESET} $YELLOW$(echo "$u" | jq -r '.edge_followed_by.count // "N/A"')"
  # echo -e "${CYAN}${RESET} \033[1;37mFollowing:${RESET} $YELLOW$(echo "$u" | jq -r '.edge_follow.count // "N/A"')"
  # echo -e "${CYAN}${RESET} \033[1;37mVerified:${RESET} $(if [ "$(echo "$u" | jq -r '.is_verified')" = "true" ]; then echo -e "${GREEN}Yes${RESET}"; else echo -e "${RED}No${RESET}"; fi)"
  # echo -e "${CYAN}${RESET} \033[1;37mPrivate:${RESET} $(if [ "$(echo "$u" | jq -r '.is_private')" = "true" ]; then echo -e "${GREEN}Yes${RESET}"; else echo -e "${RED}No${RESET}"; fi)"
  # # echo -e "${CYAN}${RESET} \033[1;37mProfile Pic URL:${RESET} $PURPLE$(echo "$u" | jq -r '.profile_pic_url_hd // "N/A"')"
  # echo
}

username="$1"
fetch_instagram_profile "$username"
if [ $? -ne 0 ]; then
  echo -e "${RED}Failed to fetch profile information for @$username.${RESET}"
  exit 1
  pkill bash
  echo "${YELLOW}Finalized Process...${RESET}"
fi

