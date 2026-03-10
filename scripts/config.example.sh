#!/bin/bash

# Example Configuration File
# Copy this file and customize with your own values:
# cp config.example.sh config.local.sh

# ===========================================
# SLACK CONFIGURATION
# ===========================================
# Get your webhook from: https://api.slack.com/apps
WEBHOOK_URL="https://hooks.slack.com/services/YOUR_WEBHOOK_URL_HERE"

# ===========================================
# ORACLE CLOUD CONFIGURATION
# ===========================================
# Your Compartment OCID (same as Tenancy OCID for root compartment)
# Find it at: Oracle Console → Profile → Tenancy
COMPARTMENT_ID="ocid1.tenancy.oc1..aaaaaaaa..."

# ===========================================
# N8N CONFIGURATION (Optional)
# ===========================================
# Your n8n instance URL
N8N_URL="http://localhost:5678"

# N8N API Key
# Generate at: n8n → Settings → API → Create API Key
N8N_API_KEY="YOUR_N8N_API_KEY_HERE"

# ===========================================
# RCLONE CONFIGURATION (Optional)
# ===========================================
# Name of your rclone remote (configured with 'rclone config')
RCLONE_REMOTE="gdrive"

# Google Drive backup paths
RCLONE_N8N_DATA_PATH="Backups/ServidorOracle/n8n"
RCLONE_N8N_WORKFLOWS_PATH="Backups/ServidorOracle/n8n-workflows-json"

# ===========================================
# DIRECTORIES
# ===========================================
N8N_DATA_DIR="/home/ubuntu/n8n-data"
N8N_BACKUP_DIR="/home/ubuntu/n8n_workflows_backup"
SCRIPT_DIR="/opt/oci_scripts/monitoring"
LOG_DIR="/var/log/oci"
