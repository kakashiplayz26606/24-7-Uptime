#!/usr/bin/env bash
set -e

APP="Shadow Clouds 24/7"
LOG="cloudflared.log"
URL_FILE=".cloudflare_url"
PID_FILE=".cloudflared.pid"

clear
echo "========================================"
echo "   $APP"
echo "========================================"
echo ""

# -----------------------------
# Python detection
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
  [ -f ".venv/bin/python" ] && PY=".venv/bin/python"
fi

# -----------------------------
# Dependencies
# -----------------------------
$PY -m pip install --upgrade pip >/dev/null 2>&1 || true
$PY -m pip install fastapi uvicorn >/dev/null 2>&1 || true

# -----------------------------
# Download connector
# -----------------------------
curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/connector.py -o connector.py

# -----------------------------
# Find free port
# -----------------------------
PORT=$($PY - <<'PY'
import socket
s=socket.socket()
s.bind(("",0))
print(s.getsockname()[1])
s.close()
PY
)

echo "[✓] Backend port: $PORT"

# -----------------------------
# Start backend
# -----------------------------
nohup $PY connector.py --port "$PORT" > backend.log 2>&1 &

# -----------------------------
# Wait until backend actually responds
# -----------------------------
echo "[+] Waiting for backend..."
for i in {1..40}; do
  if curl -s "http://127.0.0.1:$PORT/" >/dev/null; then
    echo "[✓] Backend is live"
    break
  fi
  sleep 0.5
done

# -----------------------------
# Download cloudflared
# -----------------------------
if [ ! -f "./cloudflared" ]; then
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
fi

# -----------------------------
# Start cloudflared
# -----------------------------
rm -f "$LOG" "$URL_FILE"

( ./cloudflared tunnel --url "http://127.0.0.1:$PORT" > "$LOG" 2>&1 ) &
echo $! > "$PID_FILE"

# -----------------------------
# Wait for URL
# -----------------------------
for i in {1..60}; do
  URL=$(grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare.com" "$LOG" | head -n 1)
  if [ -n "$URL" ]; then
    echo "$URL" > "$URL_FILE"
    break
  fi
  sleep 1
done

# -----------------------------
# Final output
# -----------------------------
clear
echo "========================================"
echo "   Shadow Clouds 24/7 Running"
echo "========================================"
echo ""

if [ -f "$URL_FILE" ]; then
  echo "Your Cloudflare URL:"
  echo ""
  cat "$URL_FILE"
else
  echo "❌ Tunnel started but URL not detected."
  echo "Check cloudflared.log"
fi

echo ""
echo "Options:"
echo "  r → restart tunnel"
echo "  q → quit"
echo "========================================"

# -----------------------------
# Controls
# -----------------------------
while true; do
  read -n1 -s key
  case "$key" in
    r|R)
      echo ""
      echo "Restarting tunnel..."

      kill "$(cat $PID_FILE)" 2>/dev/null || true
      rm -f "$LOG" "$URL_FILE"

      ( ./cloudflared tunnel --url "http://127.0.0.1:$PORT" > "$LOG" 2>&1 ) &
      echo $! > "$PID_FILE"

      sleep 3
      URL=$(grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare.com" "$LOG" | head -n 1)

      clear
      echo "========================================"
      echo "   Shadow Clouds 24/7 Running"
      echo "========================================"
      echo ""
      echo "Your Cloudflare URL:"
      echo ""
      echo "$URL"
      echo ""
      echo "Press r to restart | q to quit"
      ;;
    q|Q)
      kill "$(cat $PID_FILE)" 2>/dev/null || true
      exit 0
      ;;
  esac
done
