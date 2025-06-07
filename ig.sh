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
  spinner_chars=('|' '/' '-' '\\')
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

fetch_instagram_profile() {
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
  # wget -qO ig.png "$(echo $u | jq -r '.profile_pic_url_hd')" && chafa ig.png --size=60x60 && rm -rf ig.png
  
  # echo
  # echo -e "$GREEN Profile information for @$username:$RESET"
  # echo -e "$RESET  :$PURPLE $(echo "$u" | jq -r '.id // "N/A"')"
  # echo -e "$RESET  :$GREEN $(echo "$u" | jq -r '.full_name // "N/A"')"
  # echo -e "$RESET 󰓹 :$GREEN $(echo "$u" | jq -r '.username // "N/A"')"
  # echo -e "$RESET 󰂦 :$BLUE $(echo "$u" | jq -r '.biography // "N/A"')"
  # echo -e "$RESET  :$YELLOW $(echo "$u" | jq -r '.edge_followed_by.count // "N/A"')"
  # echo -e "$RESET  :$YELLOW $(echo "$u" | jq -r '.edge_follow.count // "N/A"')"
  # echo -e "$RESET  : $(if [ "$(echo "$u" | jq -r '.is_verified')" = "true" ]; then echo -e "${GREEN}Yes${RESET}"; else echo -e "${RED}No${RESET}"; fi)"
  # echo -e "$RESET  : $(if [ "$(echo "$u" | jq -r '.is_verified')" = "true" ]; then echo -e "${GREEN}Yes${RESET}"; else echo -e "${RED}No${RESET}"; fi)"
  # echo -e "$RESET  :$PURPLE $(echo "$u" | jq -r '.profile_pic_url_hd // "N/A"')"
  # echo

  echo
  echo -e "${GREEN} Profile information for @$username:${RESET}"
  echo -e "${CYAN}${RESET} \033[1;37mUser ID:${RESET} $PURPLE$(echo "$u" | jq -r '.id // "N/A"')"
  echo -e "${CYAN}${RESET} \033[1;37mFull Name:${RESET} $GREEN$(echo "$u" | jq -r '.full_name // "N/A"')"
  echo -e "${CYAN}󰓹${RESET} \033[1;37mUsername:${RESET} $GREEN$(echo "$u" | jq -r '.username // "N/A"')"
  echo -e "${CYAN}󰂦${RESET} \033[1;37mBiography:${RESET} $BLUE$(echo "$u" | jq -r '.biography // "N/A"')"
  echo -e "${CYAN}${RESET} \033[1;37mFollowers:${RESET} $YELLOW$(echo "$u" | jq -r '.edge_followed_by.count // "N/A"')"
  echo -e "${CYAN}${RESET} \033[1;37mFollowing:${RESET} $YELLOW$(echo "$u" | jq -r '.edge_follow.count // "N/A"')"
  echo -e "${CYAN}${RESET} \033[1;37mVerified:${RESET} $(if [ "$(echo "$u" | jq -r '.is_verified')" = "true" ]; then echo -e "${GREEN}Yes${RESET}"; else echo -e "${RED}No${RESET}"; fi)"
  echo -e "${CYAN}${RESET} \033[1;37mPrivate:${RESET} $(if [ "$(echo "$u" | jq -r '.is_private')" = "true" ]; then echo -e "${GREEN}Yes${RESET}"; else echo -e "${RED}No${RESET}"; fi)"
  # echo -e "${CYAN}${RESET} \033[1;37mProfile Pic URL:${RESET} $PURPLE$(echo "$u" | jq -r '.profile_pic_url_hd // "N/A"')"
  echo 
}

username="$1"
fetch_instagram_profile "$username"
