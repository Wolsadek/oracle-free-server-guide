#!/bin/bash

# Oracle Cloud Storage Monitor with Slack Alerts
# Monitors Always Free storage limits: 200GB block storage, 20GB object storage

set -euo pipefail

# Configuration
SCRIPT_DIR="/opt/oci_scripts/monitoring"
LOG_DIR="/var/log/oci"
LOG_FILE="$LOG_DIR/storage_monitor.log"
ALERT_STATE_FILE="$SCRIPT_DIR/storage_alerts_sent.txt"
WEBHOOK_URL="https://hooks.slack.com/services/YOUR_WEBHOOK_URL_HERE"

# Oracle Cloud Configuration
COMPARTMENT_ID="YOUR_COMPARTMENT_ID_HERE"

# Storage Limits (Always Free)
BLOCK_STORAGE_LIMIT_GB=200
OBJECT_STORAGE_LIMIT_GB=20
ARCHIVE_STORAGE_LIMIT_GB=10

# Alert thresholds
ALERT_THRESHOLDS=(70 80 85 90 95)

# Error handler
error_handler() {
    local line_no=$1
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Script failed at line $line_no" | tee -a "$LOG_FILE"
    exit 1
}

trap 'error_handler $LINENO' ERR

# Logging function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Logging function that also prints to console
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
    local storage_type="$2"
    local usage_formatted="$3"
    local percentage="$4"
    local limit="$5"
    
    local color="warning"
    [ "$percentage" -ge 90 ] && color="danger"
    
    local payload=$(cat <<EOF
{
    "text": "Oracle Cloud Storage Alert",
    "attachments": [
        {
            "color": "$color",
            "fields": [
                {
                    "title": "Storage Usage Alert",
                    "value": "$message",
                    "short": false
                },
                {
                    "title": "Storage Type",
                    "value": "$storage_type",
                    "short": true
                },
                {
                    "title": "Current Usage",
                    "value": "${usage_formatted} (${percentage}%)",
                    "short": true
                },
                {
                    "title": "Limit",
                    "value": "${limit} GB",
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

# Get block storage usage
get_block_storage_usage() {
    source /opt/oracle-cli-venv/bin/activate
    
    log_message "Querying block storage volumes"
    
    local volumes_data
    volumes_data=$(oci bv volume list \
        --compartment-id "$COMPARTMENT_ID" \
        --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        log_message "ERROR: Failed to query block volumes"
        echo "0"
        return 1
    fi
    
    local total_gb
    total_gb=$(echo "$volumes_data" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    total = 0
    for volume in data.get('data', []):
        size_gb = volume.get('size-in-gbs', 0)
        total += size_gb
    print(total)
except Exception as e:
    print('0')
" 2>/dev/null)
    
    echo "${total_gb:-0}"
}

# Get boot volume usage
get_boot_volume_usage() {
    source /opt/oracle-cli-venv/bin/activate
    
    log_message "Querying boot volumes"
    
    local boot_volumes_data
    boot_volumes_data=$(oci bv boot-volume list \
        --compartment-id "$COMPARTMENT_ID" \
        --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        log_message "ERROR: Failed to query boot volumes"
        echo "0"
        return 1
    fi
    
    local total_gb
    total_gb=$(echo "$boot_volumes_data" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    total = 0
    for volume in data.get('data', []):
        size_gb = volume.get('size-in-gbs', 0)
        total += size_gb
    print(total)
except Exception as e:
    print('0')
" 2>/dev/null)
    
    echo "${total_gb:-0}"
}

# Get object storage usage
get_object_storage_usage() {
    source /opt/oracle-cli-venv/bin/activate
    
    log_message "Querying object storage buckets"
    
    local buckets_data
    buckets_data=$(oci os bucket list \
        --compartment-id "$COMPARTMENT_ID" \
        --output json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        log_message "WARN: Failed to query object storage buckets (may not exist)"
        echo "0"
        return 0
    fi
    
    local total_bytes=0
    echo "$buckets_data" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    bucket_names = []
    for bucket in data.get('data', []):
        bucket_names.append(bucket.get('name', ''))
    print(' '.join(bucket_names))
except:
    print('')
" | while read -r bucket_name; do
        if [ -n "$bucket_name" ]; then
            local bucket_stats
            bucket_stats=$(oci os bucket get \
                --bucket-name "$bucket_name" \
                --output json 2>/dev/null)
            
            if [ $? -eq 0 ]; then
                local bucket_size
                bucket_size=$(echo "$bucket_stats" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('data', {}).get('approximate-size', 0))
except:
    print('0')
")
                total_bytes=$((total_bytes + bucket_size))
            fi
        fi
    done
    
    local total_gb=$((total_bytes / 1024 / 1024 / 1024))
    echo "$total_gb"
}

# Check if alert was already sent today
alert_already_sent_today() {
    local alert_key="$1"
    local today=$(date '+%Y%m%d')
    local full_key="${alert_key}_${today}"
    
    [ -f "$ALERT_STATE_FILE" ] && grep -q "^$full_key$" "$ALERT_STATE_FILE"
}

# Mark alert as sent for today
mark_alert_sent_today() {
    local alert_key="$1"
    local today=$(date '+%Y%m%d')
    echo "${alert_key}_${today}" >> "$ALERT_STATE_FILE"
}

# Clean old alert states (keep only last 7 days)
clean_old_alerts() {
    if [ -f "$ALERT_STATE_FILE" ]; then
        local week_ago=$(date -d '7 days ago' '+%Y%m%d')
        grep "_[0-9]*$" "$ALERT_STATE_FILE" | while read line; do
            local date_part=$(echo "$line" | grep -o '[0-9]*$')
            [ "$date_part" -ge "$week_ago" ] && echo "$line"
        done > "${ALERT_STATE_FILE}.tmp" 2>/dev/null || true
        mv "${ALERT_STATE_FILE}.tmp" "$ALERT_STATE_FILE" 2>/dev/null || true
    fi
}

# Monitor storage usage
monitor_storage() {
    log_console "Starting storage monitoring check"
    
    clean_old_alerts
    
    local block_volumes_gb
    block_volumes_gb=$(get_block_storage_usage)
    
    local boot_volumes_gb
    boot_volumes_gb=$(get_boot_volume_usage)
    
    local total_block_gb=$((block_volumes_gb + boot_volumes_gb))
    local block_percentage=$(( (total_block_gb * 100) / BLOCK_STORAGE_LIMIT_GB ))
    
    local object_storage_gb
    object_storage_gb=$(get_object_storage_usage)
    local object_percentage=0
    [ "$object_storage_gb" -gt 0 ] && object_percentage=$(( (object_storage_gb * 100) / OBJECT_STORAGE_LIMIT_GB ))
    
    log_console ""
    log_console "=== Storage Usage Status ==="
    log_console "Block Storage (including boot): ${total_block_gb} GB / ${BLOCK_STORAGE_LIMIT_GB} GB (${block_percentage}%)"
    log_console "  - Block volumes: ${block_volumes_gb} GB"
    log_console "  - Boot volumes: ${boot_volumes_gb} GB"
    log_console "Object Storage: ${object_storage_gb} GB / ${OBJECT_STORAGE_LIMIT_GB} GB (${object_percentage}%)"
    log_console ""
    
    for threshold in "${ALERT_THRESHOLDS[@]}"; do
        if [ "$block_percentage" -ge "$threshold" ]; then
            local alert_key="BLOCK_STORAGE_${threshold}"
            if ! alert_already_sent_today "$alert_key"; then
                local message="Block storage usage at ${block_percentage}% (${total_block_gb} GB of ${BLOCK_STORAGE_LIMIT_GB} GB)"
                send_slack_alert "$message" "Block Storage" "${total_block_gb} GB" "$block_percentage" "$BLOCK_STORAGE_LIMIT_GB"
                mark_alert_sent_today "$alert_key"
            fi
        fi
    done
    
    for threshold in "${ALERT_THRESHOLDS[@]}"; do
        if [ "$object_percentage" -ge "$threshold" ]; then
            local alert_key="OBJECT_STORAGE_${threshold}"
            if ! alert_already_sent_today "$alert_key"; then
                local message="Object storage usage at ${object_percentage}% (${object_storage_gb} GB of ${OBJECT_STORAGE_LIMIT_GB} GB)"
                send_slack_alert "$message" "Object Storage" "${object_storage_gb} GB" "$object_percentage" "$OBJECT_STORAGE_LIMIT_GB"
                mark_alert_sent_today "$alert_key"
            fi
        fi
    done
    
    if [ "$block_percentage" -ge 95 ] && ! alert_already_sent_today "BLOCK_CRITICAL_95"; then
        send_slack_alert "CRITICAL: Block storage at ${block_percentage}% - immediate cleanup required!" "Block Storage" "${total_block_gb} GB" "$block_percentage" "$BLOCK_STORAGE_LIMIT_GB"
        mark_alert_sent_today "BLOCK_CRITICAL_95"
    fi
    
    if [ "$object_percentage" -ge 95 ] && ! alert_already_sent_today "OBJECT_CRITICAL_95"; then
        send_slack_alert "CRITICAL: Object storage at ${object_percentage}% - immediate cleanup required!" "Object Storage" "${object_storage_gb} GB" "$object_percentage" "$OBJECT_STORAGE_LIMIT_GB"
        mark_alert_sent_today "OBJECT_CRITICAL_95"
    fi
    
    log_console "Storage monitoring check completed"
}

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

# Run monitoring
monitor_storage
