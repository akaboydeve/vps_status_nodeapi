#!/usr/bin/env python3
import psutil
import requests
import time
import json
import sys
import os

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

def collect_stats():
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
        "network in": psutil.net_io_counters().bytes_recv // 1024,  # KB
        "network out": psutil.net_io_counters().bytes_sent // 1024  # KB
    }

def main():
    while True:
        try:
            payload = collect_stats()
            requests.post(API_ENDPOINT, json=payload, timeout=5)
        except Exception as e:
            print("Error posting data:", e)
        time.sleep(20)

if __name__ == "__main__":
    main()
