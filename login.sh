#!/usr/bin/env bash
reset='\e[0m'
red='\e[31m'
green='\e[32m'
yellow='\e[33m'
blue='\e[34m'
gray='\e[90m'
success_icon='?'
error_icon='?'
warn_icon='?'
info_icon='?'
debug_icon='?'

log_success() {
  echo -e "${green}${success_icon} $1${reset}"
}

log_error() {
  echo -e "${red}${error_icon} $1${reset}"
}

log_warn() {
  echo -e "${yellow}${warn_icon} $1${reset}"
}

log_info() {
  echo -e "${blue}${info_icon} $1${reset}"
}

log_debug() {
  echo -e "${gray}${debug_icon} $1${reset}"
}

username=""
proxy=""
verbose=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -u|--username) username="$2"; shift ;;
    -p|--proxy) proxy="$2"; shift ;;
    -v|--verbose) verbose=true; shift ;;
    *) shift ;;
  esac
done

prompt_password() {
  read -s -p "$(echo -e "${blue}${info_icon} Password: ${reset}") " password
  echo $password
}

generate_enc_password() {
  echo "#PWD_INSTAGRAM_BROWSER:0:$(date +%s):$1"
}

handle_2fa() {
  read -p "$(echo -e "${blue}${info_icon} 2FA Code: ${reset}") " code
  log_info "Verifying 2FA code..."
}

save_session() {
  echo "{\"cookies\":\"$1\",\"timestamp\":\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}" > session.json
  log_info "Session saved successfully in session.json"
}

validate_headers() {
  if [[ -z "$1" ]]; then
    log_error "Invalid server response"
    exit 1
  fi
}

main() {
  if [[ -z "$username" ]]; then
    log_error "Username is required"
    exit 1
  fi
  password=$(prompt_password)
  if [[ -n "$proxy" ]]; then
    IFS=':' read -r host port <<< "$proxy"
    log_debug "Using proxy: $proxy"
  fi
  log_info "Starting handshake..."
  log_info "Authenticating..."
}

main
