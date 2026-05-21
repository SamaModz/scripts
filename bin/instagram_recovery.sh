#!/bin/bash

# Nome do script
SCRIPT_NAME="instagram_recovery.sh"

# Variáveis de configuração
INSTAGRAM_URL="https://www.instagram.com"
RECOVERY_URL="${INSTAGRAM_URL}/accounts/password/reset/"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

# Arquivos temporários e de log
LOG_FILE="${SCRIPT_NAME%.sh}.log"
COOKIE_JAR="${SCRIPT_NAME%.sh}.cookies"

# --- Funções de Logging e Tratamento de Erros ---

# Função para registrar mensagens no log e na saída padrão
log_message() {
    local type="$1" # INFO, WARN, ERROR, SUCCESS
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] [${type}] ${message}" | tee -a "${LOG_FILE}"
}

# Função para lidar com erros e sair do script
error_exit() {
    local message="$1"
    log_message "ERROR" "${message}"
    log_message "ERROR" "O script será encerrado."
    exit 1
}

# Função para limpar arquivos temporários
cleanup() {
    log_message "INFO" "Limpando arquivos temporários..."
    rm -f "${COOKIE_JAR}"
}

# Registrar a função cleanup para ser executada na saída do script
trap cleanup EXIT

# --- Início do Script ---
log_message "INFO" "Iniciando o script de assistência à recuperação de conta do Instagram."

# Exemplo de uso para o usuário sama_modz
USERNAME="sama_modz"
log_message "INFO" "O script irá auxiliar na recuperação da conta para o usuário: ${USERNAME}"

# Tentar abrir o navegador automaticamente (para ambientes com GUI)
# Em ambientes headless (como este sandbox), isso falhará, mas o script continuará fornecendo a URL e instruções.
log_message "INFO" "Tentando abrir a página de recuperação do Instagram no seu navegador padrão (pode não funcionar em ambientes sem GUI)."

# Detectar ambiente gráfico para tentar abrir o navegador
if command -v xdg-open &> /dev/null && [ -n "$DISPLAY" ]; then
    xdg-open "${RECOVERY_URL}" &> /dev/null
    if [ $? -eq 0 ]; then
        log_message "INFO" "Página de recuperação aberta com sucesso no navegador padrão."
    else
        log_message "WARN" "Falha ao abrir o navegador automaticamente. Por favor, abra a URL manualmente."
    fi
elif command -v open &> /dev/null && [ "$(uname)" == "Darwin" ]; then
    open "${RECOVERY_URL}" &> /dev/null
    if [ $? -eq 0 ]; then
        log_message "INFO" "Página de recuperação aberta com sucesso no navegador padrão."
    else
        log_message "WARN" "Falha ao abrir o navegador automaticamente. Por favor, abra a URL manualmente."
    fi
else
    log_message "WARN" "Nenhum comando de abertura de navegador gráfico encontrado ou ambiente sem GUI detectado."
    log_message "WARN" "Por favor, copie e cole a URL abaixo no seu navegador manualmente."
fi

log_message "INFO" "URL para recuperação: ${RECOVERY_URL}"

log_message "SUCCESS" "Por favor, siga as instruções abaixo para continuar a recuperação:"
log_message "INFO" "------------------------------------------------------------------------------------------------------------------------"
log_message "INFO" "**Instruções Manuais para Recuperação da Conta do Instagram:**"
log_message "INFO" "1. Abra a URL fornecida acima em seu navegador."
log_message "INFO" "2. Na página \'Encontre sua conta\', digite o nome de usuário \'${USERNAME}\' (ou seu e-mail/telefone associado) no campo indicado."
log_message "INFO" "3. Clique em \'Continuar\'."
log_message "INFO" "4. O Instagram pode apresentar desafios de segurança (ex: CAPTCHA, confirmação de identidade). Resolva-os manualmente."
log_message "INFO" "5. Após passar pelos desafios, você deverá ver opções de recuperação, como \'Obter link por e-mail\' ou \'Obter código por SMS\'."
log_message "INFO" "6. Selecione a opção \'Obter link por e-mail\' para que o Instagram envie o link de redefinição para o seu e-mail cadastrado."
log_message "INFO" "7. Verifique sua caixa de entrada (e pasta de spam) para o e-mail do Instagram e siga as instruções para redefinir sua senha."
log_message "INFO" "------------------------------------------------------------------------------------------------------------------------"

log_message "INFO" "Script de assistência à recuperação de conta do Instagram concluído. Aguardando sua ação manual."
