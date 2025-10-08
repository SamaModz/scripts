#!/usr/bin/env bash
# Minimal Inline Launcher com histórico (readline)
# Termux + Void Linux

set -euo pipefail

CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/launcher"
CFG_FILE="$CFG_DIR/apps.conf"
HIST_FILE="$CFG_DIR/history"

mkdir -p "$CFG_DIR"
touch "$HIST_FILE"

# apps.conf default
if [ ! -s "$CFG_FILE" ]; then
  cat > "$CFG_FILE" <<EOF
  # apps.conf (nome|comando)
  Terminal|bash
  Editor|nvim
  Browser|firefox
EOF
fi

is_termux() { command -v termux-open-url >/dev/null 2>&1 || false; }
open_url() {
  url="$1"
  if is_termux; then termux-open-url "$url"; else xdg-open "$url"; fi >/dev/null 2>&1 || true
  }

read_apps() {
  APP_NAMES=(); APP_CMDS=()
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    IFS='|' read -r name cmd <<<"$line"
    APP_NAMES+=("$name"); APP_CMDS+=("$cmd")
  done <"$CFG_FILE"
}
read_apps

animate() {
  msg="$1"; delay="${2:-0.03}"
  for ((i=0;i<${#msg};i++)); do
    printf "%s" "${msg:$i:1}"
    sleep "$delay"
  done
  printf "\n"
}

calc() {
  expr="$*"
  [ -z "$expr" ] && { printf "expr> "; read -e expr; }
  result=$(echo "scale=8; $expr" | bc -l 2>/dev/null || echo "erro")
  animate "=$result" 0.003
}

wiki() {
  q="$*"
  [ -z "$q" ] && { printf "wiki> "; read -e q; }
  url="https://pt.wikipedia.org/wiki/$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$q")"
  animate "🔗 wikipedia: $q" 0.003
  open_url "$url"
}

open_cmd() {
  if [ "$1" = "ig" ]; then shift; url="https://instagram.com/$1"
  else url="$1"; [[ ! "$url" =~ ^https?:// ]] && url="https://$url"; fi
  animate "🔗 abrindo: $url" 0.003
  open_url "$url"
}

launch_app() {
  n=$1
  name="${APP_NAMES[$n]}"; cmd="${APP_CMDS[$n]}"
  animate "▶ $name" 0.003
  setsid sh -c "$cmd" >/dev/null 2>&1 &
}

prompt() { printf "\nλ "; }

animate "Inline Launcher pronto (!calc !open !wiki !reload !bye)" 0.0001

while true; do
  prompt
  # readline com histórico
  read -e -p "" input
  [[ -n "$input" ]] && echo "$input" >> "$HIST_FILE"
  history -r "$HIST_FILE"  # recarrega histórico no readline

  case "$input" in
    "!bye") animate "saindo..." 0.05; exit 0 ;;
    "!reload") read_apps; animate "config recarregada." 0.003 ;;
    "!calc "*) calc "${input:6}" ;;
    "!calc") calc ;;
    "!open "*) open_cmd ${input:6} ;;
    "!wiki "*) wiki "${input:6}" ;;
    [0-9]*) n=$((input-1))
      [ "$n" -ge 0 ] && [ "$n" -lt "${#APP_NAMES[@]}" ] && launch_app "$n" ;;
      "") continue ;;
      *) animate "atalhos: !calc !open !wiki !reload !bye | ou número de app" 0.001 ;;
    esac
  done
