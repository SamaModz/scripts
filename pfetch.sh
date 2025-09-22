# Uptime
# CPU
# GPU
# Disk usage
# Battery
# Public IP
# Weather
# Music
# Calendar
# Quote of the day
# Random joke
# System load
# Network speed
# Last login
# Temperature

# Requiremests
# figlet
# curl
# jq

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m'

# Functions
print_header() {
  figlet -f slant "System Info"
}
print_uptime() {
  echo -e "${CYAN}Uptime:${NC} $(uptime -p)"
}
print_cpu() {
  echo -e "${CYAN}CPU:${NC} $(lscpu | grep 'Model name' | sed 's/Model name:\s*//')"
}
print_gpu() {
  echo -e "${CYAN}GPU:${NC} $(lspci | grep -i 'vga\|3d\|2d' | sed 's/.*: //')"
}
print_disk_usage() {
  echo -e "${CYAN}Disk Usage:${NC} $(df -h --total | grep 'total' | awk '{print $3 " used of " $2 " (" $5 " used)"}')"
}
print_battery() {
  if command -v acpi &> /dev/null; then
    echo -e "${CYAN}Battery:${NC} $(acpi | awk -F', ' '{print $2 " (" $3 ")"}')"
  else
    echo -e "${CYAN}Battery:${NC} acpi not installed"
  fi
}
print_public_ip() {
  echo -e "${CYAN}Public IP:${NC} $(curl -s ifconfig.me)"
}
print_weather() {
  if [ -z "$WEATHER_API_KEY" ] || [ -z "$CITY" ]; then
    echo -e "${CYAN}Weather:${NC} Please set WEATHER_API_KEY and CITY environment variables."
    return
  fi
  WEATHER=$(curl -s "http://api.openweathermap.org/data/2.5/weather?q=$CITY&appid=$WEATHER_API_KEY&units=metric")
  TEMP=$(echo $WEATHER | jq '.main.temp')
  DESC=$(echo $WEATHER | jq -r '.weather[0].description')
  echo -e "${CYAN}Weather in $CITY:${NC} $TEMP°C, $DESC"
}
print_music() {
  if command -v playerctl &> /dev/null; then
    STATUS=$(playerctl status 2>/dev/null)
    if [ "$STATUS" = "Playing" ]; then
      ARTIST=$(playerctl metadata artist 2>/dev/null)
      TITLE=$(playerctl metadata title 2>/dev/null)
      echo -e "${CYAN}Now Playing:${NC} $ARTIST - $TITLE"
    else
      echo -e "${CYAN}Now Playing:${NC} No music playing"
    fi
  else
    echo -e "${CYAN}Now Playing:${NC} playerctl not installed"
  fi
}
print_calendar() {
  echo -e "${CYAN}Calendar:${NC}"
  cal
}


show_info() {
  print_header
  print_uptime
  print_cpu
  print_gpu
  print_disk_usage
  print_battery
  print_public_ip
  print_weather
  print_music
  print_calendar
}
show_info
