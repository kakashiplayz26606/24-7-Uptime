#!/usr/bin/env bash
set -e

APP_NAME="Shadow Clouds 24/7"
PID_FILE=".tunnel.pid"
LOG_FILE="cloudflared.log"
URL_FILE=".tunnel_url"

clear
echo "========================================"
echo "   $APP_NAME"
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
# Find Python
# -----------------------------
if command -v python3 >/dev/null 2>&1; then
  PYTHON=python3
elif command -v python >/dev/null 2>&1; then
  PYTHON=python
else
  echo "❌ Python not found"
  exit 1
fi

# -----------------------------
# Setup venv (safe)
# -----------------------------
if $PYTHON -m venv .venv >/dev/null 2>&1; then
  if [ -f ".venv/bin/python" ]; then
    PYTHON=".venv/bin/python"
  fi
fi

# -----------------------------
# Install deps
# -----------------------------
$PYTHON -m pip install --upgrade pip >/dev/null 2>&1 || true
$PYTHON -m pip install fastapi uvicorn >/dev/null 2>&1 || true

# -----------------------------
# Download backend
# -----------------------------
curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/connector.py -o connector.py

# -----------------------------
# Pick free port
# -----------------------------
PORT=$($PYTHON - <<'PY'
import socket
s=socket.socket()
s.bind(("",0))
print(s.getsockname()[1])
s.close()
PY
)

# -----------------------------
# Start backend
# -----------------------------
nohup $PYTHON connector.py --port "$PORT" > connector.log 2>&1 &

# Wait for backend
for i in {1..30}; do
  if curl -s "http://127.0.0.1:$PORT" >/dev/null 2>&1; then
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
# Start Cloudflare tunnel (background)
# -----------------------------
rm -f "$LOG_FILE" "$URL_FILE"

(
  ./cloudflared tunnel --url "http://127.0.0.1:$PORT" \
    > "$LOG_FILE" 2>&1
) &
echo $! > "$PID_FILE"

# -----------------------------
# Wait until URL appears
# -----------------------------
echo "[+] Waiting for Cloudflare URL..."

for i in {1..60}; do
  URL=$(grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare.com" "$LOG_FILE" | head -n 1)
  if [ -n "$URL" ]; then
    echo "$URL" > "$URL_FILE"
    break
  fi
  sleep 1
done

# -----------------------------
# Final UI
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
  echo "❌ Failed to detect Cloudflare URL."
  echo "Check cloudflared.log for details."
fi

echo ""
echo "Options:"
echo "  r  → restart tunnel"
echo "  q  → quit"
echo "========================================"

# -----------------------------
# Interactive controls
# -----------------------------
while true; do
  read -n1 -s key
  case "$key" in
    r|R)
      echo ""
      echo "[*] Restarting tunnel..."

      if [ -f "$PID_FILE" ]; then
        kill "$(cat $PID_FILE)" 2>/dev/null || true
      fi

      rm -f "$LOG_FILE" "$URL_FILE"

      (
        ./cloudflared tunnel --url "http://127.0.0.1:$PORT" \
          > "$LOG_FILE" 2>&1
      ) &
      echo $! > "$PID_FILE"

      sleep 3

      URL=$(grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare.com" "$LOG_FILE" | head -n 1)

      clear
      echo "========================================"
      echo "   Shadow Clouds 24/7 Running"
      echo "========================================"
      echo ""
      echo "Your Cloudflare URL:"
      echo ""
      echo "$URL"
      echo ""
      echo "Press r to restart, q to quit"
      ;;
    q|Q)
      echo ""
      echo "Stopping..."
      if [ -f "$PID_FILE" ]; then
        kill "$(cat $PID_FILE)" 2>/dev/null || true
      fi
      exit 0
      ;;
  esac
done
