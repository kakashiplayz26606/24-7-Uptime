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

# ----------------------------
# Install Python if missing
# ----------------------------
if ! command -v python3 >/dev/null 2>&1; then
  echo "[+] Installing Python..."
  sudo apt update -y
  sudo apt install -y python3 python3-venv python3-pip
fi

# ----------------------------
# Create virtual environment
# ----------------------------
if [ ! -d ".venv" ]; then
  echo "[+] Creating virtual environment..."
  python3 -m venv .venv
fi

# Activate venv
source .venv/bin/activate

# ----------------------------
# Install Python deps safely
# ----------------------------
echo "[+] Installing Python packages inside venv..."
pip install --upgrade pip
pip install fastapi uvicorn

# ----------------------------
# Install cloudflared
# ----------------------------
if ! command -v cloudflared >/dev/null 2>&1; then
  echo "[+] Installing Cloudflare Tunnel..."
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
  sudo mv cloudflared /usr/local/bin/cloudflared
fi

# ----------------------------
# Download connector
# ----------------------------
echo "[+] Downloading connector..."
curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/connector.py -o connector.py

# ----------------------------
# Start backend
# ----------------------------
echo "[+] Starting FastAPI backend..."
nohup .venv/bin/python connector.py > connector.log 2>&1 &

sleep 2

# ----------------------------
# Start Cloudflare Tunnel
# ----------------------------
echo ""
echo "========================================"
echo " 🌍 YOUR PUBLIC 24/7 URL WILL APPEAR BELOW"
echo "========================================"
echo ""

cloudflared tunnel --url http://localhost:8080
