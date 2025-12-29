#!/usr/bin/env bash
set -e

clear

echo "========================================"
echo "   Shadow Clouds 24/7 Uptime Installer  "
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
sleep 1

# -------------------------
# Install Python
# -------------------------
if ! command -v python3 >/dev/null 2>&1; then
  echo "[+] Installing Python..."
  sudo apt update -y
  sudo apt install -y python3 python3-pip
fi

# -------------------------
# Install Python deps
# -------------------------
echo "[+] Installing Python packages..."
python3 -m pip install --upgrade pip >/dev/null
python3 -m pip install fastapi uvicorn >/dev/null

# -------------------------
# Install Cloudflared
# -------------------------
if ! command -v cloudflared >/dev/null 2>&1; then
  echo "[+] Installing Cloudflare Tunnel..."
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
  sudo mv cloudflared /usr/local/bin/cloudflared
fi

# -------------------------
# Download connector
# -------------------------
echo "[+] Downloading connector..."
curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/connector.py -o connector.py

# -------------------------
# Start backend
# -------------------------
echo "[+] Starting FastAPI backend..."
nohup python3 connector.py > connector.log 2>&1 &

sleep 2

# -------------------------
# Start Cloudflare Tunnel
# -------------------------
echo ""
echo "========================================"
echo " 🌍 Your public 24/7 URL will appear below"
echo "========================================"
echo ""

cloudflared tunnel --url http://localhost:8080
