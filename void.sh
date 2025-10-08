#!/usr/bin/env bash


R="\e[0;31m"
G="\e[0;32m"
Y="\e[0;33m"
B="\e[0;34m"
P="\e[0;35m"
C="\e[0;36m"
W="\e[0;37m"
N="\e[0m"

iUSER=""
iHOST=""
iDISTRO=""
iKERNEL=""
iUPTIME=""
iSHELL=""
iPKGS="󰏖"
iMEM=""
iWIFI=""
iBAT=""

DISTRO=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
MEMORY=$(free -h --si | awk '/^Mem:/ {print $3 "/ " $2}')
RAM=$(free -h --si | awk '/^Mem:/ {print $3}')
GPU=$(lspci | grep -i 'vga\|3d\|2d' | cut -d: -f3- | sed 's/^[ \t]*//')
CPU=$(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')
MOTHERBOARD=$(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')


TL="╭"; 
TR="╮";
BL="╰";
BR="╯"; 
HL="─";
VL="│"

if command -v pacman >/dev/null 2>&1; then
  PACKAGES=$(pacman -Qq | wc -l)
elif command -v dpkg >/dev/null 2>&1; then
  PACKAGES=$(dpkg -l | grep -c '^ii')
elif command -v rpm /dev/null 2>&1; then
  PACKAGES=$(rpm -qa | wc -l)
elif command -v apk >/dev/null 2>&1; then
  PACKAGES=$(apk info | wc -l)
else
  PACKAGES="?"
fi

version=$(uname -r)
# Print Basic information
echo -e "$Y$iUSER$N  user     $R$USER$N"
echo -e "$Y$iHOST$N  host     $Y$(hostname)$N"
echo -e "$G$iDISTRO$N  distro   $G$DISTRO$N"
echo -e "$C$iKERNEL$N  kernel   $C${version%%-*}$N"
echo -e "$B$iUPTIME$N  uptime   $B$(uptime -p | sed 's/up //')$N"
echo -e "$P$iSHELL$N  shell    $P$SHELL$N"
echo -e "$R$iPKGS$N  pkgs     $R$PACKAGES$N"
echo -e "$Y$iMEM$N  memory   $Y$MEMORY$N"
echo -e "$G$iMEM$N  cpu      $G$CPU$N"
echo -e "$P$iMEM$N  gpu      $P$GPU$N"
# echo -e "$C$iMEM$N  motherboard $C$MOTHERBOARD$N"

