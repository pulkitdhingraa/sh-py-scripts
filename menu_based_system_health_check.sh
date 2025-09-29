# Objective

# Your task today is to develop a menu-driven script that performs essential system health checks. This tool should allow users to select from the following options:

# Check Disk Usage
# Monitor Running Services
# Assess Memory Usage
# Evaluate CPU Usage
# Send a Comprehensive Report via Email Every Four Hours

# Implementation

# case statement to allow user input to select from options 1,2,3,4,5
# each case as a separate function
# error handling in each case
# use debugging features wherever possible


#!/bin/bash

# set -x # debug mode, print command as they execute

disk_usage() {
    df -h | sort -k5 -rh
    # df -h | awk '$NF=="/"{printf "%s\t\t", $5}'
}

running_services() {
    systemctl list-units --type=service --state=running
}

mem_usage() {
    free -h
    # free -m | awk 'NR==2{printf "%.2f%\t\t", $3*100/$2}'
}

cpu_usage() {
    mpstat 1 1 | awk '/Average/ {printf "%.2f%\t\t", 100-$12}'
    # top -bn1 | grep "Cpu(s)" | awk '{print 100-$8"%"}'
}

collect_system_info() {
    echo "====== CPU USAGE ======"
    cpu_usage
    echo 
    echo "====== MEMORY USAGE ======"
    mem_usage
    echo
    echo "====== DISK USAGE ======"
    disk_usage
    echo
    echo "====== RUNNING SERVICES ======"
    running_services
}

send_report() {
    recipient="you@example.com"
    collect_system_info | mail -s "System Report - $(hostname)" "$recipient"
}

email_reporting() {
    local CRON_JOB="0 */4 * * * $(pwd)/$(basename $0) send_report"
    if crontab -l 2>/dev/null | grep -Fq "$CRON_JOB"; then
        echo "Mailing is currently ENABLED."
        read -p "Do you want to disable it? (y/n): " ans
        if [[ $ans =~ ^[Yy]$ ]]; then
            mailing_enabled=false
            echo "Mailing has been disabled"
            (crontab -l 2>/dev/null | grep -vF "$CRON_JOB") | crontab -
        else
            echo "Mailing remains enabled"
        fi
    else
        echo "Mailing is currently DISABLED."
        read -p "Do you want to enable it? (y/n): " ans
        if [[ $ans =~ ^[Yy]$ ]]; then
            mailing_enabled=true
            echo "Mailing has been enabled"
            (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        else
            echo "Mailing remains disabled"
        fi
    fi
}

while true; do
    echo "=================="
    echo "      Menu        "
    echo "=================="
    echo "1. Check Disk Usage"
    echo "2. Monitor Running Services"
    echo "3. Assess Memory Usage"
    echo "4. Evaluate CPU Usage"
    echo "5. Enable email reporting (every 4 hours)"
    echo "0. Exit"
    echo "=================="

    read -p "Enter choice [0-5]:" choice

    case "$choice" in
    1) 
        echo "Fetching disk usage"
        disk_usage
        ;;
    2)
        echo "Listing running services"
        running_services
        ;;
    3)
        echo "Printing memory usage information"
        mem_usage
        ;;
    4)
        echo "Fetching cpu usage"
        cpu_usage
        ;;
    5) 
        email_reporting
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    esac

    echo 
done

