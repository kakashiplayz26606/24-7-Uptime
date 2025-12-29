#!/usr/bin/env bash
set -e

clear

echo "========================================"
echo "   Shadow Clouds 24/7 Uptime Installer  "
echo "========================================"
echo ""

OS="$(uname -s)"

echo "Detected OS: $OS"
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
# WINDOWS / MINGW / GIT BASH
# ----------------------------
if [[ "$OS" == *"MINGW"* || "$OS" == *"MSYS"* || "$OS" == *"CYGWIN"* ]]; then
    echo "[!] Windows environment detected"

    if ! command -v python >/dev/null 2>&1; then
        echo ""
        echo "❌ Python is not installed."
        echo "👉 Download Python from:"
        echo "https://www.python.org/downloads/windows/"
        echo ""
        echo "IMPORTANT:"
        echo "✔ Enable 'Add Python to PATH' during install"
        exit 1
    fi

    PYTHON="python"
    PIP="pip"

else
    # Linux / VPS
    if ! command -v python3 >/dev/null 2>&1; then
        echo "[+] Installing Python..."
        sudo apt update -y
        sudo apt install -y python3 python3-pip
    fi

    PYTHON="python3"
    PIP="pip3"
fi

# ----------------------------
# Install Python packages
# ----------------------------
echo "[+] Installing Python packages..."
$PIP install --upgrade pip
$PIP install fastapi uvicorn

# ----------------------------
# Install cloudflared
# ----------------------------
if ! command -v cloudflared >/dev/null 2>&1; then
    echo "[+] Installing Cloudflare Tunnel..."

    if [[ "$OS" == *"MINGW"* || "$OS" == *"MSYS"* || "$OS" == *"CYGWIN"* ]]; then
        echo "Download Cloudflared manually for Windows:"
        echo "https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
        echo ""
        echo "After install, re-run this script."
        exit 1
    else
        curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
        chmod +x cloudflared
        sudo mv cloudflared /usr/local/bin/cloudflared
    fi
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
nohup $PYTHON connector.py > connector.log 2>&1 &

sleep 2

# ----------------------------
# Start Cloudflare tunnel
# ----------------------------
echo ""
echo "========================================"
echo " 🌍 YOUR PUBLIC 24/7 URL WILL APPEAR BELOW"
echo "========================================"
echo ""

cloudflared tunnel --url http://localhost:8080
