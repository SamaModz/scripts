#!/bin/bash

# Cores ANSI para terminal
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
CYAN='\033[1;96m'
RESET='\033[0m'

# Ícones
ICON_SUCCESS=" "
ICON_ERROR=" "
ICON_INFO=" "
ICON_EMAIL="󰇮 "
ICON_USER=" "

# Função para log estilizado
log() {
  local color="$1"
  local icon="$2"
  local message="$3"
  echo -e "${color}${icon} ${message}${RESET}"
}

# Função para animação de carregamento
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

# Verifica se o usuário foi fornecido
if [ -z "$1" ]; then
  log "$RED" "$ICON_ERROR" "Por favor, forneça um nome de usuário."
  echo "Uso: $0 <username> [--proxy=http://proxy:porta] [--check-only] [--retry]"
  exit 1
fi

USERNAME="$1"
shift

# Parâmetros opcionais
PROXY=""
CHECK_ONLY=false
RETRY=false

# Processa argumentos adicionais
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
      log "$YELLOW" "$ICON_INFO" "Argumento desconhecido: $1"
      ;;
  esac
  shift
done

# Define o User-Agent
USER_AGENT="googlebot"

# Arquivo temporário para cookies
COOKIE_JAR=$(mktemp)

# Função para obter cookies e CSRF token
get_csrf_token() {
  log "$BLUE" "$ICON_INFO" "Obtendo cookies e CSRF token..."
  (
    # Requisição GET para obter cookies e token CSRF
    if [ -n "$PROXY" ]; then
      curl -s -c "$COOKIE_JAR" -x "$PROXY" -A "$USER_AGENT" "https://www.instagram.com/accounts/password/reset/" > /dev/null
    else
      curl -s -c "$COOKIE_JAR" -A "$USER_AGENT" "https://www.instagram.com/accounts/password/reset/" > /dev/null
    fi
  ) & spinner

  # Extrai o token CSRF dos cookies
  CSRF_TOKEN=$(grep -i 'csrftoken' "$COOKIE_JAR" | awk '{print $7}' | tail -n 1)

  if [ -z "$CSRF_TOKEN" ]; then
    log "$RED" "$ICON_ERROR" "CSRF token não encontrado."
    exit 1
  fi

  log "$GREEN" "$ICON_SUCCESS" "CSRF token obtido com sucesso."
}

# Função para enviar solicitação de recuperação
send_recovery_request() {
  log "$BLUE" "$ICON_INFO" "Enviando solicitação de recuperação..."
  (
    # Dados do formulário
    POST_DATA="email_or_username=${USERNAME}&recaptcha_challenge_field="

    # Cabeçalhos
    HEADERS=(
      -H "Content-Type: application/x-www-form-urlencoded"
      -H "User-Agent: $USER_AGENT"
      -H "X-CSRFToken: $CSRF_TOKEN"
      -H "X-Instagram-AJAX: 1"
      -H "X-Requested-With: XMLHttpRequest"
    )

    # Requisição POST para enviar solicitação de recuperação
    if [ -n "$PROXY" ]; then
      RESPONSE=$(curl -s -b "$COOKIE_JAR" -x "$PROXY" "${HEADERS[@]}" -d "$POST_DATA" "https://www.instagram.com/api/v1/web/accounts/account_recovery_send_ajax/")
    else
      RESPONSE=$(curl -s -b "$COOKIE_JAR" "${HEADERS[@]}" -d "$POST_DATA" "https://www.instagram.com/api/v1/web/accounts/account_recovery_send_ajax/")
    fi
  ) & spinner

  # Verifica se o jq está instalado
  if ! command -v jq &> /dev/null; then
    log "$RED" "$ICON_ERROR" "O utilitário 'jq' não está instalado. Por favor, instale-o para continuar."
    exit 1
  fi

  # Analisa a resposta
  STATUS=$(echo "$RESPONSE" | jq -r '.status')
  if [ "$STATUS" == "ok" ]; then
    log "$GREEN" "$ICON_SUCCESS" "Solicitação enviada com sucesso!"
    BODY=$(echo "$RESPONSE" | jq -r '.body')
    CONTACT_POINT=$(echo "$RESPONSE" | jq -r '.contact_point')
    RECOVERY_METHOD=$(echo "$RESPONSE" | jq -r '.recovery_method')
    CAN_RECOVER_WITH_CODE=$(echo "$RESPONSE" | jq -r '.can_recover_with_code')

    log "$CYAN" "$ICON_EMAIL" "$BODY"
    echo -e "${CYAN}Método de recuperação:${RESET}"
    echo -e "${CYAN} ~ Pode ser recuperado com código: ${CAN_RECOVER_WITH_CODE}${RESET}"
    echo -e "${CYAN} ~ Email ocultado: ${CONTACT_POINT}${RESET}"
    echo -e "${CYAN} ~ Método de recuperação: ${RECOVERY_METHOD}${RESET}"
  else
    TITLE=$(echo "$RESPONSE" | jq -r '.title // empty')
    BODY=$(echo "$RESPONSE" | jq -r '.body // empty')
    log "$RED" "$ICON_ERROR" "${TITLE}: ${BODY}"
  fi
}

# Função principal
main() {
  log "$BLUE" "$ICON_USER" "Iniciando recuperação para o usuário @$USERNAME"

  MAX_RETRIES=1
  if [ "$RETRY" = true ]; then
    MAX_RETRIES=3
  fi

  ATTEMPT=1
  while [ $ATTEMPT -le $MAX_RETRIES ]; do
    get_csrf_token
    send_recovery_request

    # Verifica se a solicitação foi bem-sucedida
    STATUS=$(echo "$RESPONSE" | jq -r '.status')
    if [ "$STATUS" == "ok" ]; then
      break
    else
      log "$YELLOW" "$ICON_INFO" "Tentativa $ATTEMPT falhou."
      if [ $ATTEMPT -lt $MAX_RETRIES ]; then
        SLEEP_TIME=$((2 ** ATTEMPT))
        log "$YELLOW" "$ICON_INFO" "Aguardando $SLEEP_TIME segundos antes da próxima tentativa..."
        sleep $SLEEP_TIME
      fi
    fi
    ATTEMPT=$((ATTEMPT + 1))
  done

  if [ "$STATUS" != "ok" ]; then
    log "$RED" "$ICON_ERROR" "Todas as tentativas falharam."
  fi

  # Remove o arquivo temporário de cookies
  rm -f "$COOKIE_JAR"
}

# Executa a função principal
main

