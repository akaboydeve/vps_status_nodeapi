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


# Set up Python virtual environment
if [ ! -d "/etc/node-agent/venv" ]; then
  echo "[*] Creating Python virtual environment..."
  sudo python3 -m venv /etc/node-agent/venv
fi

# Install required Python packages in venv
echo "[*] Installing required Python packages in virtual environment..."
sudo /etc/node-agent/venv/bin/pip install --quiet psutil requests

echo "[*] Required Python packages installed in virtual environment."

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

echo "=== Installation Complete ==="
echo "Service running: systemctl status node-agent"
