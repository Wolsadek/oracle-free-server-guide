#!/bin/bash

# Oracle Cloud CPU Monitor with Slack Alerts
# Monitors CPU usage to prevent instance reclamation (must stay above 20%)

set -euo pipefail

# Configuration
SCRIPT_DIR="/opt/oci_scripts/monitoring"
LOG_DIR="/var/log/oci"
LOG_FILE="$LOG_DIR/cpu_monitor.log"
ALERT_STATE_FILE="$SCRIPT_DIR/cpu_alerts_sent.txt"
WEBHOOK_URL="https://hooks.slack.com/services/YOUR_WEBHOOK_URL_HERE"

# Oracle Cloud Configuration
COMPARTMENT_ID="YOUR_COMPARTMENT_ID_HERE"

# CPU Thresholds
WARNING_THRESHOLD=25    # Warning below 25%
CRITICAL_THRESHOLD=20   # Critical below 20% (reclamation risk)

# Error handler
error_handler() {
    local line_no=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Script failed at line $line_no" | tee -a "$LOG_FILE"
    exit 1
}

trap 'error_handler $LINENO' ERR

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Send Slack notification
send_slack_alert() {
    local message="$1"
    local cpu_percent="$2"
    local urgency="$3"
    
    local color="warning"
    [ "$urgency" = "CRITICAL" ] && color="danger"
    
    local payload=$(cat <<EOF
{
    "text": "Oracle Cloud CPU Alert",
    "attachments": [
        {
            "color": "$color",
            "fields": [
                {
                    "title": "CPU Usage Alert",
                    "value": "$message",
                    "short": false
                },
                {
                    "title": "Current CPU Usage",
                    "value": "${cpu_percent}%",
                    "short": true
                },
                {
                    "title": "Critical Threshold",
                    "value": "${CRITICAL_THRESHOLD}% (reclamation risk)",
                    "short": true
                }
            ]
        }
    ]
}
EOF
)
    
    curl -X POST -H 'Content-type: application/json' \
         --data "$payload" \
         "$WEBHOOK_URL" 2>/dev/null
    
    log_message "Slack alert sent: $message"
}

# Get current CPU usage
get_cpu_usage() {
    source /opt/oracle-cli-venv/bin/activate
    
    local end_time=$(date '+%Y-%m-%dT%H:%M:%SZ')
    local start_time=$(date -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ')
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Querying CPU usage from $start_time to $end_time" >> "$LOG_FILE"
    
    local cpu_data
    cpu_data=$(oci monitoring metric-data summarize-metrics-data \
        --compartment-id "$COMPARTMENT_ID" \
        --namespace oci_computeagent \
        --query-text "CpuUtilization[1h].mean()" \
        --start-time "$start_time" \
        --end-time "$end_time" \
        --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Failed to query CPU data" >> "$LOG_FILE"
        return 1
    fi
    
    local cpu_percent
    cpu_percent=$(echo "$cpu_data" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for item in data.get('data', []):
        points = item.get('aggregated-datapoints', [])
        if points:
            value = points[-1].get('value', 0)
            print(f'{value:.2f}')
            break
    else:
        print('0.00')
except:
    print('0.00')
")
    
    echo "$cpu_percent"
}

# Check if alert was already sent today
alert_already_sent_today() {
    local alert_type="$1"
    local today=$(date '+%Y%m%d')
    local alert_key="${alert_type}_${today}"
    
    [ -f "$ALERT_STATE_FILE" ] && grep -q "^$alert_key$" "$ALERT_STATE_FILE"
}

# Mark alert as sent for today
mark_alert_sent_today() {
    local alert_type="$1"
    local today=$(date '+%Y%m%d')
    echo "${alert_type}_${today}" >> "$ALERT_STATE_FILE"
}

# Clean old alert state (keep only last 7 days)
clean_old_alerts() {
    if [ -f "$ALERT_STATE_FILE" ]; then
        local week_ago=$(date -d '7 days ago' '+%Y%m%d')
        grep -v "_[0-9]*$" "$ALERT_STATE_FILE" > "${ALERT_STATE_FILE}.tmp" || true
        grep "_[0-9]*$" "$ALERT_STATE_FILE" | while read line; do
            local date_part=$(echo "$line" | grep -o '[0-9]*$')
            [ "$date_part" -ge "$week_ago" ] && echo "$line"
        done >> "${ALERT_STATE_FILE}.tmp" 2>/dev/null || true
        mv "${ALERT_STATE_FILE}.tmp" "$ALERT_STATE_FILE"
    fi
}

# Monitor CPU usage
monitor_cpu() {
    log_message "Starting CPU monitoring check"
    
    clean_old_alerts
    
    local cpu_percent
    cpu_percent=$(get_cpu_usage)
    
    if [ $? -ne 0 ] || [ -z "$cpu_percent" ]; then
        log_message "ERROR: Could not retrieve CPU usage"
        return 1
    fi
    
    local cpu_int=$(echo "$cpu_percent" | cut -d. -f1)
    cpu_int=${cpu_int:-0}
    
    log_message ""
    log_message "=== CPU Usage Status ==="
    log_message "Current CPU Usage: ${cpu_percent}%"
    log_message "Warning Threshold:  ${WARNING_THRESHOLD}%"
    log_message "Critical Threshold: ${CRITICAL_THRESHOLD}% (Oracle reclamation risk)"
    log_message ""
    
    if [ "$cpu_int" -lt "$CRITICAL_THRESHOLD" ]; then
        if ! alert_already_sent_today "CRITICAL_LOW_CPU"; then
            local message="CRITICAL: CPU usage at ${cpu_percent}% - Oracle may reclaim instance if this persists for 7 days"
            send_slack_alert "$message" "$cpu_percent" "CRITICAL"
            mark_alert_sent_today "CRITICAL_LOW_CPU"
        fi
    elif [ "$cpu_int" -lt "$WARNING_THRESHOLD" ]; then
        if ! alert_already_sent_today "WARNING_LOW_CPU"; then
            local message="WARNING: CPU usage at ${cpu_percent}% - approaching reclamation threshold"
            send_slack_alert "$message" "$cpu_percent" "WARNING"
            mark_alert_sent_today "WARNING_LOW_CPU"
        fi
    fi
    
    log_message "CPU monitoring check completed"
}

# Create directories
mkdir -p "$SCRIPT_DIR"
if [ ! -d "$LOG_DIR" ]; then
    sudo mkdir -p "$LOG_DIR"
    sudo chown ubuntu:ubuntu "$LOG_DIR"
fi

# Run monitoring
monitor_cpu
