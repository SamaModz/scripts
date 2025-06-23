#!/usr/bin/env node
const https = require("https");
require("console").clear();
const colors = {
  reset: "\x1b[0m",
  gray: "\x1b[90m",    
  yellow: "\x1b[33m",  
  green: "\x1b[32m",   
  red: "\x1b[31m",     
  blue: "\x1b[34m",    
  cyan: "\x1b[36m",    
 
};

const nerdFont = {
  check: `${colors.green} `,
  cross: `${colors.red} `,
  gear: `${colors.gray} `,
  hourglass: `${colors.yellow} `,
  lock: `${colors.green} `,
  unlock: `${colors.green} `,
  loading: `${colors.blue} `,
  email: `${colors.yellow} `,
  key: `${colors.gray} `,
  user: `${colors.cyan} `,
};

const printFilledLine = (char = "─") => {
  console.log(char.repeat(process.stdout.columns));
};

const printStatus = (message, status = "processing", icon = "gear") => {
  const colorMap = {
    processing: colors.gray,
    pending: colors.yellow,
    success: colors.green,
    error: colors.red,
    info: colors.blue,
    warning: colors.yellow,
    note: colors.gray,     
  };
  const color = colorMap[status] || colors.gray;
  const selectedIcon = nerdFont[icon] || nerdFont.gear;
  console.log(`${color}${selectedIcon} ${message}${colors.reset}`);
};

const delay = (ms, message = "") => {
  return new Promise((resolve) => {
    const frames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];
    let i = 0;
    const interval = setInterval(() => {
      process.stdout.write(`\r${colors.cyan}${frames[i]} ${message}${colors.reset}`);
      i = (i + 1) % frames.length;
    }, 100);
    setTimeout(() => {
      clearInterval(interval);
      process.stdout.write("\r" + " ".repeat(process.stdout.columns) + "\r");
      resolve();
    }, ms);
  });
};

const debugLog = (message, data = {}) => {
  if (process.env.DEBUG) {
    console.log(`${colors.gray} DEBUG: ${message}${colors.reset}`);
    if (Object.keys(data).length > 0) {
      console.log(`${colors.gray}${JSON.stringify(data, null, 2)}${colors.reset}`);
    }
  }
};

const generatePassword = (length = 14) => {
  const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@&$";
  let password = "";
  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * charset.length);
    password += charset[randomIndex];
  }
  return password;
};

const checkInstagramAccount = async (username) => {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: "www.instagram.com",
      path: `/${username}/`,
      method: "GET",
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        Referer: "https://www.instagram.com/",
        "Accept-Language": "en-US,en;q=0.9",
      },
    };
    debugLog("Making HTTP request to Instagram...", {
      url: `https://${options.hostname}${options.path}`,
    });
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        debugLog("Received response from Instagram.", {
          statusCode: res.statusCode,
          headers: res.headers,
        });
        if (res.statusCode === 200) {
          if (data.includes("Page Not Found")) {
            resolve(false);
          } else {
            resolve(true);
          }
        } else if (res.statusCode === 302) {
          const location = res.headers.location;
          debugLog("Following redirect...", {
            location,
          });
          resolve(checkInstagramAccount(username));
        } else {
          reject(new Error(`HTTP error: ${res.statusCode}`));
        }
      });
    });
    req.on("error", (error) => {
      debugLog("HTTP request failed.", {
        error: error.message,
      });
      reject(error);
    });
    req.end();
  });
};

const simulateRecovery = async () => {
  printFilledLine();
  console.log(`${colors.gray}${nerdFont.lock} Instagram Account Recovery${colors.reset}`);
  printFilledLine();
  const username = process.argv[2];
  if (!username) {
    printStatus("Error: Please provide an Instagram username.", "error", "cross");
    printFilledLine();
    return;
  }
  try {
    printStatus(`Checking if the account @${username} exists...`, "processing", "user");
    await delay(2000, "Checking account...");
    const accountExists = await checkInstagramAccount(username);
    if (!accountExists) {
      printStatus(`Error: The account @${username} does not exist.`, "error", "cross");
      printFilledLine();
      return;
    }
    printStatus(`Account @${username} found.`, "success", "check");
    await delay(1000);
    const steps = [
      {
        message: "Starting recovery process...",
        delay: 2000,
        icon: "gear",
      },
      {
        message: "Verifying email address...",
        status: "pending",
        delay: 3000,
        icon: "email",
      },
      {
        message: "Email address verified successfully.",
        status: "success",
        delay: 1000,
        icon: "check",
      },
      {
        message: "Sending recovery code to your email...",
        delay: 4000,
        icon: "email",
      },
      {
        message: "Recovery code sent. Please check your email.",
        status: "info",
        delay: 2000,
        icon: "email",
      },
      {
        message: "Waiting for recovery code input...",
        status: "pending",
        delay: 5000,
        icon: "hourglass",
      },
      {
        message: "Recovery code accepted.",
        status: "success",
        delay: 1000,
        icon: "check",
      },
      {
        message: "Resetting password...",
        delay: 3000,
        icon: "key",
      },
      {
        message: "Password reset successfully.",
        status: "success",
        delay: 1000,
        icon: "check",
      },
      {
        message: "Logging into your account...",
        delay: 2000,
        icon: "user",
      },
      {
        message: "Account recovered successfully!",
        status: "success",
        delay: 0,
        icon: "check",
      },
    ];
    for (const step of steps) {
      printStatus(step.message, step.status || "processing", step.icon);
      debugLog(`Executing step: ${step.message}`, {
        delay: step.delay,
        icon: step.icon,
      });
      await delay(step.delay, step.message);
    }

    const newPassword = generatePassword(14);
    printFilledLine();
    console.log(`${colors.green}${nerdFont.unlock} Account Recovery Summary:${colors.reset}`);
    console.log(`${colors.cyan}  Username: ${username}${colors.reset}`);
    console.log(`${colors.cyan}  New Password: ${newPassword}${colors.reset}`);
    printFilledLine();
  } catch (error) {
    printStatus(`Error: ${error.message}`, "error", "cross");
    debugLog("Error occurred during recovery process.", {
      error: error.message,
    });
    printFilledLine();
  }
};

simulateRecovery();
