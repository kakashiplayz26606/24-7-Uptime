#!/bin/bash
clear

echo "========================================"
echo " ________  ___  ___  ________  ________  ________  ___       __           ________  ___       ________  ___  ___  ________  ________      "
echo "|\   ____\|\  \|\  \|\   __  \|\   ___ \|\   __  \|\  \     |\  \        |\   ____\|\  \     |\   __  \|\  \|\  \|\   ___ \|\   ____\     "
echo "\ \  \___|\ \  \\\  \ \  \|\  \ \  \_|\ \ \  \|\  \ \  \    \ \  \       \ \  \___|\ \  \    \ \  \|\  \ \  \\\  \ \  \_|\ \ \  \___|_    "
echo " \ \_____  \ \   __  \ \   __  \ \  \ \\ \ \  \\\  \ \  \  __\ \  \       \ \  \    \ \  \    \ \  \\\  \ \  \\\  \ \  \ \\ \ \_____  \   "
echo "  \|____|\  \ \  \ \  \ \  \ \  \ \  \_\\ \ \  \\\  \ \  \|\__\_\  \       \ \  \____\ \  \____\ \  \\\  \ \  \\\  \ \  \_\\ \|____|\  \  "
echo "    ____\_\  \ \__\ \__\ \__\ \__\ \_______\ \_______\ \____________\       \ \_______\ \_______\ \_______\ \_______\ \_______\____\_\  \ "
echo "   |\_________\|__|\|__|\|__|\|__|\|_______|\|_______|\|____________|        \|_______|\|_______|\|_______|\|_______|\|_______|\_________\"
echo "   \|_________|                                                                                                               \|_________|"
echo ""
echo "      Shadow Clouds 24/7 Uptime"
echo "========================================"
echo ""
echo "Choose platform:"
echo "1) GitHub"
echo "2) Google IDX"
echo "3) CodeSandbox"
echo ""
read -p "Enter option (1/2/3): " OPTION

echo ""
echo "▶ Setting up environment..."

# -------------------------
# Python install
# -------------------------
if ! command -v python3 >/dev/null 2>&1; then
  echo "Installing Python..."
  apt update -y && apt install -y python3 python3-pip
fi

# -------------------------
# Pip deps
# -------------------------
pip3 install --upgrade pip >/dev/null
pip3 install fastapi uvicorn >/dev/null

# -------------------------
# Cloudflare Tunnel
# -------------------------
if ! command -v cloudflared >/dev/null 2>&1; then
  echo "Installing Cloudflare Tunnel..."
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
  mv cloudflared /usr/local/bin/cloudflared
fi

# -------------------------
# Download connector
# -------------------------
echo "Downloading connector..."
curl -fsSL https://raw.githubusercontent.com/YOURNAME/REPO/main/connector.py -o connector.py

# -------------------------
# Start FastAPI backend
# -------------------------
echo "Starting backend..."
nohup python3 connector.py > connector.log 2>&1 &

sleep 2

# -------------------------
# Start Cloudflare Tunnel
# -------------------------
echo ""
echo "========================================"
echo " Your public 24/7 URL will appear below "
echo "========================================"
echo ""

./cloudflared tunnel --url http://localhost:8080
