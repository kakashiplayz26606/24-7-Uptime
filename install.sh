#!/usr/bin/env bash
set -e

clear
echo "========================================"
echo "   Shadow Clouds 24/7 Uptime Installer"
echo "========================================"
echo ""

echo "Select platform:"
echo "1) GitHub / VPS (Cloudflare)"
echo "2) Google IDX"
echo "3) CodeSandbox"
echo ""
read -p "Enter option (1/2/3): " OPTION

echo ""
echo "▶ Setting up environment..."

# Detect python
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "❌ Python not found"
  exit 1
fi

# Create venv safely
if $PY -m venv .venv >/dev/null 2>&1; then
  [ -f ".venv/bin/python" ] && PY=".venv/bin/python"
fi

# Install deps
$PY -m pip install --upgrade pip >/dev/null 2>&1 || true
$PY -m pip install fastapi uvicorn >/dev/null 2>&1 || true

# Download connector
echo "[+] Downloading connector..."
curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/connector.py -o connector.py

# -----------------------
# CODE SANDBOX MODE
# -----------------------
if [ "$OPTION" = "3" ]; then
  echo ""
  echo "✅ CodeSandbox mode enabled"
  echo "----------------------------------------"
  echo "➡ After server starts:"
  echo "   Open the Preview / Ports tab"
  echo "   Open port 8080"
  echo ""
  echo "Use that URL for 24/7 pinging"
  echo "----------------------------------------"
  echo ""

  exec $PY connector.py
fi

# -----------------------
# IDX / VPS MODE
# -----------------------
echo "[+] Starting backend on port 8080..."
$PY connector.py &

sleep 2

# Install cloudflared
if [ ! -f cloudflared ]; then
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
fi

echo ""
echo "========================================"
echo " Cloudflare tunnel starting..."
echo "========================================"

./cloudflared tunnel --url http://localhost:8080
