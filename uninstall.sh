#!/usr/bin/env bash
# ==============================================================================
# MumbleBox Uninstaller
# Safe and clean removal utility for MumbleBox
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${RED}${BOLD}"
echo "============================================================"
echo "               MumbleBox Uninstaller                        "
echo "============================================================"
echo -e "${NC}"

# Detect Environment
if [ -n "$PREFIX" ] && [ -d "$PREFIX" ] && [[ "$PREFIX" == *"com.termux"* ]]; then
    ENV_MODE="termux"
    DATA_DIR="$HOME/.mumblebox"
    BIN_FILE="$PREFIX/bin/mumblebox"
    BOOT_FILE="$HOME/.termux/boot/start-mumblebox.sh"
else
    ENV_MODE="linux"
    DATA_DIR="/var/lib/mumblebox"
    BIN_FILE="/usr/local/bin/mumblebox"
    
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}[!] Re-running uninstaller with sudo...${NC}"
        exec sudo bash "$0" "$@"
    fi
fi

read -rp "Are you sure you want to uninstall MumbleBox? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}[*] Uninstallation cancelled.${NC}"
    exit 0
fi

# 1. Stop Server
echo -e "${BLUE}[1/3] Stopping Mumble server...${NC}"
if [ -x "$BIN_FILE" ]; then
    "$BIN_FILE" stop >/dev/null 2>&1 || true
fi
pkill -f "murmurd" 2>/dev/null || true

# 2. Remove binary and boot scripts
echo -e "${BLUE}[2/3] Removing binaries and autostart scripts...${NC}"
rm -f "$BIN_FILE"

if [ "$ENV_MODE" = "termux" ]; then
    rm -f "$BOOT_FILE"
else
    if command -v systemctl >/dev/null 2>&1; then
        systemctl disable mumble-server >/dev/null 2>&1 || true
    fi
fi

# 3. Clean or preserve data
echo -e "${BLUE}[3/3] Handling database & configuration...${NC}"
read -rp "Do you want to permanently delete all server data & databases? [y/N]: " PURGE_DATA
if [[ "$PURGE_DATA" =~ ^[Yy]$ ]]; then
    rm -rf "$DATA_DIR"
    echo -e "${YELLOW}[✔] Removed $DATA_DIR${NC}"
else
    echo -e "${GREEN}[✔] Preserved data files in $DATA_DIR${NC}"
fi

echo ""
echo -e "${GREEN}${BOLD}[✔] MumbleBox has been successfully uninstalled.${NC}"

