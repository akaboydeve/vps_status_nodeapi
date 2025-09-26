# VPS Status NodeAPI Agent

This project provides a lightweight agent for monitoring VPS status and reporting to a central API endpoint.

## Features
- Collects CPU, RAM, disk, network, and OS info
- Sends data to a configurable API endpoint
- Runs as a systemd service for reliability

## Installation

Run the following command on your VPS:

```
bash <(curl -s https://raw.githubusercontent.com/akaboydeve/vps_status_nodeapi/main/install.sh)
```

You will be prompted for:
- API endpoint (e.g. `http://localhost:3000/api/nodes`)
- Node name
- Node IP

The agent will be installed to `/etc/node-agent/` and started as a service.

## Service Management

Check status:
```
systemctl status node-agent
```
Restart service:
```
sudo systemctl restart node-agent
```

## Uninstall
To remove the agent:
```
sudo systemctl stop node-agent
sudo systemctl disable node-agent
sudo rm /etc/systemd/system/node-agent.service
sudo rm -rf /etc/node-agent
sudo systemctl daemon-reload
```

## License
MIT
