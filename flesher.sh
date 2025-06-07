#!/bin/bash

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
YELLOW='\033[1;34m'
YELLOW='\033[1;35m'
CYAN='\033[1;36m'
RESET='\033[0m'

# Nerd Font Icons
DISK=""
CD=""
ARROW=""
WARN=""
CHECK=""
CROSS=""
LOADING=""

# Spinner animation for loading
loading() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠸⢰⣠⣄⡆⡃⡁⠈'
    local i=0
    tput civis
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        printf "\r${YELLOW}${LOADING} ${message} ${spin:$i:1}${RESET}"
        sleep 0.1
    done
    printf "\r${GREEN}${CHECK} ${message} completed.${RESET}\n"
    tput cnorm
}

# Confirmation prompt
confirm_action() {
    local prompt=$1
    read -p "$(echo -e "${RED}${WARN} ${prompt} (y/N): ${RESET}")" confirm
    [[ "$confirm" == "y" || "$confirm" == "Y" ]]
}

# Main
clear
echo -e "${CYAN}${CD} ISO Burner Tool${RESET}"
echo -e "${YELLOW}${ARROW} This script will use 'dd' to burn an ISO image to a USB device.${RESET}"
echo -e "${RED}${WARN} WARNING: All data on the target device will be erased!${RESET}"
echo

# Ask for ISO path
read -p "$(echo -e "${CYAN}${CD} Enter the path to the ISO file: ${RESET}")" iso_path

if [[ ! -f "$iso_path" ]]; then
    echo -e "${RED}${CROSS} File not found: $iso_path${RESET}"
    exit 1
fi

# Show connected devices
echo
echo -e "${YELLOW}${DISK} Available devices (lsblk):${RESET}"
lsblk -dpno NAME,SIZE,MODEL | grep -v "loop"
echo

# Ask for target device
read -p "$(echo -e "${CYAN}${DISK} Enter the target device path (e.g., /dev/sdX): ${RESET}")" device

if [[ ! -b "$device" ]]; then
    echo -e "${RED}${CROSS} Invalid device: $device${RESET}"
    exit 1
fi

# Confirm operation
echo
if ! confirm_action "Are you sure you want to write to '$device'?"; then
    echo -e "${RED}${CROSS} Operation cancelled.${RESET}"
    exit 1
fi

# Run dd with loading animation
echo -e "${GREEN}${ARROW} Starting ISO burn process...${RESET}"
(sudo dd if="$iso_path" of="$device" bs=4M status=progress oflag=sync) &

loading $! "Burning ISO"

echo -e "${GREEN}${CHECK} Done.${RESET}"

