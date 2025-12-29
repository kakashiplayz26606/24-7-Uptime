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

# -----------------------------------
# Detect python
# -----------------------------------
if command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON=python
else
  echo "❌ Python not found. Install Python first."
  exit 1
fi

# -----------------------------------
# Try creating venv (safe)
# -----------------------------------
USE_VENV=false

if $PYTHON -m venv .venv >/dev/null 2>&1; then
  if [ -f ".venv/bin/python" ]; then
    USE_VENV=true
    PYTHON=".venv/bin/python"
    echo "[✓] Virtual environment ready"
  fi
fi

# -----------------------------------
# Install dependencies
# -----------------------------------
echo "[+] Installing Python packages..."

if [ "$USE_VENV" = true ]; then
  "$PYTHON" -m pip install --upgrade pip
  "$PYTHON" -m pip install fastapi uvicorn
else
  echo "[!] Falling back to user install (no venv)"
  $PYTHON -m pip install --user fastapi uvicorn || true
fi

# -----------------------------------
# Download connector
# -----------------------------------
echo "[+] Downloading connector..."
curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/connector.py -o connector.py

# -----------------------------------
# Install cloudflared locally (NO sudo)
# -----------------------------------
if [ ! -f "./cloudflared" ]; then
  echo "[+] Downloading Cloudflare Tunnel..."
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
fi

# -----------------------------------
# Start backend
# -----------------------------------
echo "[+] Starting FastAPI backend..."
nohup $PYTHON connector.py > connector.log 2>&1 &

sleep 2

# -----------------------------------
# Start Cloudflare Tunnel
# -----------------------------------
echo ""
echo "========================================"
echo " 🌍 YOUR PUBLIC 24/7 URL WILL APPEAR BELOW"
echo "========================================"
echo ""

./cloudflared tunnel --url http://localhost:8080
