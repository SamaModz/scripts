#!/usr/bin/env bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m'
SPINNER=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")

spinner() {
    local pid=$!
    local delay=0.1
    local i=0
    while [ -d /proc/$pid ]; do
        printf "\r${SPINNER[$i]} "
        i=$(( (i + 1) % 10 ))
        sleep $delay
    done
    printf "\r   \r"
}
progress_bar() {
    local progress=$1
    local total=$2
    local width=30
    local percent=$(( progress * 100 / total ))
    local filled=$(( progress * width / total ))
    local empty=$(( width - filled ))
    local bar=$(printf "%0.s#" $(seq 1 $filled))
    local spaces=$(printf "%0.s " $(seq 1 $empty))
    printf "${WHITE}%3d/%d [${GREEN}==>${RED}%s${NC}%s] %3d%%\n" "$progress" "$total" "$bar" "$spaces" "$percent"
}
remove_packages() {
    local description=$1
    shift
    local packages=("$@")
    echo -e "${BLUE}Removing: $description${NC}"
    sudo apt purge -y "${packages[@]}" & spinner
    sudo apt autoremove -y & spinner
    sudo apt clean & spinner
    echo -e "${GREEN}✔ $description removed successfully.${NC}"
}
show_help() {
    echo -e "${YELLOW}Usage:${NC} $0 [options]"
    echo -e "Options:"
    echo -e "  --extra    Remove additional packages (browsers, players, etc.)"
    echo -e "  --help     Show this help message"
    exit 0
}
EXTRA=false
for arg in "$@"; do
    case $arg in
        --extra)
            EXTRA=true
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $arg${NC}"
            show_help
            ;;
    esac
done
tasks=(
    "Removing XFCE and LightDM"
    "Removing Xorg and graphics libraries"
    "Removing themes and icons"
)

if $EXTRA; then
    tasks+=("Removing additional packages")
fi

total_tasks=${#tasks[@]}
current_task=0
for task in "${tasks[@]}"; do
    current_task=$((current_task + 1))
    progress_bar "$current_task" "$total_tasks"
    case $task in
        "Removing XFCE and LightDM")
            remove_packages "$task" xfce4 xfce4-* lightdm lightdm-*
            ;;
        "Removing Xorg and graphics libraries")
            remove_packages "$task" xorg xserver-* x11-* libx11-6 libwayland-client0
            ;;
        "Removing themes and icons")
            remove_packages "$task" gtk* gnome* qt*
            ;;
        "Removing additional packages")
            remove_packages "$task" vlc* chromium* firefox* libreoffice* gimp* plymouth* lxdm* lxde* lxqt* mate-* cinnamon* kde* sddm* xdg-utils
            ;;
    esac
done
echo -e "${BLUE}Configuring system to boot in text mode...${NC}"
sudo systemctl set-default multi-user.target & spinner
echo -e "${GREEN}✔ Configuration completed.${NC}"
echo -e "${YELLOW}Rebooting system...${NC}"
sudo reboot
