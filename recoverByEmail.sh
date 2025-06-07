#!/bin/bash
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
CYAN='\033[1;96m'
RESET='\033[0m'

ICON_SUCCESS="?"
ICON_ERROR="?"
ICON_INFO="?"
ICON_EMAIL="?"
ICON_USER="?"

log() {
  local color="$1"
  local icon="$2"
  local message="$3"
  echo -e "${color}${icon} ${message}${RESET}"
}
spinner() {
  local pid=$!
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf "[%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "\b\b\b\b"
}
if [ -z "$1" ]; then
  log "$RED" "$ICON_ERROR" "Please provide a username."
  echo "Usage: $0 <username> [--proxy=http://proxy:port] [--check-only] [--retry]"
  exit 1
fi

USERNAME="$1"
shift
PROXY=""
CHECK_ONLY=false
RETRY=false
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --proxy=*)
      PROXY="${1#*=}"
      ;;
    --check-only)
      CHECK_ONLY=true
      ;;
    --retry)
      RETRY=true
      ;;
    *)
      log "$YELLOW" "$ICON_INFO" "Unknown argument: $1"
      ;;
  esac
  shift
done
USER_AGENT="googlebot"
COOKIE_JAR=$(mktemp)
get_csrf_token() {
  log "$BLUE" "$ICON_INFO" "Getting cookies and CSRF token..."
  (
    if [ -n "$PROXY" ]; then
      curl -s -c "$COOKIE_JAR" -x "$PROXY" -A "$USER_AGENT" "https://www.instagram.com/accounts/password/reset/" > /dev/null
    else
      curl -s -c "$COOKIE_JAR" -A "$USER_AGENT" "https://www.instagram.com/accounts/password/reset/" > /dev/null
    fi
  ) & spinner
  CSRF_TOKEN=$(grep -i 'csrftoken' "$COOKIE_JAR" | awk '{print $7}' | tail -n 1)

  if [ -z "$CSRF_TOKEN" ]; then
    log "$RED" "$ICON_ERROR" "CSRF token not found."
    exit 1
  fi

  log "$GREEN" "$ICON_SUCCESS" "CSRF token successfully obtained."
}
send_recovery_request() {
  log "$BLUE" "$ICON_INFO" "Sending recovery request..."
  (
    POST_DATA="email_or_username=${USERNAME}&recaptcha_challenge_field="
    HEADERS=(
      -H "Content-Type: application/x-www-form-urlencoded"
      -H "User-Agent: $USER_AGENT"
      -H "X-CSRFToken: $CSRF_TOKEN"
      -H "X-Instagram-AJAX: 1"
      -H "X-Requested-With: XMLHttpRequest"
    )
    if [ -n "$PROXY" ]; then
      RESPONSE=$(curl -s -b "$COOKIE_JAR" -x "$PROXY" "${HEADERS[@]}" -d "$POST_DATA" "https://www.instagram.com/api/v1/web/accounts/account_recovery_send_ajax/")
    else
      RESPONSE=$(curl -s -b "$COOKIE_JAR" "${HEADERS[@]}" -d "$POST_DATA" "https://www.instagram.com/api/v1/web/accounts/account_recovery_send_ajax/")
    fi
  ) & spinner
  if ! command -v jq &> /dev/null; then
    log "$RED" "$ICON_ERROR" "'jq' utility is not installed. Please install it to continue."
    exit 1
  fi
  STATUS=$(echo "$RESPONSE" | jq -r '.status')
  if [ "$STATUS" == "ok" ]; then
    log "$GREEN" "$ICON_SUCCESS" "Request sent successfully!"
    BODY=$(echo "$RESPONSE" | jq -r '.body')
    CONTACT_POINT=$(echo "$RESPONSE" | jq -r '.contact_point')
    RECOVERY_METHOD=$(echo "$RESPONSE" | jq -r '.recovery_method')
    CAN_RECOVER_WITH_CODE=$(echo "$RESPONSE" | jq -r '.can_recover_with_code')

    log "$CYAN" "$ICON_EMAIL" "$BODY"
    echo -e "${CYAN}Recovery method:${RESET}"
    echo -e "${CYAN} ~ Can be recovered with code: ${CAN_RECOVER_WITH_CODE}${RESET}"
    echo -e "${CYAN} ~ Hidden email: ${CONTACT_POINT}${RESET}"
    echo -e "${CYAN} ~ Recovery method: ${RECOVERY_METHOD}${RESET}"
  else
    TITLE=$(echo "$RESPONSE" | jq -r '.title
    BODY=$(echo "$RESPONSE" | jq -r '.body
    log "$RED" "$ICON_ERROR" "${TITLE}: ${BODY}"
  fi
}
main() {
  log "$BLUE" "$ICON_USER" "Starting recovery for user @$USERNAME"

  MAX_RETRIES=1
  if [ "$RETRY" = true ]; then
    MAX_RETRIES=3
  fi

  ATTEMPT=1
  while [ $ATTEMPT -le $MAX_RETRIES ]; do
    get_csrf_token
    send_recovery_request
    STATUS=$(echo "$RESPONSE" | jq -r '.status')
    if [ "$STATUS" == "ok" ]; then
      break
    else
      log "$YELLOW" "$ICON_INFO" "Attempt $ATTEMPT failed."
      if [ $ATTEMPT -lt $MAX_RETRIES ]; then
        SLEEP_TIME=$((2 ** ATTEMPT))
        log "$YELLOW" "$ICON_INFO" "Waiting $SLEEP_TIME seconds before next attempt..."
        sleep $SLEEP_TIME
      fi
    fi
    ATTEMPT=$((ATTEMPT + 1))
  done

  if [ "$STATUS" != "ok" ]; then
    log "$RED" "$ICON_ERROR" "All attempts failed."
  fi
  rm -f "$COOKIE_JAR"
}
main
