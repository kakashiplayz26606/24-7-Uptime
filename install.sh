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
sleep 1

# -----------------------------
# Detect Python
# -----------------------------
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "❌ Python not found"
  exit 1
fi

# -----------------------------
# Ensure pip works (codesandbox fix)
# -----------------------------
echo "[+] Ensuring pip..."
$PY -m ensurepip --default-pip >/dev/null 2>&1 || true

# -----------------------------
# Install deps (USER MODE)
# -----------------------------
echo "[+] Installing Python dependencies (this may take 1–2 minutes)..."
$PY -m pip install --user --upgrade pip
$PY -m pip install --user fastapi uvicorn

# -----------------------------
# Verify install
# -----------------------------
echo "[+] Verifying FastAPI..."
$PY - <<'PY'
import fastapi, uvicorn
print("FastAPI OK")
PY

# -----------------------------
# Download connector
# -----------------------------
echo "[+] Downloading connector..."
curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/connector.py -o connector.py

# -----------------------------
# CodeSandbox mode
# -----------------------------
if [ "$OPTION" = "3" ]; then
  echo ""
  echo "✅ CodeSandbox mode enabled"
  echo "----------------------------------------"
  echo "➡ After server starts:"
  echo "   Open Ports / Preview"
  echo "   Open port 8080"
  echo "➡ Use /ping endpoint for uptime"
  echo "----------------------------------------"
  echo ""
  sleep 2
  exec $PY connector.py
fi

# -----------------------------
# IDX / VPS mode
# -----------------------------
echo "[+] Starting backend on port 8080..."
$PY connector.py &

sleep 3

# -----------------------------
# Install cloudflared
# -----------------------------
if [ ! -f cloudflared ]; then
  echo "[+] Downloading cloudflared..."
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
fi

echo ""
echo "========================================"
echo " Cloudflare tunnel starting..."
echo "========================================"

./cloudflared tunnel --url http://localhost:8080
