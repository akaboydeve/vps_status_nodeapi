#!/usr/bin/env python3
import psutil
import requests
import time
import json
import sys
import os
import subprocess

# Load config
CONFIG_FILE = "/etc/node-agent/config.json"

if not os.path.exists(CONFIG_FILE):
    print("Config file not found:", CONFIG_FILE)
    sys.exit(1)

with open(CONFIG_FILE, "r") as f:
    config = json.load(f)

API_ENDPOINT = config["endpoint"]
NODENAME = config["nodename"]
NODEIP = config["nodeip"]


# Track previous network counters for KBps calculation
prev_recv = None
prev_sent = None
INTERVAL = 20

def collect_stats():
    global prev_recv, prev_sent
    net = psutil.net_io_counters()
    curr_recv = net.bytes_recv
    curr_sent = net.bytes_sent
    if prev_recv is None or prev_sent is None:
        # First run, can't calculate KBps
        kbps_in = 0
        kbps_out = 0
    else:
        kbps_in = ((curr_recv - prev_recv) / 1024) / INTERVAL
        kbps_out = ((curr_sent - prev_sent) / 1024) / INTERVAL
    prev_recv = curr_recv
    prev_sent = curr_sent
    return {
        "nodename": NODENAME,
        "cpuCores": psutil.cpu_count(logical=True),
        "cpuUsage": psutil.cpu_percent(interval=1),
        "Ram": round(psutil.virtual_memory().total / (1024**3)),  # GB
        "RamUsage": psutil.virtual_memory().percent,
        "Disk": round(psutil.disk_usage('/').total / (1024**3)),  # GB
        "DIskUsed": psutil.disk_usage('/').percent,
        "OS": os.popen("lsb_release -d").read().strip().replace("Description:\t", ""),
        "IP": NODEIP,
        "network in": round(kbps_in, 2),  # KBps
        "network out": round(kbps_out, 2)  # KBps
    }


def reboot_system():
    print("Reboot requested by API. Rebooting now...")
    try:
        subprocess.run(["sudo", "reboot"], check=True)
    except Exception as e:
        print("Failed to reboot:", e)

def main():
    global prev_recv, prev_sent
    while True:
        try:
            payload = collect_stats()
            response = requests.post(API_ENDPOINT, json=payload, timeout=5)
            # Check for reboot instruction in API response
            if response.ok:
                try:
                    data = response.json()
                    if data.get("reboot") is True:
                        reboot_system()
                except Exception as e:
                    print("Error parsing API response:", e)
        except Exception as e:
            print("Error posting data:", e)
        time.sleep(INTERVAL)

if __name__ == "__main__":
    main()
