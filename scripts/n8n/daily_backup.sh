#!/bin/bash

# N8N Daily Backup Script
# Backs up n8n data folder to Google Drive using rclone

# --- CONFIGURAÇÃO ---
# Nome do seu "remote" do rclone (o que criamos antes)
REMOTE_NAME="gdrive"

# Pasta no seu Google Drive onde os backups serão salvos
# (ela será criada automaticamente se não existir)
DRIVE_FOLDER="Backups/ServidorOracle/n8n"

# Pasta local no seu servidor que será backupeada
LOCAL_FOLDER="/home/ubuntu/n8n-data"

# Arquivo de log para registrar as atividades do backup
LOG_FILE="/home/ubuntu/rclone_n8n_backup.log"

# --- FIM DA CONFIGURAÇÃO ---

echo "-------------------------------------" >> $LOG_FILE
echo "Iniciando backup do n8n para o Google Drive..." >> $LOG_FILE
date >> $LOG_FILE

# O comando mágico: sincroniza a pasta local com a pasta na nuvem
# --log-file=$LOG_FILE : Registra tudo o que acontece no nosso arquivo de log
rclone sync "$LOCAL_FOLDER" "$REMOTE_NAME:$DRIVE_FOLDER" --log-file=$LOG_FILE -v

echo "Backup concluído!" >> $LOG_FILE
date >> $LOG_FILE
echo "-------------------------------------" >> $LOG_FILE
