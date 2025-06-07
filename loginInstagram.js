#!/usr/bin/env node
const axios = require('axios');
const querystring = require('querystring');
const fs = require('fs');
const readline = require('readline');
const dotenv = require('dotenv');
const winston = require('winston');

dotenv.config();

// Configuração do logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.colorize(),
    winston.format.simple()
  ),
  transports: [new winston.transports.Console()]
});

// Cores personalizadas
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  gray: '\x1b[90m',
  orange: '\x1b[38;5;208m'
};

// Desestruturação das cores
const { reset, red, green, yellow, blue, gray, orange } = colors;

// Ícones Nerd Fonts
const icons = {
  success: '',
  error: '',
  warn: '',
  info: '',
  debug: '󱂅'
};

// Helpers de exibição
const log = {
  success: (msg) => logger.info(`${green}${icons.success} ${msg}${reset}`),
  error: (msg) => logger.error(`${red}${icons.error} ${msg}${reset}`),
  warn: (msg) => logger.warn(`${orange}${icons.warn} ${msg}${reset}`),
  info: (msg) => logger.info(`${blue}${icons.info} ${msg}${reset}`),
  debug: (msg) => logger.debug(`${gray}${icons.debug} ${msg}${reset}`)
};

// Captura de argumentos da linha de comando
const args = process.argv.slice(2);
let username, proxy, verbose = false;

for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case '-u':
    case '--username':
      username = args[i + 1];
      break;
    case '-p':
    case '--proxy':
      proxy = args[i + 1];
      break;
    case '-v':
    case '--verbose':
      verbose = true;
      logger.level = 'debug';
      break;
  }
}

// Função para capturar a senha de forma segura
async function promptPassword(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question(`${blue}${icons.info} ${question}${reset}`, (password) => {
      rl.close();
      resolve(password);
    });
    rl._writeToOutput = function _writeToOutput(stringToWrite) {
      if (stringToWrite !== `${blue}${icons.info} ${question}${reset}`) {
        rl.output.write('*');
      } else {
        rl.output.write(stringToWrite);
      }
    };
  });
}

// Gerar encrypted password
function generateEncPassword(password) {
  return `#PWD_INSTAGRAM_BROWSER:0:${Date.now()}:${password}`;
}

// Função para lidar com 2FA
async function handle2FA() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  const code = await new Promise((resolve) => {
    rl.question(`${blue}${icons.info}  Código 2FA:${reset}`, (input) => {
      rl.close();
      resolve(input);
    });
  });

  // Enviar código para endpoint de verificação
  log.info('Verificando código 2FA...');
  try {
    const response = await axios.post(
      'https://www.instagram.com/api/v1/web/accounts/login/two_factor/',
      querystring.stringify({
        verification_code: code,
        username
      }),
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRFToken': csrfToken,
          'X-Instagram-AJAX': 'd3d3a9d7d2',
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': 'https://www.instagram.com/accounts/login/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
        withCredentials: true
      }
    );

    if (response.data.authenticated) {
      log.success('Autenticação 2FA bem-sucedida!');
    } else {
      throw new Error('Código 2FA inválido');
    }
  } catch (error) {
    log.error(`Erro ao verificar código 2FA: ${error.message}`);
    throw error;
  }
}

// Função para salvar sessão
function saveSession(cookies) {
  const sessionData = {
    cookies,
    timestamp: new Date().toISOString()
  };
  fs.writeFileSync('session.json', JSON.stringify(sessionData), { mode: 0o600 });
  log.info('Sessão salva com sucesso em session.json');
}

// Função para validar headers
function validateHeaders(headers) {
  if (!headers['ig-set-authorization']) {
    throw new Error('Resposta inválida do servidor');
  }
}

async function main() {
  try {
    // Validação inicial
    if (!username) throw new Error('Username obrigatório');

    // Captura segura da senha
    const password = await promptPassword(' Senha: ');

    // Configuração do proxy
    if (proxy) {
      const [host, port] = proxy.split(':');
      axios.defaults.proxy = { host, port };
      log.debug(`Usando proxy: ${proxy}`);
    }

    // Fase 1: Obter CSRF Token
    log.info('Iniciando handshake...');
    const { headers } = await axios.get('https://www.instagram.com/accounts/login/', {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9'
      },
      withCredentials: true
    });

    // Extrair CSRF Token dos cookies
    const csrfToken = headers['set-cookie']
      .find(c => c.startsWith('csrftoken='))
      .split(';')[0]
      .split('=')[1];

    // Fase 2: Autenticação principal
    log.info('Autenticando...');
    const response = await axios.post(
      'https://www.instagram.com/api/v1/web/accounts/login/ajax/',
      querystring.stringify({
        username,
        enc_password: generateEncPassword(password)
      }),
      {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRFToken': csrfToken,
          'X-Instagram-AJAX': 'd3d3a9d7d2',
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': 'https://www.instagram.com/accounts/login/',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
        withCredentials: true
      }
    );

    // Processar resposta
    log.debug(`Status: ${response.status} | Tempo: ${response.duration}ms`);

    // Analisar códigos de status críticos
    switch (response.status) {
      case 200:
        if (response.data.authenticated) {
          log.success('Autenticação bem-sucedida!');
          validateHeaders(response.headers);
          saveSession(response.headers['set-cookie']);
        } else if (response.data.requires_2fa) {
          log.warn('Requer verificação 2FA');
          await handle2FA();
        } else {
          throw new Error('Credenciais inválidas');
        }
        break;
      case 400:
        throw new Error('Requisição inválida - possivel bloqueio temporário');
      case 429:
        throw new Error('Rate limit excedido - tente novamente mais tarde');
      default:
        throw new Error(`Resposta inesperada: ${response.status}`);
    }
  } catch (error) {
    // Tratamento de erros detalhado
    if (error.response) {
      log.error(`HTTP ${error.response.status} | ${error.response.data.message || ''}`);
      verbose && console.error(error.response.data);
    } else if (error.request) {
      log.error(`Timeout/conexão: ${error.message}`);
    } else {
      log.error(`Erro interno: ${error.message}`);
    }
    process.exit(1);
  }
}

main();
