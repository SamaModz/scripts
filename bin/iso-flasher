#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'
shopt -s extglob

USE_TRUECOLOR=1
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
OK='\033[32m'; WARN='\033[33m'; ERR='\033[31m'
if [[ "${USE_TRUECOLOR}" -eq 1 ]]; then
  PURPLE='\033[38;2;173;132;255m'
  PURPLE_DARK='\033[38;2;120;81;169m'
  MAGENTA='\033[38;2;255;110;199m'
  TITLE_BG='\033[48;2;40;21;62m'
  TITLE_FG='\033[38;2;230;220;255m'
else
  PURPLE='\033[95m'
  PURPLE_DARK='\033[35m'
  MAGENTA='\033[36m'
  TITLE_BG='\033[45m'
  TITLE_FG='\033[97m'
fi

ICON_INFO="▶"; ICON_STEP="➤"; ICON_OK="✔"; ICON_WARN="⚠"; ICON_ERR="✖"
say()        { printf "%b%s%b\n" "$1" "${*:2}" "$RESET"; }
title()      { printf "%b%b %s %b%b\n" "$TITLE_BG" "$TITLE_FG" "$*" "$RESET" "$RESET"; }
log_info()   { say "${PURPLE}${BOLD}${ICON_INFO}" "$*"; }
log_step()   { say "${PURPLE_DARK}${BOLD}${ICON_STEP}" "$*"; }
log_ok()     { say "${OK}${BOLD}${ICON_OK}" "$*"; }
log_warn()   { say "${WARN}${BOLD}${ICON_WARN}" "$*"; }
log_err()    { say "${ERR}${BOLD}${ICON_ERR}" "$*"; }
abort() { log_err "$*"; exit 1; }

LOCK_FILE="/tmp/iso-flasher.lock"
exec 9>"$LOCK_FILE" || true
if ! flock -n 9; then
  abort "a run is already in progress (lock: $LOCK_FILE)."
fi

require_cmd() { command -v "$1" >/dev/null 2>&1 || abort "required command missing: $1"; }
is_block()     { [[ -b "$1" ]]; }
is_file()      { [[ -f "$1" ]]; }
is_root()      { [[ "${EUID:-$(id -u)}" -eq 0 ]]; }
is_whole_disk() {
  local d="$1"
  [[ "$d" =~ ^/dev/sd[a-z]$ || "$d" =~ ^/dev/nvme[0-9]+n[0-9]+$ || "$d" =~ ^/dev/mmcblk[0-9]+$ ]]
}
list_devices() {
  require_cmd lsblk
  title "AVAILABLE DEVICES"
  lsblk -o NAME,MODEL,SIZE,TYPE,RM,RO,TRAN,MOUNTPOINT -e7
  printf "\n"
}
device_partitions() {
  lsblk -ln "$1" -o NAME,TYPE | awk '$2=="part"{print "/dev/"$1}'
}
umount_partitions() {
  local d="$1"
  local parts; mapfile -t parts < <(device_partitions "$d" || true)
  if ((${#parts[@]})); then
    log_step "unmounting partitions on $d…"
    for p in "${parts[@]}"; do
      if findmnt -rn "$p" >/dev/null 2>&1; then
        umount -lf "$p" || abort "failed to unmount $p"
      fi
    done
  fi
}
bytes_of() {
  local p="$1"
  if command -v stat >/dev/null 2>&1; then
    stat -Lc %s "$p" 2>/dev/null || stat -f %z "$p"
  else
    wc -c <"$p"
  fi
}
settle_kernel() {
  command -v partprobe >/dev/null 2>&1 && partprobe || true
  command -v udevadm >/dev/null 2>&1 && udevadm settle || true
}
confirm_destruction() {
  local d="$1"
  [[ $FORCE -eq 1 ]] || {
    printf "%b\n" "${WARN}${BOLD}${ICON_WARN} WARNING:${RESET} this will completely erase ${BOLD}$d${RESET}."
      printf "To confirm, type exactly the target disk path (%s): " "$d"
      local reply; read -r reply
      [[ "$reply" == "$d" ]] || abort "invalid confirmation. nothing was written."
    }
}
check_not_root_disk() {
  local rootdev
  rootdev="$(findmnt -nro SOURCE / || true)"
  [[ -n "$rootdev" ]] || return 0
  local parent
  parent="$(lsblk -no PKNAME "$rootdev" 2>/dev/null || true)"
  if [[ -n "$parent" ]]; then
    parent="/dev/$parent"
    [[ "$parent" == "$DEV" ]] && abort "target device matches system disk ($parent). operation cancelled."
  fi
}
sha256_of_file() {
  require_cmd sha256sum
  sha256sum "$1" | awk '{print $1}'
}
sha256_of_device_prefix() {
  require_cmd sha256sum
  local dev="$1"; local nbytes="$2"
  dd if="$dev" bs=4M count=$(( (nbytes + 4*1024*1024 - 1)/(4*1024*1024) )) status=none \
    | head -c "$nbytes" | sha256sum | awk '{print $1}'
  }

ISO=""
DEV=""
VERIFY=0
DRY=0
FORCE=0
BS="4M"

require_cmd dialog

function select_iso() {
  local file
  file=$(dialog --stdout --title "Select ISO file" --fselect "$HOME/" 14 48)
  if [[ -n "$file" && -f "$file" ]]; then
    ISO="$file"
  else
    dialog --msgbox "Invalid file selection!" 6 30
  fi
}

function select_device() {
  local devices
  devices=$(lsblk -dpno NAME,SIZE,MODEL | grep -v "loop" | grep -v "sr0")
  local options=()
  while IFS= read -r line; do
    dev=$(echo "$line" | awk '{print $1}')
    size=$(echo "$line" | awk '{print $2}')
    model=$(echo "$line" | cut -d ' ' -f3-)
    options+=("$dev" "$size $model")
  done <<< "$devices"
  DEV=$(dialog --stdout --menu "Select target device" 15 60 6 "${options[@]}")
  if [[ -z "$DEV" ]]; then
    dialog --msgbox "No device selected!" 6 30
  fi
}

function toggle_verify() {
  VERIFY=$((1 - VERIFY))
  local msg="Verify after writing: $( [[ $VERIFY -eq 1 ]] && echo 'ON' || echo 'OFF' )"
  dialog --msgbox "$msg" 6 30
}

function toggle_dry_run() {
  DRY=$((1 - DRY))
  local msg="Dry-run mode: $( [[ $DRY -eq 1 ]] && echo 'ON' || echo 'OFF' )"
  dialog --msgbox "$msg" 6 30
}

function start_flashing() {
  if [[ -z "$ISO" ]]; then
    dialog --msgbox "ISO file not selected!" 6 30
    return
  fi
  if [[ -z "$DEV" ]]; then
    dialog --msgbox "Target device not selected!" 6 30
    return
  fi

  if ! is_file "$ISO"; then
    dialog --msgbox "ISO file does not exist!" 6 30
    return
  fi

  if ! is_block "$DEV"; then
    dialog --msgbox "Invalid target device!" 6 30
    return
  fi

  if ! is_whole_disk "$DEV"; then
    dialog --msgbox "Target must be a whole disk, not a partition." 6 40
    return
  fi

  if ! is_root; then
    dialog --msgbox "Please run this script as root (sudo)." 6 40
    return
  fi

  check_not_root_disk

  dialog --yesno "Start flashing:\n\nISO: $ISO\nDevice: $DEV\nVerify: $( [[ $VERIFY -eq 1 ]] && echo 'Yes' || echo 'No' )\nDry-run: $( [[ $DRY -eq 1 ]] && echo 'Yes' || echo 'No' )\n\nThis will erase all data on $DEV. Proceed?" 12 50
  if [[ $? -ne 0 ]]; then
    return
  fi

  umount_partitions "$DEV"
  settle_kernel

  local iso_size
  iso_size=$(bytes_of "$ISO")
  local bs_bytes
  bs_bytes=$(numfmt --from=iec "$BS" 2>/dev/null || echo 4194304)

  dialog --infobox "Flashing started...\nPlease check terminal output for progress." 6 40
  sleep 2
  clear

  if (( DRY )); then
    log_info "[dry-run] simulated write command:"
    if command -v pv >/dev/null 2>&1; then
      echo "pv -tpreb -s $iso_size \"$ISO\" | dd of=\"$DEV\" bs=$BS conv=fsync,noerror status=none"
    else
      echo "dd if=\"$ISO\" of=\"$DEV\" bs=$BS conv=fsync,noerror status=progress"
    fi
  else
    title "WRITING"
    if command -v pv >/dev/null 2>&1; then
      log_step "using pv + dd (this may take a few minutes)..."
      pv -tpreb -s "$iso_size" "$ISO" | dd of="$DEV" bs="$BS" conv=fsync,noerror status=none
    else
      log_step "pv not found; using dd with progress..."
      dd if="$ISO" of="$DEV" bs="$BS" conv=fsync,noerror status=progress
    fi
    sync
    settle_kernel
    log_ok "writing completed."

    if (( VERIFY )); then
      title "VERIFYING (sha256)"
      log_step "calculating ISO hash..."
      local iso_sha
      iso_sha=$(sha256_of_file "$ISO")
      log_step "calculating hash of first $(numfmt --to=iec --suffix=B "$iso_size" 2>/dev/null || echo "$iso_size bytes") of device..."
      local dev_sha
      dev_sha=$(sha256_of_device_prefix "$DEV" "$iso_size")
      if [[ "$iso_sha" == "$dev_sha" ]]; then
        log_ok "verification OK — hashes match."
      else
        log_err "verification FAILED — hashes differ.
        ISO: $iso_sha
        DEV: $dev_sha"
      fi
    fi
  fi

  title "DONE"
  log_info "You can remove and reinsert the device for the system to reread the partition table."
  read -rp "Press Enter to continue..."
}

while true; do
  CHOICE=$(dialog --stdout --title "ISO Flasher" --menu "Choose an option:" 16 60 8 \
    1 "List available devices" \
    2 "Select ISO file" \
    3 "Select target device" \
    4 "Toggle verify after flashing (Current: $( [[ $VERIFY -eq 1 ]] && echo ON || echo OFF ))" \
    5 "Toggle dry-run mode (Current: $( [[ $DRY -eq 1 ]] && echo ON || echo OFF ))" \
    6 "Start flashing" \
    7 "Show current selections" \
    8 "Exit")

  case "$CHOICE" in
    1)
      clear
      lsblk -o NAME,MODEL,SIZE,TYPE,RM,RO,TRAN,MOUNTPOINT -e7
      echo
      read -rp "Press Enter to continue..."
      ;;
    2) select_iso ;;
    3) select_device ;;
    4) toggle_verify ;;
    5) toggle_dry_run ;;
    6) start_flashing ;;
    7)
      dialog --msgbox "Current selections:\n\nISO: ${ISO:-not selected}\nDevice: ${DEV:-not selected}\nVerify: $( [[ $VERIFY -eq 1 ]] && echo ON || echo OFF )\nDry-run: $( [[ $DRY -eq 1 ]] && echo ON || echo OFF )" 10 50
      ;;
    8) break ;;
    *) break ;;
  esac
done

clear

