#!/usr/bin/env bash
set -e

echo "🌑 Atualizando pacotes..."

echo "📦 Instalando dependências do scrcpy..."
sudo apt install -y adb ffmpeg libsdl2-2.0-0 libsdl2-dev \
  ffmpeg libsdl2-image-2.0-0 gcc meson ninja-build pkg-config \
  libavcodec-dev libavformat-dev libavutil-dev libusb-1.0-0-dev \
  libv4l-dev libpulse-dev

echo "📦 Instalando scrcpy via apt (última versão disponível no repositório Debian)..."
sudo apt install -y scrcpy

# --- Verificação ---
if command -v scrcpy &>/dev/null; then
    echo "✅ scrcpy instalado com sucesso!"
    echo "Você pode rodar o scrcpy conectando seu Android via USB e digitando:"
    echo "scrcpy"
else
    echo "❌ Falha na instalação do scrcpy!"
fi