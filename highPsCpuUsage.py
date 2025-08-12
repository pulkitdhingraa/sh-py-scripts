# Create a Python script that monitors CPU usage of running processes and sends an alert (via a fake HTTP POST API call) if any process uses more than 30% CPU.
# The script should:
# Use ps, awk, grep, and xargs to extract process info.
# Parse and filter with re.
# Log timestamps using datetime.
# Send alerts using requests.post().
# Save CPU usage logs to a JSON file using json.
# Use os for file handling and system path checks.
# Bonus: Wrap the script in a Docker container that runs this script on startup.

import subprocess
import re
from datetime import datetime
import os
import json
import requests

CPU_THRESHOLD = 30.0
ALERT_API = "https://httpbin.com/post"
LOG_FILE = "high_cpu_usage.json"

def get_high_cpu_processes():
    cmd = "ps aux --sort=-%cpu | awk 'NR>1 {print $1, $2, $3, $11}' | grep -v '^root' | head -n 10"
    output = subprocess.run(cmd, shell=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    result = output.stdout.strip().splitlines()
    return result

def parse_cpu_info(process_info):
    """
    PARSE
    pd 376 5.2 nginx   
    """
    match = re.match(r"(\S+)\s+(\d+)\s+(\d+\.\d+)\s+(.+)", process_info)
    if match:
        user, pid, cpu, cmd = match.groups()
        return {
            "user": user,
            "pid": pid,
            "cpu": cpu,
            "command": cmd
        }
    return None

def log_ps_to_file(process_info):
    log_entry = {
        "timestamp": datetime.now().isoformat(),
        "process": process_info
    }

    # load old logs
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, 'r') as f:
            try:
                logs = json.load(f)
            except json.JSONDecodeError:
                logs = []
    else:
        logs = []
    
    logs.append(log_entry)

    with open(LOG_FILE, 'w') as f:
        json.dump(logs, f, indent=2)

def send_alert(process_info):
    payload = {
        "alert": f"High CPU usage detected!",
        "process": process_info,
        "timestamp": datetime.now().isoformat()
    }

    try:
        response = requests.post(ALERT_API, json=payload)
        print(f"[ALERT SENT] {process_info['command']} (CPU: {process_info['cpu']}%)")
        print(f"Response: {response.status_code}")
    except requests.RequestException as e:
        print(f"Failed to send alert: {e}")

if __name__ == "__main__":
    processes = get_high_cpu_processes()
    for ps in processes:
        cpu_ps = parse_cpu_info(ps)
        if cpu_ps and float(cpu_ps['cpu']) > CPU_THRESHOLD:
            log_ps_to_file(cpu_ps)
            send_alert(cpu_ps)
        else:
            print(f'[INFO] Skipping process')
