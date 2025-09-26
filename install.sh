#!/bin/bash
set -e


echo "=== Node Agent Installer ==="
read -p "Enter API endpoint (e.g. https://monitor.hexonode.com/api/nodes ): " endpoint
read -p "Enter Node Name: " nodename
read -p "Enter Node IP: " nodeip

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

# Check for required Python packages
missing_pkgs=""
python3 -m pip show psutil >/dev/null 2>&1 || missing_pkgs="psutil $missing_pkgs"
python3 -m pip show requests >/dev/null 2>&1 || missing_pkgs="requests $missing_pkgs"
if [ ! -z "$missing_pkgs" ]; then
  echo "[*] Installing required Python packages: $missing_pkgs"
  sudo pip3 install $missing_pkgs --quiet
else
  echo "[*] Required Python packages already installed."
fi

# Create install directory
sudo mkdir -p /etc/node-agent
sudo tee /etc/node-agent/config.json > /dev/null <<EOL
{
  "endpoint": "$endpoint",
  "nodename": "$nodename",
  "nodeip": "$nodeip"
}
EOL


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
ExecStart=/usr/bin/python3 /etc/node-agent/agent.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOL

# Enable + start service
sudo systemctl daemon-reexec
sudo systemctl enable node-agent
sudo systemctl restart node-agent

echo "=== Installation Complete ==="
echo "Service running: systemctl status node-agent"
