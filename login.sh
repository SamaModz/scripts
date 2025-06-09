#!/bin/bash

# Requer: curl, jq

# Cores para logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
ORANGE='\033[38;5;208m'
RESET='\033[0m'

# Ícones simples
ICON_SUCCESS="✔"
ICON_ERROR="✖"
ICON_WARN="⚠"
ICON_INFO="ℹ"
ICON_DEBUG="🐞"

# Funções de log
log_success() { echo -e "${GREEN}${ICON_SUCCESS} $1${RESET}"; }
log_error() { echo -e "${RED}${ICON_ERROR} $1${RESET}"; }
log_warn() { echo -e "${ORANGE}${ICON_WARN} $1${RESET}"; }
log_info() { echo -e "${BLUE}${ICON_INFO} $1${RESET}"; }
log_debug() { [[ $VERBOSE == true ]] && echo -e "${GRAY}${ICON_DEBUG} $1${RESET}"; }

# Variáveis
USERNAME=""
PROXY=""
VERBOSE=false
SESSION_FILE="session.json"

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    -u|--username)
      USERNAME="$2"
      shift 2
      ;;
    -p|--proxy)
      PROXY="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -z "$USERNAME" ]]; then
  log_error "Username is required. Use -u or --username."
  exit 1
fi

# Prompt password (hidden input)
prompt_password() {
  read -s -p "$(echo -e "${BLUE}${ICON_INFO} Password: ${RESET}")" PASSWORD
  echo
}

# Gera senha no formato esperado
generate_enc_password() {
  local pass="$1"
  echo "#PWD_INSTAGRAM_BROWSER:0:$(date +%s):$pass"
}

# Função para fazer requisição curl com proxy, cookies, headers
curl_request() {
  local url="$1"
  local method="$2"
  local data="$3"
  local headers=("${!4}")
  local cookie_jar="$5"
  local extra_opts=("${!6}")

  local proxy_opts=()
  if [[ -n "$PROXY" ]]; then
    proxy_opts=(--proxy "$PROXY")
    log_debug "Using proxy: $PROXY"
  fi

  # Monta headers para curl
  local header_args=()
  for h in "${headers[@]}"; do
    header_args+=(-H "$h")
  done

  if [[ "$method" == "GET" ]]; then
    curl "${proxy_opts[@]}" -sSL "${header_args[@]}" --cookie "$cookie_jar" --cookie-jar "$cookie_jar" "${extra_opts[@]}" "$url"
  else
    curl "${proxy_opts[@]}" -sSL -X "$method" "${header_args[@]}" --data "$data" --cookie "$cookie_jar" --cookie-jar "$cookie_jar" "${extra_opts[@]}" "$url"
  fi
}

# Manipulação 2FA
handle_2fa() {
  read -p "$(echo -e "${BLUE}${ICON_INFO} 2FA Code: ${RESET}")" code

  log_info "Verifying 2FA code..."

  local data="verification_code=$code&username=$USERNAME"

  local headers=(
    "Content-Type: application/x-www-form-urlencoded"
    "X-CSRFToken: $CSRF_TOKEN"
    "X-Instagram-AJAX: d3d3a9d7d2"
    "X-Requested-With: XMLHttpRequest"
    "Referer: https://www.instagram.com/accounts/login/"
    "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
  )

  local response=$(curl_request "https://www.instagram.com/api/v1/web/accounts/login/two_factor/" "POST" "$data" headers[@] "$COOKIE_JAR" extra_opts[@])
  local authenticated=$(echo "$response" | jq -r '.authenticated')

  if [[ "$authenticated" == "true" ]]; then
    log_success "2FA authentication successful!"
  else
    log_error "Invalid 2FA code"
    exit 1
  fi
}

# Salva sessão
save_session() {
  local cookies_content
  cookies_content=$(cat "$COOKIE_JAR")
  local timestamp
  timestamp=$(date --iso-8601=seconds)
  echo "{\"cookies\": $(jq -Rs '.' <<< "$cookies_content"), \"timestamp\": \"$timestamp\"}" > "$SESSION_FILE"
  chmod 600 "$SESSION_FILE"
  log_info "Session saved successfully in $SESSION_FILE"
}

# Variáveis temporárias
COOKIE_JAR=$(mktemp)
trap "rm -f $COOKIE_JAR" EXIT

# Início do script principal
main() {
  prompt_password

  log_info "Starting handshake..."

  # GET login page para pegar csrf token e cookies
  local headers=(
    "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
    "Accept-Language: en-US,en;q=0.9"
  )

  local login_page_response_headers
  login_page_response_headers=$(curl -sSL -D - "${headers[@]/#/-H }" --cookie "$COOKIE_JAR" --cookie-jar "$COOKIE_JAR" "https://www.instagram.com/accounts/login/" -o /dev/null)

  # Extrai csrf token do cookie
  CSRF_TOKEN=$(grep -i 'csrftoken' "$COOKIE_JAR" | head -n1 | awk '{print $7}')
  if [[ -z "$CSRF_TOKEN" ]]; then
    log_error "Failed to retrieve CSRF token."
    exit 1
  fi
  log_debug "CSRF Token: $CSRF_TOKEN"

  log_info "Authenticating..."

  local enc_pass
  enc_pass=$(generate_enc_password "$PASSWORD")

  local post_data="username=$USERNAME&enc_password=$enc_pass"

  local post_headers=(
    "Content-Type: application/x-www-form-urlencoded"
    "X-CSRFToken: $CSRF_TOKEN"
    "X-Instagram-AJAX: d3d3a9d7d2"
    "X-Requested-With: XMLHttpRequest"
    "Referer: https://www.instagram.com/accounts/login/"
    "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
  )

  local response
  response=$(curl_request "https://www.instagram.com/api/v1/web/accounts/login/ajax/" "POST" "$post_data" post_headers[@] "$COOKIE_JAR" extra_opts[@])

  local authenticated
  authenticated=$(echo "$response" | jq -r '.authenticated')
  local requires_2fa
  requires_2fa=$(echo "$response" | jq -r '.two_factor_required')

  if [[ "$authenticated" == "true" ]]; then
    log_success "Authentication successful!"
    save_session
  elif [[ "$requires_2fa" == "true" ]]; then
    log_warn "2FA verification required"
    handle_2fa
    save_session
  else
    local message
    message=$(echo "$response" | jq -r '.message // empty')
    log_error "Invalid credentials. $message"
    exit 1
  fi
}

main

