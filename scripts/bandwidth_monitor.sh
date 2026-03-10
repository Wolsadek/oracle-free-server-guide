#!/bin/bash

# Oracle Cloud Bandwidth Monitor with Slack Alerts
# Monitors monthly 10TB Always Free limit and sends alerts every 1%

set -euo pipefail

# Configuration
SCRIPT_DIR="/opt/oci_scripts/monitoring"
LOG_DIR="/var/log/oci"
LOG_FILE="$LOG_DIR/bandwidth_monitor.log"
ALERT_STATE_FILE="$SCRIPT_DIR/bandwidth_alerts_sent.txt"
WEBHOOK_URL="https://hooks.slack.com/services/YOUR_WEBHOOK_URL_HERE"

# Oracle Cloud Configuration
COMPARTMENT_ID="YOUR_COMPARTMENT_ID_HERE"

# Bandwidth Limits
MONTHLY_LIMIT_GB=10240  # 10TB in GB
ALERT_INCREMENT=1       # Alert every 1%

# Logging function - only logs to file, not stdout
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Logging function that also prints to console (for main script flow)
log_console() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    local gb=$(( bytes / 1024 / 1024 / 1024 ))
    local mb=$(( (bytes / 1024 / 1024) % 1024 ))
    
    if [ "$gb" -gt 0 ]; then
        echo "${gb}.$(( (mb * 100) / 1024 )) GB"
    else
        echo "$mb MB"
    fi
}

# Send Slack notification
send_slack_alert() {
    local message="$1"
    local percentage="$2"
    local usage_formatted="$3"
    
    local payload=$(cat <<EOF
{
    "text": "Oracle Cloud Bandwidth Alert",
    "attachments": [
        {
            "color": "warning",
            "fields": [
                {
                    "title": "Bandwidth Usage Alert",
                    "value": "$message",
                    "short": false
                },
                {
                    "title": "Current Usage",
                    "value": "${usage_formatted} (${percentage}%)",
                    "short": true
                },
                {
                    "title": "Monthly Limit",
                    "value": "${MONTHLY_LIMIT_GB} GB",
                    "short": true
                }
            ]
        }
    ]
}
EOF
)
    
    local response
    response=$(curl -X POST -H 'Content-type: application/json' \
         --data "$payload" \
         "$WEBHOOK_URL" 2>&1)
    
    log_message "Slack alert sent: $message (Response: $response)"
}

# Get bandwidth usage for specific metric
get_metric_usage() {
    local metric_name="$1"
    local month_start="$2"
    local current_time="$3"
    
    local bandwidth_data
    bandwidth_data=$(oci monitoring metric-data summarize-metrics-data \
        --compartment-id "$COMPARTMENT_ID" \
        --namespace "oci_internet_gateway" \
        --query-text "${metric_name}[1h].sum()" \
        --start-time "$month_start" \
        --end-time "$current_time" \
        --output json 2>&1)
    
    local oci_exit_code=$?
    
    if [ $oci_exit_code -ne 0 ]; then
        log_message "WARN: Failed to query $metric_name"
        echo "0"
        return 1
    fi
    
    local total_bytes
    total_bytes=$(echo "$bandwidth_data" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    total = 0
    count = 0
    for item in data.get('data', []):
        for point in item.get('aggregated-datapoints', []):
            value = point.get('value', 0)
            if value > 0:
                total += value
                count += 1
    print(int(total))
except Exception as e:
    print('0')
" 2>/dev/null)
    
    echo "${total_bytes:-0}"
}

# Get total bandwidth usage for current month (both inbound and outbound)
get_monthly_bandwidth_usage() {
    source /opt/oracle-cli-venv/bin/activate
    
    local month_start=$(date -d "$(date +%Y-%m-01)" '+%Y-%m-%dT00:00:00Z')
    local current_time=$(date '+%Y-%m-%dT%H:%M:%SZ')
    
    log_message "Querying bandwidth usage from $month_start to $current_time"
    
    local bytes_from_igw
    bytes_from_igw=$(get_metric_usage "BytesFromIgw" "$month_start" "$current_time")
    log_message "BytesFromIgw (inbound): $bytes_from_igw bytes"
    
    local bytes_to_igw
    bytes_to_igw=$(get_metric_usage "BytesToIgw" "$month_start" "$current_time")
    log_message "BytesToIgw (outbound): $bytes_to_igw bytes"
    
    local total_bytes=$(( bytes_from_igw + bytes_to_igw ))
    log_message "Total bandwidth usage: $total_bytes bytes ($(format_bytes $total_bytes))"
    
    echo "$total_bytes"
}

# Check if alert for this percentage was already sent
alert_already_sent() {
    local percentage="$1"
    
    if [ ! -f "$ALERT_STATE_FILE" ]; then
        touch "$ALERT_STATE_FILE"
        return 1
    fi
    
    grep -q "^$percentage$" "$ALERT_STATE_FILE"
}

# Mark alert as sent
mark_alert_sent() {
    local percentage="$1"
    echo "$percentage" >> "$ALERT_STATE_FILE"
}

# Reset alert state at start of new month
reset_monthly_alerts() {
    local current_month
    current_month="$(date '+%Y%m')"
    local last_reset_file="$SCRIPT_DIR/.last_reset_month"
    
    log_message "DEBUG: current_month='$current_month'"
    
    local last_month=""
    if [ -f "$last_reset_file" ]; then
        last_month="$(cat "$last_reset_file" 2>/dev/null || echo '')"
        log_message "DEBUG: last_month='$last_month'"
    fi
    
    if [ "$last_month" != "$current_month" ]; then
        log_message "New month detected, resetting alert state"
        > "$ALERT_STATE_FILE"
        echo "$current_month" > "$last_reset_file"
    fi
}

# Main monitoring function
monitor_bandwidth() {
    log_console "Starting bandwidth monitoring check"
    
    reset_monthly_alerts
    
    local usage_bytes
    usage_bytes=$(get_monthly_bandwidth_usage)
    local exit_code=$?
    
    if [ $exit_code -ne 0 ] || [ -z "$usage_bytes" ] || ! [[ "$usage_bytes" =~ ^[0-9]+$ ]]; then
        log_console "ERROR: Could not retrieve valid bandwidth usage"
        return 1
    fi
    
    local usage_gb_precise=$(( (usage_bytes * 1000) / 1024 / 1024 / 1024 ))
    local percentage_precise=$(( (usage_gb_precise * 100) / MONTHLY_LIMIT_GB ))
    local percentage=$(( percentage_precise / 1000 ))
    
    local usage_formatted=$(format_bytes "$usage_bytes")
    
    log_console "Current monthly usage: ${usage_formatted} (${percentage}.$(( (percentage_precise % 1000) / 10 ))% of ${MONTHLY_LIMIT_GB} GB limit)"
    
    log_message "Note: Oracle Always Free tier counts outbound bandwidth (BytesToIgw) against the 10TB monthly limit"
    
    if [ "$percentage" -eq 0 ] && [ "$usage_bytes" -gt 0 ] && ! alert_already_sent "INITIAL"; then
        send_slack_alert "Bandwidth monitoring active. Current usage: ${usage_formatted}" "0" "$usage_formatted"
        mark_alert_sent "INITIAL"
    fi
    
    local i
    for ((i=ALERT_INCREMENT; i<=percentage; i+=ALERT_INCREMENT)); do
        if ! alert_already_sent "$i"; then
            local message="ALERT: Oracle Cloud bandwidth usage has reached ${i}% of monthly limit"
            send_slack_alert "$message" "$i" "$usage_formatted"
            mark_alert_sent "$i"
        fi
    done
    
    if [ "$percentage" -ge 80 ] && ! alert_already_sent "WARNING_80"; then
        send_slack_alert "WARNING: Bandwidth usage at ${percentage}% - approaching limit" "$percentage" "$usage_formatted"
        mark_alert_sent "WARNING_80"
    fi
    
    if [ "$percentage" -ge 90 ] && ! alert_already_sent "CRITICAL_90"; then
        send_slack_alert "CRITICAL: Bandwidth usage at ${percentage}% - immediate attention required" "$percentage" "$usage_formatted"
        mark_alert_sent "CRITICAL_90"
    fi
    
    if [ "$percentage" -ge 95 ] && ! alert_already_sent "URGENT_95"; then
        send_slack_alert "URGENT: Bandwidth usage at ${percentage}% - risk of overage charges!" "$percentage" "$usage_formatted"
        mark_alert_sent "URGENT_95"
    fi
    
    log_console "Bandwidth monitoring check completed"
}

# Error handler
error_handler() {
    local line_no=$1
    log_console "ERROR: Script failed at line $line_no"
    exit 1
}

trap 'error_handler $LINENO' ERR

# Create directories
mkdir -p "$SCRIPT_DIR"

if [ ! -d "$LOG_DIR" ]; then
    sudo mkdir -p "$LOG_DIR"
    sudo chown ubuntu:ubuntu "$LOG_DIR"
fi

# Check for Oracle CLI virtual environment
if [ ! -d "/opt/oracle-cli-venv" ]; then
    log_console "ERROR: Oracle CLI virtual environment not found at /opt/oracle-cli-venv"
    exit 1
fi

# Run the monitoring
monitor_bandwidth

exit 0
