#!/bin/bash
set -e

echo "=== Node Agent Installer ==="
read -p "Enter API endpoint (e.g. http://localhost:3000/api/nodes): " endpoint
read -p "Enter Node Name: " nodename
read -p "Enter Node IP: " nodeip

# Install python + pip + psutil if not present
if ! command -v python3 >/dev/null; then
    echo "[*] Installing python3..."
    sudo apt-get update -y
    sudo apt-get install -y python3 python3-pip
fi

sudo pip3 install psutil requests --quiet

# Create install directory
sudo mkdir -p /etc/node-agent
sudo tee /etc/node-agent/config.json > /dev/null <<EOL
{
  "endpoint": "$endpoint",
  "nodename": "$nodename",
  "nodeip": "$nodeip"
}
EOL

# Copy agent
sudo tee /etc/node-agent/agent.py > /dev/null <<'EOPY'
<PUT PYTHON CODE FROM ABOVE HERE>
EOPY

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
