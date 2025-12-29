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

# -----------------------------
# Detect python
# -----------------------------
if command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON=python
else
  echo "❌ Python not found."
  exit 1
fi

# -----------------------------
# Try venv (safe)
# -----------------------------
USE_VENV=false
if $PYTHON -m venv .venv >/dev/null 2>&1; then
  if [ -f ".venv/bin/python" ]; then
    PYTHON=".venv/bin/python"
    USE_VENV=true
  fi
fi

# -----------------------------
# Install deps
# -----------------------------
echo "[+] Installing Python packages..."
$PYTHON -m pip install --upgrade pip >/dev/null 2>&1 || true
$PYTHON -m pip install fastapi uvicorn >/dev/null 2>&1 || true

# -----------------------------
# Download connector
# -----------------------------
curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/connector.py -o connector.py

# -----------------------------
# Download cloudflared locally
# -----------------------------
if [ ! -f "./cloudflared" ]; then
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
fi

# -----------------------------
# Start backend
# -----------------------------
nohup $PYTHON connector.py > connector.log 2>&1 &

# -----------------------------
# Wait for backend (CRITICAL)
# -----------------------------
echo "[+] Waiting for backend on port 8080..."
for i in {1..20}; do
  if curl -s http://127.0.0.1:8080 >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

# -----------------------------
# Start cloudflared quietly & extract URL
# -----------------------------
URL=$(./cloudflared tunnel --url http://localhost:8080 2>&1 \
  | grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare.com" \
  | head -n 1)

# -----------------------------
# Clean output
# -----------------------------
clear
echo "========================================"
echo "   Shadow Clouds 24/7 Uptime"
echo "========================================"
echo ""
echo "Here is your Cloudflare URL:"
echo ""
echo "$URL"
echo ""
echo "Keep this terminal open."
echo "========================================"
