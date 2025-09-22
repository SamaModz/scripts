#!/bin/bash

PORT=8080

# Função para detectar Content-Type por extensão
get_mime_type() {
  case "$1" in
    *.html) echo "text/html" ;;
    *.htm)  echo "text/html" ;;
    *.css)  echo "text/css" ;;
    *.js)   echo "application/javascript" ;;
    *.json) echo "application/json" ;;
    *.png)  echo "image/png" ;;
    *.jpg|*.jpeg) echo "image/jpeg" ;;
    *.gif)  echo "image/gif" ;;
    *.apk)  echo "application/vnd.android.package-archive" ;;
    *)      echo "application/octet-stream" ;;
  esac
}

# Seleção de arquivo/pasta via dialog
TARGET=$(dialog --stdout --title "🌙 Escolha arquivo ou pasta" --fselect "$HOME/" 20 60)

clear
if [ -z "$TARGET" ]; then
  echo "❌ Nada selecionado. Saindo..."
  exit 1
fi

echo "📂 Servindo '$TARGET' em http://localhost:$PORT"
echo "❌ CTRL+C para parar"

if [ -d "$TARGET" ]; then
  # Servir diretório inteiro
  while true; do
    {
      read req
      FILE=$(echo "$req" | awk '{print $2}')
      [ "$FILE" = "/" ] && FILE="/index.html"

      FILEPATH="$TARGET$FILE"
      if [ -f "$FILEPATH" ]; then
        MIME=$(get_mime_type "$FILEPATH")
        echo -e "HTTP/1.1 200 OK\r"
        echo -e "Content-Type: $MIME\r"
        echo -e "\r"
        cat "$FILEPATH"
      else
        echo -e "HTTP/1.1 404 Not Found\r"
        echo -e "Content-Type: text/plain\r"
        echo -e "\r"
        echo "404 - File Not Found"
      fi
    } | nc -l -p "$PORT" -q 1
done
else
  # Servir apenas um arquivo
  MIME=$(get_mime_type "$TARGET")
  while true; do
    {
      echo -e "HTTP/1.1 200 OK\r"
      echo -e "Content-Type: $MIME\r"
      echo -e "\r"
      cat "$TARGET"
    } | nc -l -p "$PORT" -q 1
done
fi
