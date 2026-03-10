#!/bin/bash

# N8N Workflow Backup Script
# Exports individual workflows via API and syncs to Google Drive

# --- CONFIGURAÇÃO ---
N8N_URL="http://localhost:5678"
API_KEY="YOUR_N8N_API_KEY_HERE"
BACKUP_DIR="/home/ubuntu/n8n_workflows_backup"
REMOTE_NAME="gdrive"
DRIVE_FOLDER="Backups/ServidorOracle/n8n-workflows-json"
LOG_FILE="/home/ubuntu/rclone_workflows_backup.log"
# --- FIM DA CONFIGURAÇÃO ---

# Cria a pasta de backup local se não existir
mkdir -p "$BACKUP_DIR"

echo "-------------------------------------" >> $LOG_FILE
echo "Iniciando backup de workflows individuais..." >> $LOG_FILE
date >> $LOG_FILE

# Pede ao n8n a lista de todos os workflows e extrai o ID e o NOME de cada um
curl -s --location "${N8N_URL}/api/v1/workflows" \
--header "accept: application/json" \
--header "X-N8N-API-KEY: ${API_KEY}" | \
jq -r '.data[] | "\(.id) \(.name)"' | \
while read -r id name; do
    # Limpa o nome do workflow para criar um nome de arquivo seguro
    filename=$(echo "$name" | sed 's/[^a-zA-Z0-9._-]/_/g').json

    echo "Fazendo backup do workflow: '$name' -> $filename" >> $LOG_FILE

    # Pede ao n8n os dados completos do workflow (em JSON) e salva no arquivo
    curl -s --location "${N8N_URL}/api/v1/workflows/${id}" \
    --header "accept: application/json" \
    --header "X-N8N-API-KEY: ${API_KEY}" > "$BACKUP_DIR/$filename"
done

echo "Backup local concluído. Sincronizando com o Google Drive..." >> $LOG_FILE

# Sincroniza a pasta de backups JSON com o Google Drive
rclone sync "$BACKUP_DIR" "$REMOTE_NAME:$DRIVE_FOLDER" --log-file=$LOG_FILE -v

echo "Sincronização com Google Drive concluída." >> $LOG_FILE
date >> $LOG_FILE
echo "-------------------------------------" >> $LOG_FILE
