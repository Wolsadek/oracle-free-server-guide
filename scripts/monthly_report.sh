#!/bin/bash

# Monthly Server Report
# Envia relatório mensal completo do servidor por email

set -euo pipefail

# ======================================
# CONFIGURAÇÃO
# ======================================
EMAIL_TO="estudominucioso@gmail.com"  # MUDE AQUI
COMPARTMENT_ID="YOUR_COMPARTMENT_ID_HERE"  # Seu Tenancy OCID

LOG_DIR="/var/log/oci"
REPORT_FILE="/tmp/monthly_report_$(date +%Y%m).txt"

# ======================================
# FUNÇÕES
# ======================================

log() {
    echo "$1" | tee -a "$REPORT_FILE"
}

section() {
    log ""
    log "=========================================="
    log "$1"
    log "=========================================="
    log ""
}

# Formatar bytes para humano
format_bytes() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(( bytes / 1024 ))KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$(( bytes / 1048576 ))MB"
    else
        echo "$(( bytes / 1073741824 ))GB"
    fi
}

# ======================================
# INÍCIO DO RELATÓRIO
# ======================================

# Limpar arquivo anterior
> "$REPORT_FILE"

log "╔════════════════════════════════════════════════════╗"
log "║  📊 RELATÓRIO MENSAL - ORACLE FREE SERVER          ║"
log "╚════════════════════════════════════════════════════╝"
log ""
log "Período: $(date -d '1 month ago' '+%B %Y')"
log "Gerado em: $(date '+%d/%m/%Y às %H:%M:%S')"
log ""

# ======================================
# RESUMO EXECUTIVO
# ======================================

section "📈 RESUMO EXECUTIVO"

UPTIME_DAYS=$(uptime -p)
log "⏱️  Uptime: $UPTIME_DAYS"

DISK_USAGE=$(df -h / | awk 'NR==2{print $5}')
log "💾 Uso de Disco: $DISK_USAGE de 200GB (Always Free)"

MEM_USAGE=$(free -h | awk 'NR==2{printf "%s/%s (%.0f%%)", $3, $2, ($3/$2)*100}')
log "🧠 Memória: $MEM_USAGE"

LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')
log "📊 Load Average:$LOAD_AVG"

# ======================================
# CONTAINERS DOCKER
# ======================================

section "🐳 CONTAINERS DOCKER"

if command -v docker &> /dev/null; then
    TOTAL_CONTAINERS=$(docker ps -a | wc -l)
    RUNNING_CONTAINERS=$(docker ps | wc -l)
    STOPPED_CONTAINERS=$((TOTAL_CONTAINERS - RUNNING_CONTAINERS - 1))
    
    log "Total de containers: $((TOTAL_CONTAINERS - 1))"
    log "Rodando: $((RUNNING_CONTAINERS - 1))"
    [ $STOPPED_CONTAINERS -gt 0 ] && log "⚠️  Parados: $STOPPED_CONTAINERS"
    log ""
    
    log "Status detalhado:"
    docker ps --format "  ✅ {{.Names}}: {{.Status}}" >> "$REPORT_FILE" 2>&1 || log "  Erro ao listar containers"
else
    log "Docker não está instalado"
fi

# ======================================
# MONITORAMENTO - CPU
# ======================================

section "🔥 MONITORAMENTO DE CPU"

if [ -f "$LOG_DIR/cpu_monitor.log" ]; then
    # Última medição
    LAST_CPU=$(tail -n 50 "$LOG_DIR/cpu_monitor.log" | grep "Current CPU Usage:" | tail -1 | awk '{print $5}')
    
    if [ -n "$LAST_CPU" ]; then
        log "Última medição: ${LAST_CPU}"
        
        # Verificar se teve alertas
        ALERTS=$(grep -c "WARNING\|CRITICAL" "$LOG_DIR/cpu_monitor.log" 2>/dev/null || echo "0")
        
        if [ "$ALERTS" -gt 0 ]; then
            log "⚠️  Alertas no mês: $ALERTS"
        else
            log "✅ Nenhum alerta de CPU"
        fi
    else
        log "Sem dados disponíveis"
    fi
else
    log "⚠️  Log não encontrado - monitoramento pode não estar configurado"
fi

# ======================================
# MONITORAMENTO - STORAGE
# ======================================

section "💾 MONITORAMENTO DE STORAGE"

if [ -f "$LOG_DIR/storage_monitor.log" ]; then
    # Extrair última medição
    LAST_BLOCK=$(tail -n 100 "$LOG_DIR/storage_monitor.log" | grep "Block Storage" | tail -1)
    LAST_OBJECT=$(tail -n 100 "$LOG_DIR/storage_monitor.log" | grep "Object Storage" | tail -1)
    
    if [ -n "$LAST_BLOCK" ]; then
        log "Block Storage: $(echo $LAST_BLOCK | grep -oP '\d+ GB / \d+ GB \(\d+%\)')"
    fi
    
    if [ -n "$LAST_OBJECT" ]; then
        log "Object Storage: $(echo $LAST_OBJECT | grep -oP '\d+ GB / \d+ GB \(\d+%\)')"
    fi
    
    # Alertas
    STORAGE_ALERTS=$(grep -c "ALERT\|WARNING" "$LOG_DIR/storage_monitor.log" 2>/dev/null || echo "0")
    
    if [ "$STORAGE_ALERTS" -gt 0 ]; then
        log "⚠️  Alertas no mês: $STORAGE_ALERTS"
    else
        log "✅ Storage dentro dos limites"
    fi
else
    log "⚠️  Log não encontrado"
fi

# ======================================
# MONITORAMENTO - BANDWIDTH
# ======================================

section "🌐 MONITORAMENTO DE BANDWIDTH"

if [ -f "$LOG_DIR/bandwidth_monitor.log" ]; then
    # Última medição
    LAST_BW=$(tail -n 50 "$LOG_DIR/bandwidth_monitor.log" | grep "Current monthly usage:" | tail -1)
    
    if [ -n "$LAST_BW" ]; then
        log "$LAST_BW"
        
        # Verificar se passou de 50%
        PERCENT=$(echo "$LAST_BW" | grep -oP '\d+\.\d+%' | cut -d'%' -f1 | cut -d'.' -f1)
        
        if [ "$PERCENT" -gt 50 ]; then
            log "⚠️  Atenção: Uso acima de 50% do limite mensal (10TB)"
        else
            log "✅ Bandwidth dentro do esperado"
        fi
    fi
else
    log "⚠️  Log não encontrado"
fi

# ======================================
# BACKUPS
# ======================================

section "💾 BACKUPS (n8n)"

if [ -f "$HOME/rclone_n8n_backup.log" ]; then
    LAST_BACKUP=$(tail -n 50 "$HOME/rclone_n8n_backup.log" | grep "Backup concluído!" | tail -1)
    
    if [ -n "$LAST_BACKUP" ]; then
        BACKUP_DATE=$(echo "$LAST_BACKUP" | awk '{print $1, $2}')
        log "Último backup: $BACKUP_DATE"
        
        # Contar backups do mês
        CURRENT_MONTH=$(date +%Y-%m)
        BACKUPS_COUNT=$(grep -c "$CURRENT_MONTH" "$HOME/rclone_n8n_backup.log" 2>/dev/null || echo "0")
        log "Backups realizados este mês: $BACKUPS_COUNT"
    else
        log "⚠️  Nenhum backup encontrado no log"
    fi
else
    log "⚠️  Log de backup não encontrado"
fi

# Workflows backup
if [ -f "$HOME/rclone_workflows_backup.log" ]; then
    WF_BACKUPS=$(grep -c "Sincronização com Google Drive concluída" "$HOME/rclone_workflows_backup.log" 2>/dev/null || echo "0")
    log "Backups de workflows: $WF_BACKUPS"
fi

# ======================================
# SEGURANÇA
# ======================================

section "🔒 SEGURANÇA"

# Fail2Ban
if command -v fail2ban-client &> /dev/null; then
    BANNED_IPS=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned:" | awk '{print $4}')
    TOTAL_BANNED=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Total banned:" | awk '{print $4}')
    
    log "Fail2Ban SSH:"
    log "  IPs banidos atualmente: ${BANNED_IPS:-0}"
    log "  Total de bans no mês: ${TOTAL_BANNED:-0}"
else
    log "⚠️  Fail2Ban não instalado"
fi

# UFW
if command -v ufw &> /dev/null; then
    UFW_STATUS=$(sudo ufw status | head -1 | awk '{print $2}')
    log ""
    log "Firewall (UFW): $UFW_STATUS"
else
    log "⚠️  UFW não instalado"
fi

# Tentativas de login SSH
if [ -f "/var/log/auth.log" ]; then
    FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)
    log ""
    log "Tentativas falhas de login SSH: $FAILED_LOGINS"
fi

# ======================================
# ATUALIZAÇÕES
# ======================================

section "📦 ATUALIZAÇÕES DO SISTEMA"

UPDATES_AVAILABLE=$(apt list --upgradable 2>/dev/null | grep -c upgradable)

if [ "$UPDATES_AVAILABLE" -gt 0 ]; then
    log "⚠️  $UPDATES_AVAILABLE pacotes podem ser atualizados"
else
    log "✅ Sistema atualizado"
fi

# Unattended upgrades
if systemctl is-active --quiet unattended-upgrades; then
    log "✅ Unattended-upgrades ativo (updates automáticos)"
else
    log "⚠️  Unattended-upgrades não está rodando"
fi

# ======================================
# CUSTOS
# ======================================

section "💰 CUSTOS"

log "Oracle Cloud Always Free Tier"
log ""
log "✅ Gasto atual: R$ 0,00"
log "✅ Limite mensal: R$ 0,00 (Always Free)"
log ""
log "Recursos usados dentro do Always Free:"
log "  • Compute: VM.Standard.A1.Flex"
log "  • Storage: Block (boot + volumes)"
log "  • Bandwidth: Dentro de 10TB/mês"
log "  • IP Público: 1 IPv4 fixo"

# ======================================
# RECOMENDAÇÕES
# ======================================

section "💡 RECOMENDAÇÕES"

RECOMMENDATIONS=()

# Check disk space
DISK_PERCENT=$(df / | awk 'NR==2{print $5}' | sed 's/%//')
[ "$DISK_PERCENT" -gt 80 ] && RECOMMENDATIONS+=("⚠️  Disco acima de 80% - considere limpar logs antigos")

# Check memory
MEM_PERCENT=$(free | awk 'NR==2{printf "%.0f", ($3/$2)*100}')
[ "$MEM_PERCENT" -gt 85 ] && RECOMMENDATIONS+=("⚠️  Memória acima de 85% - verifique processos pesados")

# Check updates
[ "$UPDATES_AVAILABLE" -gt 20 ] && RECOMMENDATIONS+=("📦 Mais de 20 updates pendentes - execute: sudo apt upgrade")

# Check backups
DAYS_SINCE_BACKUP=999
if [ -f "$HOME/rclone_n8n_backup.log" ]; then
    LAST_BACKUP_DATE=$(tail -n 50 "$HOME/rclone_n8n_backup.log" | grep -oP '\d{4}-\d{2}-\d{2}' | tail -1)
    if [ -n "$LAST_BACKUP_DATE" ]; then
        DAYS_SINCE_BACKUP=$(( ($(date +%s) - $(date -d "$LAST_BACKUP_DATE" +%s)) / 86400 ))
    fi
fi
[ "$DAYS_SINCE_BACKUP" -gt 7 ] && RECOMMENDATIONS+=("💾 Último backup há mais de 7 dias - verifique script de backup")

if [ ${#RECOMMENDATIONS[@]} -eq 0 ]; then
    log "✅ Tudo OK! Nenhuma ação necessária."
else
    for rec in "${RECOMMENDATIONS[@]}"; do
        log "$rec"
    done
fi

# ======================================
# PRÓXIMOS PASSOS
# ======================================

section "📅 PRÓXIMO RELATÓRIO"

NEXT_MONTH=$(date -d "+1 month" "+%B %Y")
log "Você receberá o próximo relatório em $NEXT_MONTH"
log ""
log "Para desabilitar relatórios mensais:"
log "  crontab -e"
log "  # Comente a linha do monthly_report.sh"

# ======================================
# RODAPÉ
# ======================================

log ""
log "────────────────────────────────────────────────────"
log "Gerado automaticamente por Oracle Free Server Guide"
log "https://github.com/wolsadek/oracle-free-server-guide"
log "────────────────────────────────────────────────────"

# ======================================
# ENVIAR EMAIL
# ======================================

SUBJECT="📊 Relatório Mensal - Oracle Server - $(date '+%B %Y')"

if command -v mail &> /dev/null; then
    cat "$REPORT_FILE" | mail -s "$SUBJECT" "$EMAIL_TO"
    echo "✅ Relatório enviado para $EMAIL_TO"
else
    echo "⚠️  Comando 'mail' não encontrado. Instale mailutils:"
    echo "   sudo apt install mailutils"
    echo ""
    echo "Relatório salvo em: $REPORT_FILE"
fi

# Manter backup do relatório
cp "$REPORT_FILE" "$HOME/monthly_report_$(date +%Y%m).txt"

echo "📄 Backup salvo em: $HOME/monthly_report_$(date +%Y%m).txt"
