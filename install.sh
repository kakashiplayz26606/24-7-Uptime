#!/usr/bin/env bash
set -e

clear
echo "========================================"
echo "   Shadow Clouds 24/7 Uptime Installer"
echo "========================================"
echo ""

echo "Select platform:"
echo "1) GitHub / VPS (Cloudflare)"
echo "2) Google IDX (Cloudflare)"
echo "3) CodeSandbox (Preview URL)"
echo ""
read -p "Enter option (1/2/3): " OPT

# detect python
if command -v python3 >/dev/null 2>&1; then
  PY=python3
elif command -v python >/dev/null 2>&1; then
  PY=python
else
  echo "Python not found"
  exit 1
fi

# setup venv safely
if $PY -m venv .venv >/dev/null 2>&1; then
  [ -f ".venv/bin/python" ] && PY=".venv/bin/python"
fi

$PY -m pip install --upgrade pip >/dev/null 2>&1 || true
$PY -m pip install fastapi uvicorn >/dev/null 2>&1 || true

if [ "$OPT" = "1" ]; then
  echo "[+] Using GitHub/VPS mode"
  curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/github_connector.py -o connector.py

elif [ "$OPT" = "2" ]; then
  echo "[+] Using Google IDX mode"
  curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/idx_connector.py -o connector.py

elif [ "$OPT" = "3" ]; then
  echo "[+] Using CodeSandbox mode"
  curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/csb_connector.py -o connector.py
else
  echo "Invalid option"
  exit 1
fi

echo "[+] Starting backend..."
$PY connector.py &

sleep 2

if [ "$OPT" = "3" ]; then
  echo ""
  echo "✅ CodeSandbox running!"
  echo "Use the Preview URL shown by CodeSandbox."
  exit 0
fi

# cloudflare for github / idx
if [ ! -f cloudflared ]; then
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
fi

echo ""
echo "========================================"
echo " Cloudflare tunnel starting..."
echo "========================================"

./cloudflared tunnel --url http://localhost:8080
