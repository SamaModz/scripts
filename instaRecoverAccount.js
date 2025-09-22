#!/usr/bin/env node
import axios from 'axios';
import querystring from 'querystring';
import fs from 'fs';
import readline from 'readline';
import winston from 'winston';
import process from 'process';
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.colorize(),
    winston.format.simple()
  ),
  transports: [new winston.transports.Console()]
});

const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  gray: '\x1b[90m',
  orange: '\x1b[38;5;208m'
};


const { reset, red, green, blue, gray, orange } = colors;

const icons = {
  success: '\u2714',
  error: '\u2716',
  warn: '\u26A0',
  info: '\u2139',
  debug: '\uD83D\uDD0E'
};

const log = {
  success: (msg) => logger.info(`${green}${icons.success} ${msg}${reset}`),
  error: (msg) => logger.error(`${red}${icons.error} ${msg}${reset}`),
  warn: (msg) => logger.warn(`${orange}${icons.warn} ${msg}${reset}`),
  info: (msg) => logger.info(`${blue}${icons.info} ${msg}${reset}`),
  debug: (msg) => logger.debug(`${gray}${icons.debug} ${msg}${reset}`)
};


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

function generateEncPassword(password) {
  return `#PWD_INSTAGRAM_BROWSER:0:${Date.now()}:${password}`;
}

async function handle2FA() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  const code = await new Promise((resolve) => {
    rl.question(`${blue}${icons.info} 2FA Code: ${reset}`, (input) => {
      rl.close();
      resolve(input);
    });
  });

  log.info('Verifying 2FA code...');
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
      log.success('2FA authentication successful!');
    } else {
      throw new Error('Invalid 2FA code');
    }
  } catch (error) {
    log.error(`Error verifying 2FA code: ${error.message}`);
    throw error;
  }
}

function saveSession(cookies) {
  const sessionData = {
    cookies,
    timestamp: new Date().toISOString()
  };
  fs.writeFileSync('session.json', JSON.stringify(sessionData), { mode: 0o600 });
  log.info('Session saved successfully in session.json');
}

function validateHeaders(headers) {
  if (!headers['ig-set-authorization']) {
    throw new Error('Invalid server response');
  }
}

async function main() {
  try {
    if (!username) throw new Error('Username is required');
    const password = await promptPassword('Password: ');
    if (proxy) {
      const [host, port] = proxy.split(':');
      axios.defaults.proxy = { host, port };
      log.debug(`Using proxy: ${proxy}`);
    }
    log.info('Starting handshake...');
    const { headers } = await axios.get('https://www.instagram.com/accounts/login/', {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9'
      },
      withCredentials: true
    });
    const csrfToken = headers['set-cookie']
      .find(c => c.startsWith('csrftoken='))
      .split(';')[0]
      .split('=')[1];
    log.info('Authenticating...');
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
    log.debug(`Status: ${response.status} | Time: ${response.duration}ms`);
    switch (response.status) {
      case 200:
        if (response.data.authenticated) {
          log.success('Authentication successful!');
          validateHeaders(response.headers);
          saveSession(response.headers['set-cookie']);
        } else if (response.data.requires_2fa) {
          log.warn('2FA verification required');
          await handle2FA();
        } else {
          throw new Error('Invalid credentials');
        }
        break;
      case 400:
        throw new Error('Invalid request - possible temporary block');
      case 429:
        throw new Error('Rate limit exceeded - please try again later');
      default:
        throw new Error(`Unexpected response: ${response.status}`);
    }
  } catch (error) {
    if (error.response) {
      log.error(`HTTP ${error.response.status} | ${error.response.data.message || ''}`);
      verbose && console.error(error.response.data);
    } else if (error.request) {
      log.error(`Timeout/connection error: ${error.message}`);
    } else {
      log.error(`Internal error: ${error.message}`);
    }
    process.exit(1);
  }
}

main();
