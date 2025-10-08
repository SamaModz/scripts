#!/bin/bash
# html_pretty_termux_fix.sh (sem cores)

[ -z "$1" ] && { echo "Uso: $0 <URL>"; exit 1; }

URL="$1"
HTML=$(curl -s "$URL")

# Remove linhas contendo <script> ou <style> e blocos simples
HTML=$(echo "$HTML" | awk 'BEGIN{skip=0}
/<script/{skip=1} /<\/script>/{skip=0; next}
/<style/{skip=1} /<\/style>/{skip=0; next}
skip==0 {print}
')

format_line() {
  local line="$1"

  # Remove todas as tags HTML restantes e espaços em branco nas bordas
  line=$(echo "$line" | sed 's/<[^>]*>//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  echo "$line"
}

echo "$HTML" | while IFS= read -r line; do
format_line "$line"
done

