#!/usr/bin/env bash
set -e

clear

APP_NAME="Shadow Clouds 24/7"
PID_FILE=".tunnel.pid"
URL_FILE=".tunnel_url"

print_banner() {
  clear
  echo "========================================"
  echo "   $APP_NAME"
  echo "========================================"
  echo ""
}

find_python() {
  if command -v python3 >/dev/null 2>&1; then
    echo "python3"
  elif command -v python >/dev/null 2>&1; then
    echo "python"
  else
    echo ""
  fi
}

get_free_port() {
  $PYTHON - <<'PY'
import socket
s=socket.socket()
s.bind(("",0))
print(s.getsockname()[1])
s.close()
PY
}

start_backend() {
  PORT=$(get_free_port)
  echo "[✓] Backend port: $PORT"

  nohup $PYTHON connector.py --port "$PORT" > connector.log 2>&1 &
  BACKEND_PID=$!

  for i in {1..30}; do
    if curl -s "http://127.0.0.1:$PORT" >/dev/null 2>&1; then
      echo "[✓] Backend running"
      break
    fi
    sleep 0.5
  done
}

start_tunnel() {
  echo "[+] Starting Cloudflare tunnel..."

  (
    while true; do
      ./cloudflared tunnel --url "http://127.0.0.1:$PORT" 2>&1 | tee tunnel.log | \
      grep -oE "https://[a-zA-Z0-9.-]+\.trycloudflare.com" > "$URL_FILE"
      sleep 2
    done
  ) &
  
  echo $! > "$PID_FILE"
}

show_url() {
  sleep 3
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
    echo "Waiting for Cloudflare URL..."
  fi
  echo ""
  echo "Options:"
  echo "  r  → restart tunnel"
  echo "  q  → quit"
  echo "========================================"
}

restart_tunnel() {
  if [ -f "$PID_FILE" ]; then
    kill "$(cat $PID_FILE)" 2>/dev/null || true
    rm -f "$PID_FILE"
  fi
  start_tunnel
}

# -------------------- START --------------------

print_banner

echo "Choose platform:"
echo "1) GitHub"
echo "2) Google IDX"
echo "3) CodeSandbox"
echo ""
read -p "Enter option (1/2/3): " OPTION

echo ""
echo "▶ Setting up environment..."

PYTHON=$(find_python)
if [ -z "$PYTHON" ]; then
  echo "❌ Python not found"
  exit 1
fi

# Create venv safely (optional)
if $PYTHON -m venv .venv >/dev/null 2>&1; then
  if [ -f ".venv/bin/python" ]; then
    PYTHON=".venv/bin/python"
  fi
fi

# Install deps
$PYTHON -m pip install --upgrade pip >/dev/null 2>&1 || true
$PYTHON -m pip install fastapi uvicorn >/dev/null 2>&1 || true

# Download connector
curl -fsSL https://raw.githubusercontent.com/kakashiplayz26606/24-7-Uptime/main/connector.py -o connector.py

# Download cloudflared
if [ ! -f "./cloudflared" ]; then
  curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
fi

# Start backend + tunnel
start_backend
start_tunnel
show_url

# Interactive loop
while true; do
  read -n1 -s key
  case "$key" in
    r|R)
      echo ""
      echo "[*] Restarting tunnel..."
      restart_tunnel
      show_url
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
