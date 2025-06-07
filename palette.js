const inputColor = process.argv[2];
const color = require('color');
const resetAnsi = '\x1b[0m';
const dangerAnsi = '\x1b[1;91m';
const warningAnsi = '\x1b[1;93m';
const invalidAnsi = '\x1b[38;2;240;128;128m';

// I already started this code, too lazy to finish it 🫩
const showError = (type, message) => {
  const styles = {
    danger: `${dangerAnsi}`,
    warning: `${warningAnsi}`,
    invalid: `${invalidAnsi}`
  };
  const prefix = styles[type] || '⚠️';
  console.error(`[${prefix}${type.toUpperCase()}${resetAnsi}] ${message}`);
};
if (!inputColor) {
  showError('danger', 'Usage: node tailwindColorPalette.js <color>');
  process.exit(1);
}

let baseColor;

try {
  baseColor = color(inputColor);
} catch (e) {
  if (e.message.includes('Expected a string')) {
    showError('invalid', 'The color input must be a valid string (e.g., "#FF5733" or "rgb(255, 87, 51)").');
  } else {
    showError('danger', 'Invalid color format. Please provide a valid hex, RGB, or other supported color format.');
  }
  process.exit(1);
}
if (!process.stdout.isTTY) {
  showError('warning', 'Your terminal may not support ANSI escape codes. Colors may not display correctly.');
}
const levels = {
  50: 90,
  100: 80,
  200: 70,
  300: 60,
  400: 50,
  500: 40,
  600: 30,
  700: 20,
  800: 10,
};

const palette = {};
for (const level in levels) {
  const lightness = levels[level];
  try {
    const adjustedColor = baseColor.lightness(lightness).hex();
    palette[level] = adjustedColor;
  } catch (e) {
    showError('danger', `Failed to calculate the color for level ${level}. Possible issues with lightness value: ${lightness}.`);
    process.exit(1);
  }
}
const fill = () => {
  const lengthLine = process.stdout.columns;
  console.log('—'.repeat(Math.floor(lengthLine / 2)));
};
const showColorWithAnsi = (hexColor, text) => {
  try {
    const r = parseInt(hexColor.slice(1, 3), 16);
    const g = parseInt(hexColor.slice(3, 5), 16);
    const b = parseInt(hexColor.slice(5, 7), 16);
    return `\x1b[48;2;${r};${g};${b}m\x1b[30m ${text} \x1b[0m`;
  } catch (e) {
    showError('warning', `Failed to display color "${hexColor}". Possible issues with color conversion.`);
    return text;
  }
};

fill()
console.log('$palette (')
for (const level in palette) {
  const colorDisplay = showColorWithAnsi(palette[level], `${level}: ${palette[level]}`);
  console.log(`  ${colorDisplay}`);
}
console.log(');');
