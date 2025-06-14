#!/usr/bin/env bash

# Cores e ícones
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
CYAN='\033[1;96m'
RESET='\033[0m'

ICON_SUCCESS="✔"
ICON_ERROR="✖"
ICON_INFO="ℹ"
ICON_WARN="⚠"

log() {
  local color=$1
  local icon=$2
  local msg=$3
  echo -e "${color}${icon} ${msg}${RESET}"
}

debug_log() {
  if [ "$DEBUG" = true ]; then
    echo -e "${YELLOW}[DEBUG] $*${RESET}"
  fi
}

urlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  for (( pos=0; pos<strlen; pos++ )); do
    c=${string:$pos:1}
    case "$c" in
      [a-zA-Z0-9.~_-]) encoded+="$c" ;;
      ' ') encoded+="+" ;;
      *) printf -v hex '%%%02X' "'$c"
         encoded+="$hex"
         ;;
    esac
  done
  echo "$encoded"
}

generate_enc_password() {
  local password="$1"
  echo "#PWD_INSTAGRAM_BROWSER:0:$(date +%s):$password"
}

# Variáveis globais
USERNAME=""
PROXY=""
NO_PASSWORD=false
DEBUG=false

# Parse argumentos
while [[ $# -gt 0 ]]; do
  case "$1" in
    -u|--username)
      USERNAME="$2"
      shift 2
      ;;
    -p|--proxy)
      PROXY="$2"
      shift 2
      ;;
    --no-password)
      NO_PASSWORD=true
      shift
      ;;
    --debug)
      DEBUG=true
      shift
      ;;
    *)
      log "$YELLOW" "$ICON_WARN" "Unknown argument: $1"
      shift
      ;;
  esac
done

if [ -z "$USERNAME" ]; then
  log "$RED" "$ICON_ERROR" "Username is required."
  echo "Usage: $0 -u <username> [-p <proxy>] [--no-password] [--debug]"
  exit 1
fi

prompt_password() {
  if [ "$NO_PASSWORD" = true ]; then
    # senha visível com edição (setas funcionam)
    read -e -p "Password: " PASSWORD
  else
    # senha oculta (sem edição)
    read -s -p "Password: " PASSWORD
    echo
  fi
}

prompt_password

USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"

get_csrf_token() {
  log "$BLUE" "$ICON_INFO" "Getting CSRF token..."

  local headers
  if [ -n "$PROXY" ]; then
    headers=$(curl -s -x "$PROXY" -A "$USER_AGENT" -D - "https://www.instagram.com/accounts/login/" -o /dev/null)
  else
    headers=$(curl -s -A "$USER_AGENT" -D - "https://www.instagram.com/accounts/login/" -o /dev/null)
  fi

  CSRF_TOKEN=$(echo "$headers" | grep -i 'Set-Cookie: csrftoken=' | head -n1 | sed -E 's/.*csrftoken=([^;]+);.*/\1/')

  debug_log "CSRF token: $CSRF_TOKEN"

  if [ -z "$CSRF_TOKEN" ]; then
    log "$RED" "$ICON_ERROR" "CSRF token not found."
    exit 1
  fi

  log "$GREEN" "$ICON_SUCCESS" "CSRF token successfully obtained."
}

send_login_request() {
  log "$BLUE" "$ICON_INFO" "Sending login request..."

  ENC_PASSWORD=$(generate_enc_password "$PASSWORD")
  POST_DATA="username=$(urlencode "$USERNAME")&enc_password=$(urlencode "$ENC_PASSWORD")"

  HEADERS=(
    -H "User-Agent: $USER_AGENT"
    -H "X-CSRFToken: $CSRF_TOKEN"
    -H "X-Instagram-AJAX: 1"
    -H "X-Requested-With: XMLHttpRequest"
    -H "Content-Type: application/x-www-form-urlencoded"
    -H "Referer: https://www.instagram.com/accounts/login/"
    -H "Cookie: csrftoken=$CSRF_TOKEN"
  )

  if [ -n "$PROXY" ]; then
    RESPONSE=$(curl -s -x "$PROXY" "${HEADERS[@]}" -d "$POST_DATA" "https://www.instagram.com/api/v1/web/accounts/login/ajax/")
  else
    RESPONSE=$(curl -s "${HEADERS[@]}" -d "$POST_DATA" "https://www.instagram.com/api/v1/web/accounts/login/ajax/")
  fi

  debug_log "Response: $RESPONSE"
}

handle_2fa() {
  log "$YELLOW" "$ICON_WARN" "Two-factor authentication required."

  read -p "Enter 2FA code: " TWO_FA_CODE

  POST_2FA_DATA="username=$(urlencode "$USERNAME")&verification_code=$TWO_FA_CODE"

  HEADERS_2FA=(
    -H "User-Agent: $USER_AGENT"
    -H "X-CSRFToken: $CSRF_TOKEN"
    -H "X-Instagram-AJAX: 1"
    -H "X-Requested-With: XMLHttpRequest"
    -H "Content-Type: application/x-www-form-urlencoded"
    -H "Referer: https://www.instagram.com/accounts/login/"
    -H "Cookie: csrftoken=$CSRF_TOKEN"
  )

  if [ -n "$PROXY" ]; then
    RESPONSE_2FA=$(curl -s -x "$PROXY" "${HEADERS_2FA[@]}" -d "$POST_2FA_DATA" "https://www.instagram.com/api/v1/web/accounts/login/two_factor/")
  else
    RESPONSE_2FA=$(curl -s "${HEADERS_2FA[@]}" -d "$POST_2FA_DATA" "https://www.instagram.com/api/v1/web/accounts/login/two_factor/")
  fi

  debug_log "2FA Response: $RESPONSE_2FA"

  AUTHENTICATED_2FA=$(echo "$RESPONSE_2FA" | jq -r '.authenticated // false')

  if [ "$AUTHENTICATED_2FA" == "true" ]; then
    log "$GREEN" "$ICON_SUCCESS" "2FA verification successful! Logged in."
    exit 0
  else
    log "$RED" "$ICON_ERROR" "2FA verification failed."
    exit 1
  fi
}

main() {
  get_csrf_token
  send_login_request

  AUTHENTICATED=$(echo "$RESPONSE" | jq -r '.authenticated // false')
  REQUIRES_2FA=$(echo "$RESPONSE" | jq -r '.two_factor_required // false')
  MESSAGE=$(echo "$RESPONSE" | jq -r '.message // empty')

  if [ "$AUTHENTICATED" == "true" ]; then
    log "$GREEN" "$ICON_SUCCESS" "Login successful!"
    exit 0
  elif [ "$REQUIRES_2FA" == "true" ]; then
    handle_2fa
  else
    log "$RED" "$ICON_ERROR" "Login failed: $MESSAGE"
    exit 1
  fi
}

main

