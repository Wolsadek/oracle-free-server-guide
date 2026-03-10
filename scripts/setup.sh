#!/bin/bash

# Oracle Free Server Setup Script
# Automates the initial setup of monitoring scripts

set -e

echo "======================================"
echo "Oracle Free Server - Setup Script"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Please do not run this script as root${NC}"
    exit 1
fi

echo -e "${GREEN}1. Installing dependencies...${NC}"
sudo apt update
sudo apt install -y python3-pip python3-venv python3-dev python3-full stress-ng pipx curl jq

echo ""
echo -e "${GREEN}2. Setting up Oracle CLI...${NC}"

# Check if venv already exists
if [ -d "/opt/oracle-cli-venv" ]; then
    echo -e "${YELLOW}Oracle CLI venv already exists, skipping...${NC}"
else
    sudo mkdir -p /opt
    sudo python3 -m venv /opt/oracle-cli-venv
    sudo chown -R $USER:$USER /opt/oracle-cli-venv
fi

# Install OCI CLI
if command -v oci &> /dev/null; then
    echo -e "${YELLOW}OCI CLI already installed${NC}"
else
    pipx install oci-cli
    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
fi

echo ""
echo -e "${GREEN}3. Creating directories...${NC}"
sudo mkdir -p /opt/oci_scripts/monitoring
sudo mkdir -p /var/log/oci
sudo chown -R $USER:$USER /opt/oci_scripts
sudo chown -R $USER:$USER /var/log/oci

mkdir -p ~/scripts

echo ""
echo -e "${GREEN}4. Installing monitoring scripts...${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Copy monitoring scripts
sudo cp "$SCRIPT_DIR/cpu_monitor.sh" /opt/oci_scripts/monitoring/
sudo cp "$SCRIPT_DIR/storage_monitor.sh" /opt/oci_scripts/monitoring/
sudo cp "$SCRIPT_DIR/bandwidth_monitor.sh" /opt/oci_scripts/monitoring/
sudo chmod +x /opt/oci_scripts/monitoring/*.sh

echo ""
echo -e "${GREEN}5. Installing CPU Keep-Alive service...${NC}"
sudo cp "$SCRIPT_DIR/systemd/cpu-keepalive.service" /etc/systemd/system/
sudo systemctl daemon-reload

echo ""
echo -e "${YELLOW}======================================"
echo "Setup Complete!"
echo "======================================${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Configure Oracle CLI:"
echo "   ${GREEN}oci iam region list${NC}"
echo ""
echo "2. Edit monitoring scripts with your credentials:"
echo "   - WEBHOOK_URL (Slack webhook)"
echo "   - COMPARTMENT_ID (Your tenancy OCID)"
echo "   ${GREEN}nano /opt/oci_scripts/monitoring/cpu_monitor.sh${NC}"
echo "   ${GREEN}nano /opt/oci_scripts/monitoring/storage_monitor.sh${NC}"
echo "   ${GREEN}nano /opt/oci_scripts/monitoring/bandwidth_monitor.sh${NC}"
echo ""
echo "3. Enable CPU Keep-Alive service:"
echo "   ${GREEN}sudo systemctl enable cpu-keepalive${NC}"
echo "   ${GREEN}sudo systemctl start cpu-keepalive${NC}"
echo ""
echo "4. Add monitoring scripts to crontab:"
echo "   ${GREEN}crontab -e${NC}"
echo "   Add these lines:"
echo "   ${GREEN}0 */6 * * * /opt/oci_scripts/monitoring/cpu_monitor.sh >> /var/log/oci/cpu_monitor_cron.log 2>&1${NC}"
echo "   ${GREEN}0 9 * * * /opt/oci_scripts/monitoring/storage_monitor.sh >> /var/log/oci/storage_monitor_cron.log 2>&1${NC}"
echo "   ${GREEN}0 */12 * * * /opt/oci_scripts/monitoring/bandwidth_monitor.sh >> /var/log/oci/bandwidth_monitor_cron.log 2>&1${NC}"
echo ""
echo "5. (Optional) Setup n8n backups with rclone - see README.md"
echo ""
echo -e "${GREEN}For full documentation, see: README.md${NC}"
