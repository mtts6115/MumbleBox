#!/usr/bin/env bash
# ==============================================================================
#  __  __                 _     _      ____            
# |  \/  |_   _ _ __ ___ | |__ | | ___| __ )  _____  __
# | |\/| | | | | '_ ` _ \| '_ \| |/ _ \  _ \ / _ \ \/ /
# | |  | | |_| | | | | | | |_) | |  __/ |_) | (_) >  < 
# |_|  |_|\__,_|_| |_| |_|_.__/|_|\___|____/ \___/_/\_\
#
# Turnkey Mumble Server Installer for Android TV Box (Termux) & ARM Linux
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "============================================================"
    echo "  __  __                 _     _      ____            "
    echo " |  \/  |_   _ _ __ ___ | |__ | | ___| __ )  _____  __"
    echo " | |\/| | | | | '_ \` _ \| '_ \| |/ _ \  _ \ / _ \ \/ /"
    echo " | |  | | |_| | | | | | | |_) | |  __/ |_) | (_) >  < "
    echo " |_|  |_|\__,_|_| |_| |_|_.__/|_|\___|____/ \___/_/\_\\"
    echo ""
    echo " Turnkey Mumble Server for Android TV Box & ARM Devices"
    echo "============================================================"
    echo -e "${NC}"
}

banner

# ------------------------------------------------------------------------------
# 1. Environment Detection
# ------------------------------------------------------------------------------
echo -e "${BLUE}[1/5] Detecting environment...${NC}"

if [ -n "$PREFIX" ] && [ -d "$PREFIX" ] && [[ "$PREFIX" == *"com.termux"* ]]; then
    ENV_MODE="termux"
    echo -e "${GREEN}[✔] Detected Termux on Android OS!${NC}"
    DATA_DIR="$HOME/.mumblebox"
    BIN_DIR="$PREFIX/bin"
    BOOT_DIR="$HOME/.termux/boot"
else
    ENV_MODE="linux"
    echo -e "${GREEN}[✔] Detected Standard Linux / Armbian!${NC}"
    DATA_DIR="/var/lib/mumblebox"
    BIN_DIR="/usr/local/bin"
    
    # Check root for linux
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}[!] Notice: Running on Linux requires root privileges.${NC}"
        echo -e "${YELLOW}[!] Re-running script with sudo...${NC}"
        exec sudo bash "$0" "$@"
    fi
fi

# ------------------------------------------------------------------------------
# 2. Interactive Setup Wizard
# ------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}[2/5] Server Configuration Wizard${NC}"

# Server Name
read -rp "Enter Server Name [Default: MumbleBox]: " INPUT_SERVER_NAME
SERVER_NAME="${INPUT_SERVER_NAME:-MumbleBox}"

# Port
read -rp "Enter Port (TCP & UDP) [Default: 64738]: " INPUT_PORT
PORT="${INPUT_PORT:-64738}"

# Max Users
read -rp "Enter Max Concurrent Users [Default: 50]: " INPUT_USERS
MAX_USERS="${INPUT_USERS:-50}"

# SuperUser Password
DEFAULT_PASS=$(tr -dc A-Za-z0-9 2>/dev/null | head -c 12 || date +%s | sha256sum | head -c 12)
read -rp "Enter SuperUser (Admin) Password [Press ENTER for random: $DEFAULT_PASS]: " INPUT_PASS
SUPERUSER_PASS="${INPUT_PASS:-$DEFAULT_PASS}"

echo ""
echo -e "${GREEN}Configuration Summary:${NC}"
echo -e "  - Server Name : ${BOLD}$SERVER_NAME${NC}"
echo -e "  - Port        : ${BOLD}$PORT${NC}"
echo -e "  - Max Users   : ${BOLD}$MAX_USERS${NC}"
echo -e "  - SuperUser PW: ${BOLD}$SUPERUSER_PASS${NC}"
echo ""

# ------------------------------------------------------------------------------
# 3. Installing Dependencies & Core Packages
# ------------------------------------------------------------------------------
echo -e "${BLUE}[3/5] Installing dependencies...${NC}"

if [ "$ENV_MODE" = "termux" ]; then
    echo -e "${CYAN}[*] Updating Termux packages...${NC}"
    pkg update -y -o Dpkg::Options::="--force-confold"
    pkg install -y proot-distro curl jq tar iproute2 procps termux-tools

    # Acquire wake lock so Android won't freeze background tasks
    if command -v termux-wake-lock >/dev/null 2>&1; then
        echo -e "${CYAN}[*] Enabling Android Wake Lock (Prevent Sleep)...${NC}"
        termux-wake-lock
    fi

    # Install Debian inside proot if not present
    if ! proot-distro list | grep -q "debian (installed)"; then
        echo -e "${CYAN}[*] Setting up Debian container inside PRoot (One-time setup)...${NC}"
        proot-distro install debian
    fi

    # Install mumble-server inside proot
    echo -e "${CYAN}[*] Installing mumble-server inside Debian...${NC}"
    proot-distro login debian -- bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y mumble-server"

else
    # Linux / Armbian
    echo -e "${CYAN}[*] Updating apt repositories...${NC}"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y mumble-server curl jq iproute2 procps
fi

# ------------------------------------------------------------------------------
# 4. Configuring Mumble Server
# ------------------------------------------------------------------------------
echo -e "${BLUE}[4/5] Deploying configuration...${NC}"

# Find script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$ENV_MODE" = "termux" ]; then
    mkdir -p "$DATA_DIR"
    CONF_FILE="$DATA_DIR/mumble-server.ini"
    DB_FILE="$DATA_DIR/mumble-server.sqlite"
    LOG_FILE="$DATA_DIR/mumble-server.log"

    # Write configuration
    cat <<EOF > "$CONF_FILE"
database=$DB_FILE
logfile=$LOG_FILE
port=$PORT
host=
serverpassword=
users=$MAX_USERS
bandwidth=72000
welcometext="<br />Welcome to <b>$SERVER_NAME</b>!<br />Powered by MumbleBox on Android Box.<br />"
opusthreshold=100
channelname=[$SERVER_NAME] Lobby
channelnestinglimit=5
defaultchannel=1
bonjour=True
sendversion=True
allowhtml=true
suggestversion=true
timeout=30
EOF

    # Set SuperUser password
    echo -e "${CYAN}[*] Setting SuperUser password...${NC}"
    proot-distro login debian -- murmurd -ini "$CONF_FILE" -supw "$SUPERUSER_PASS" >/dev/null 2>&1

    # Install CLI Controller
    cp "$SCRIPT_DIR/bin/mumblebox" "$BIN_DIR/mumblebox"
    chmod +x "$BIN_DIR/mumblebox"

    # Configure Auto-Start on Boot (Termux:Boot)
    mkdir -p "$BOOT_DIR"
    cat << 'BOOTEOF' > "$BOOT_DIR/start-mumblebox.sh"
#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
sleep 10
$PREFIX/bin/mumblebox start
BOOTEOF
    chmod +x "$BOOT_DIR/start-mumblebox.sh"

else
    # Linux / Armbian
    CONF_FILE="/etc/mumble-server.ini"
    
    # Backup original config if exists
    if [ -f "$CONF_FILE" ] && [ ! -f "$CONF_FILE.orig" ]; then
        cp "$CONF_FILE" "$CONF_FILE.orig"
    fi

    cat <<EOF > "$CONF_FILE"
database=/var/lib/mumble-server/mumble-server.sqlite
logfile=/var/log/mumble-server/mumble-server.log
pidfile=/var/run/mumble-server/mumble-server.pid
welcometext="<br />Welcome to <b>$SERVER_NAME</b>!<br />Powered by MumbleBox.<br />"
port=$PORT
serverpassword=
bandwidth=72000
users=$MAX_USERS
opusthreshold=100
channelnestinglimit=5
defaultchannel=1
bonjour=True
sendversion=True
allowhtml=true
suggestversion=true
timeout=30
EOF

    # Set permissions
    chown -R mumble-server:mumble-server /var/lib/mumble-server /var/log/mumble-server 2>/dev/null || true

    # Set SuperUser password
    echo -e "${CYAN}[*] Setting SuperUser password...${NC}"
    murmurd -ini "$CONF_FILE" -supw "$SUPERUSER_PASS" >/dev/null 2>&1

    # Install CLI Controller
    cp "$SCRIPT_DIR/bin/mumblebox" "$BIN_DIR/mumblebox"
    chmod +x "$BIN_DIR/mumblebox"

    # Enable and start systemd service
    systemctl enable mumble-server >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------------------
# 5. Starting the Server & Printing Connection Card
# ------------------------------------------------------------------------------
echo -e "${BLUE}[5/5] Starting MumbleBox service...${NC}"

"$BIN_DIR/mumblebox" start

# Network detection
LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | awk -F"src " 'NR==1{split($2,a," ");print a[1]}' || echo "127.0.0.1")
PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || echo "Unable to detect")

echo ""
echo -e "${GREEN}${BOLD}============================================================${NC}"
echo -e "${GREEN}${BOLD}       🎉 MUMBLEBOX INSTALLATION COMPLETED SUCCESSFULLY!    ${NC}"
echo -e "${GREEN}${BOLD}============================================================${NC}"
echo ""
echo -e "${BOLD}Server Name:${NC}       $SERVER_NAME"
echo -e "${BOLD}Port:${NC}              $PORT (TCP & UDP)"
echo -e "${BOLD}SuperUser Login:${NC}   Username: ${CYAN}SuperUser${NC} | Password: ${CYAN}$SUPERUSER_PASS${NC}"
echo ""
echo -e "${BOLD}📡 Connection Details:${NC}"
echo -e "  • Local Network (LAN):  ${CYAN}${BOLD}$LOCAL_IP:$PORT${NC}"
echo -e "  • Join Link (LAN):      ${GREEN}mumble://$LOCAL_IP:$PORT${NC}"
if [ "$PUBLIC_IP" != "Unable to detect" ]; then
    echo -e "  • Public IP (Internet): ${YELLOW}${BOLD}$PUBLIC_IP:$PORT${NC}"
    echo -e "  • Join Link (Internet): ${YELLOW}mumble://$PUBLIC_IP:$PORT${NC}"
fi
echo ""
echo -e "${BOLD}🛠️ Management Commands:${NC}"
echo -e "  - Check status:         ${CYAN}mumblebox status${NC}"
echo -e "  - View connection info: ${CYAN}mumblebox info${NC}"
echo -e "  - View live logs:       ${CYAN}mumblebox logs${NC}"
echo -e "  - Change admin pass:    ${CYAN}mumblebox passwd${NC}"
echo -e "  - Stop / Start server:  ${CYAN}mumblebox stop${NC} / ${CYAN}mumblebox start${NC}"
echo ""
echo -e "${YELLOW}${BOLD}⚠️ IMPORTANT FOR ANDROID TV BOX USERS:${NC}"
echo -e "  1. Keep Termux open in background or use ${BOLD}Termux:Boot${NC} for auto-start."
echo -e "  2. Go to Android Settings -> Apps -> Termux -> Battery -> Set to ${BOLD}'Unrestricted'${NC}."
echo -e "  3. If friends outside home want to connect, forward Port ${BOLD}$PORT (TCP & UDP)${NC} on your Wi-Fi Router."
echo -e "${GREEN}============================================================${NC}"

