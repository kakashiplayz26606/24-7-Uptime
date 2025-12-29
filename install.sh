#!/usr/bin/env bash
set -e

clear
echo "========================================"
echo "   Shadow Clouds 24/7 Uptime Installer"
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

# -----------------------------
# Python
# -----------------------------
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "Python not found"
  exit 1
fi

# -----------------------------
# Virtual env (safe)
# -----------------------------
if $PY -m venv .venv >/dev/null 2>&1; then
  if [ -f ".venv/bin/python" ]; then
    PY=".venv/bin/python"
  fi
fi

# -----------------------------
# Install deps
# -----------------------------
echo "[+] Installing Python dependencies..."
$PY -m pip install --upgrade pip >/dev/null 2>&1 || true
$PY -m pip install fastapi uvicorn >/dev/null 2>&1 || true

# -----------------------------
# Download backend
# -----------------------------
echo "[+] Downloading connector.py..."
curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/connector.py -o connector.py

# -----------------------------
# Start backend on FIXED port 8080
# -----------------------------
echo "[+] Starting backend on http://localhost:8080"
nohup $PY connector.py > backend.log 2>&1 &

sleep 3

# -----------------------------
# Download cloudflared
# -----------------------------
if [ ! -f "./cloudflared" ]; then
  echo "[+] Downloading cloudflared..."
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
fi

# -----------------------------
# Start Cloudflare tunnel
# -----------------------------
echo ""
echo "========================================"
echo " Cloudflare tunnel starting..."
echo " Copy the URL shown below"
echo "========================================"
echo ""

./cloudflared tunnel --url http://localhost:8080
