























const colors = {red: "\x1b[1;91m",green: "\x1b[1;92m",yellow: "\x1b[1;93m",blue: "\x1b[1;94m",pink: "\x1b[1;95m",white: "\x1b[1;96m",reset: "\x1b[0m"}
const tag = (color) => `${colors.white}[${color}!${colors.white}]${colors.reset} `;
const logs = {
  success: tag(colors.green),
  warn: tag(colors.yellow),
  error: tag(colors.red),
  debug: tag(colors.pink),
};


