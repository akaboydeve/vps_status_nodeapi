#!/bin/bash
set -e

echo "=== Node Agent Installer ==="

# Prompt for API endpoint with default
read -p "Enter API endpoint (press enter to use default: https://monitor.hexonode.com/api/nodes): " endpoint
if [ -z "$endpoint" ]; then
  endpoint="https://monitor.hexonode.com/api/nodes"
fi

# Prompt for Node Name
read -p "Enter Node Name: " nodename

# Prompt for Node IP with default (public IP)
default_ip=$(curl -4 -s ifconfig.me)
read -p "Enter Node IP (press enter to use detected: $default_ip): " nodeip
if [ -z "$nodeip" ]; then
  nodeip="$default_ip"
fi

# Remove previous installation if exists
if [ -d "/etc/node-agent" ]; then
  echo "[*] Removing previous node-agent installation..."
  sudo systemctl stop node-agent || true
  sudo systemctl disable node-agent || true
  sudo rm -rf /etc/node-agent
  sudo rm -f /etc/systemd/system/node-agent.service
  sudo systemctl daemon-reload
fi

echo "[*] Checking for python3..."
if ! command -v python3 >/dev/null; then
  echo "[*] Installing python3..."
  sudo apt-get update -y
  sudo apt-get install -y python3
fi

echo "[*] Checking for pip3..."
if ! command -v pip3 >/dev/null; then
  echo "[*] Installing python3-pip..."
  sudo apt-get install -y python3-pip
fi

# Ensure python3-venv is installed
if ! dpkg -s python3-venv >/dev/null 2>&1; then
  echo "[*] Installing python3-venv..."
  sudo apt-get update -y
  sudo apt-get install -y python3-venv
fi

# Create install directory
sudo mkdir -p /etc/node-agent

# Set up Python virtual environment
if [ ! -d "/etc/node-agent/venv" ]; then
  echo "[*] Creating Python virtual environment..."
  sudo python3 -m venv /etc/node-agent/venv
fi

# Install required Python packages in venv
echo "[*] Installing required Python packages in virtual environment..."
sudo /etc/node-agent/venv/bin/pip install --quiet psutil requests
echo "[*] Required Python packages installed in virtual environment."

# Write config.json
sudo tee /etc/node-agent/config.json > /dev/null <<EOL
{
  "endpoint": "$endpoint",
  "nodename": "$nodename",
  "nodeip": "$nodeip"
}
EOL

# (Optional) Copy example config if not present
if [ ! -f /etc/node-agent/config.json ]; then
    sudo cp config.json.example /etc/node-agent/config.json
    echo "Copied example config to /etc/node-agent/config.json"
fi

# Download agent code from GitHub
echo "[*] Downloading agent code..."
sudo curl -sSL https://raw.githubusercontent.com/akaboydeve/vps_status_nodeapi/main/main.py -o /etc/node-agent/agent.py
sudo chmod +x /etc/node-agent/agent.py

# Create systemd service
sudo tee /etc/systemd/system/node-agent.service > /dev/null <<EOL
[Unit]
Description=Lightweight Node Monitoring Agent
After=network.target

[Service]
ExecStart=/etc/node-agent/venv/bin/python /etc/node-agent/agent.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOL

# Enable + start service
sudo systemctl daemon-reexec
sudo systemctl enable node-agent
sudo systemctl restart node-agent

# Add passwordless sudo for reboot for the current user
USERNAME=$(whoami)
SUDOERS_LINE="$USERNAME ALL=(ALL) NOPASSWD: /usr/sbin/reboot"
SUDOERS_FILE="/etc/sudoers.d/node-agent-reboot"

if ! sudo grep -q "$SUDOERS_LINE" "$SUDOERS_FILE" 2>/dev/null; then
    echo "$SUDOERS_LINE" | sudo tee "$SUDOERS_FILE" > /dev/null
    sudo chmod 440 "$SUDOERS_FILE"
    echo "Added passwordless sudo for reboot to $SUDOERS_FILE"
else
    echo "Passwordless sudo for reboot already set."
fi

echo "=== Installation Complete ==="
echo "Service running: systemctl status node-agent"
