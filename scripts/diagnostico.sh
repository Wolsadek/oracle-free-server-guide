#!/bin/bash

# Script de Diagnóstico Completo
# Gera relatório do estado atual do servidor

echo "=========================================="
echo "  DIAGNÓSTICO DO SERVIDOR ORACLE CLOUD"
echo "=========================================="
echo ""
echo "Data: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo ""

echo "==================== SISTEMA ===================="
echo ""

echo "==> Versão do OS"
lsb_release -a 2>/dev/null || cat /etc/os-release
echo ""

echo "==> Uso de Disco"
df -h / /home | grep -v tmpfs
echo ""

echo "==> Uso de Memória"
free -h
echo ""

echo "==> Uso de CPU (últimos 5 min)"
uptime
echo ""

echo "==> Processos que mais usam CPU"
ps aux --sort=-%cpu | head -n 6
echo ""

echo "==> Processos que mais usam Memória"
ps aux --sort=-%mem | head -n 6
echo ""

echo "================== SEGURANÇA ===================="
echo ""

echo "==> Status do UFW Firewall"
sudo ufw status 2>/dev/null || echo "UFW não instalado"
echo ""

echo "==> Status do Fail2Ban"
if systemctl is-active --quiet fail2ban 2>/dev/null; then
    echo "✅ Fail2Ban ativo"
    sudo fail2ban-client status sshd 2>/dev/null || true
else
    echo "❌ Fail2Ban não está rodando"
fi
echo ""

echo "==> Últimas tentativas de login SSH"
sudo tail -n 10 /var/log/auth.log 2>/dev/null | grep -E "Failed|Accepted" || echo "Nenhuma tentativa recente"
echo ""

echo "================== SERVIÇOS ===================="
echo ""

echo "==> CPU Keep-Alive Status"
if systemctl is-active --quiet cpu-keepalive 2>/dev/null; then
    echo "✅ CPU Keep-Alive ativo"
    systemctl status cpu-keepalive --no-pager -l | head -n 10
else
    echo "❌ CPU Keep-Alive NÃO está rodando!"
fi
echo ""

echo "==> Unattended Upgrades Status"
if systemctl is-active --quiet unattended-upgrades 2>/dev/null; then
    echo "✅ Unattended-upgrades ativo"
else
    echo "❌ Unattended-upgrades não está rodando"
fi
echo ""

echo "================== DOCKER ===================="
echo ""

if command -v docker &> /dev/null; then
    echo "==> Containers Rodando"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Erro ao listar containers"
    echo ""
    
    echo "==> Uso de Recursos (Docker)"
    docker stats --no-stream 2>/dev/null || echo "Erro ao obter stats"
    echo ""
    
    echo "==> Uso de Disco (Docker)"
    docker system df 2>/dev/null || echo "Erro ao obter disk usage"
    echo ""
    
    echo "==> Containers com problemas"
    docker ps -a --filter "status=exited" --filter "status=restarting" 2>/dev/null || echo "Nenhum container com problema"
    echo ""
else
    echo "❌ Docker não está instalado"
    echo ""
fi

echo "================== REDE ===================="
echo ""

echo "==> Portas Abertas (Listening)"
sudo ss -tulpn | grep LISTEN | awk '{print $5, $7}' | sort -u
echo ""

echo "==> IP Público"
curl -s ifconfig.me || curl -s icanhazip.com || echo "Não foi possível obter IP público"
echo ""

echo "==> Conexões Ativas"
sudo ss -tupn | grep ESTAB | wc -l
echo " conexões estabelecidas"
echo ""

echo "================== BACKUPS ===================="
echo ""

echo "==> Scripts de Backup"
if [ -d "$HOME/scripts" ]; then
    ls -lh "$HOME/scripts/"*.sh 2>/dev/null || echo "Nenhum script encontrado"
else
    echo "Diretório ~/scripts não existe"
fi
echo ""

echo "==> Últimos Backups (rclone)"
if command -v rclone &> /dev/null; then
    echo "Logs de backup n8n:"
    tail -n 3 "$HOME/rclone_n8n_backup.log" 2>/dev/null || echo "Nenhum log encontrado"
    echo ""
    echo "Logs de backup workflows:"
    tail -n 3 "$HOME/rclone_workflows_backup.log" 2>/dev/null || echo "Nenhum log encontrado"
else
    echo "rclone não está instalado"
fi
echo ""

echo "================== MONITORAMENTO ===================="
echo ""

echo "==> Logs de Monitoramento OCI"
if [ -d "/var/log/oci" ]; then
    echo "CPU Monitor:"
    tail -n 2 /var/log/oci/cpu_monitor.log 2>/dev/null || echo "Nenhum log"
    echo ""
    echo "Storage Monitor:"
    tail -n 2 /var/log/oci/storage_monitor.log 2>/dev/null || echo "Nenhum log"
    echo ""
    echo "Bandwidth Monitor:"
    tail -n 2 /var/log/oci/bandwidth_monitor.log 2>/dev/null || echo "Nenhum log"
else
    echo "❌ Diretório /var/log/oci não existe - monitoramento não configurado"
fi
echo ""

echo "==> Crontab do usuário"
crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" || echo "Nenhum cron configurado"
echo ""

echo "================== ATUALIZAÇÕES ===================="
echo ""

echo "==> Pacotes que podem ser atualizados"
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
if [ "$UPDATES" -gt 0 ]; then
    echo "⚠️  $UPDATES pacotes podem ser atualizados"
else
    echo "✅ Sistema está atualizado"
fi
echo ""

echo "==> Últimas atualizações automáticas"
tail -n 5 /var/log/unattended-upgrades/unattended-upgrades.log 2>/dev/null || echo "Nenhum log disponível"
echo ""

echo "================== ALERTAS ===================="
echo ""

# Alertas críticos
CRITICAL=0

# CPU Keep-Alive
if ! systemctl is-active --quiet cpu-keepalive 2>/dev/null; then
    echo "🚨 CRÍTICO: CPU Keep-Alive não está rodando!"
    CRITICAL=$((CRITICAL + 1))
fi

# Disco cheio
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "⚠️  AVISO: Disco está com ${DISK_USAGE}% de uso!"
    CRITICAL=$((CRITICAL + 1))
fi

# Memória
MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
if [ "$MEM_USAGE" -gt 90 ]; then
    echo "⚠️  AVISO: Memória está com ${MEM_USAGE}% de uso!"
    CRITICAL=$((CRITICAL + 1))
fi

# Containers parados
if command -v docker &> /dev/null; then
    STOPPED=$(docker ps -a -f "status=exited" -q | wc -l)
    if [ "$STOPPED" -gt 0 ]; then
        echo "⚠️  AVISO: $STOPPED container(s) parado(s)"
        CRITICAL=$((CRITICAL + 1))
    fi
fi

# Updates pendentes
if [ "$UPDATES" -gt 50 ]; then
    echo "⚠️  AVISO: Muitas atualizações pendentes ($UPDATES)"
    CRITICAL=$((CRITICAL + 1))
fi

if [ "$CRITICAL" -eq 0 ]; then
    echo "✅ Nenhum alerta crítico!"
fi

echo ""
echo "=========================================="
echo "  FIM DO DIAGNÓSTICO"
echo "=========================================="
echo ""
echo "Para salvar este relatório:"
echo "./diagnostico.sh > diagnostico-\$(date +%Y%m%d).txt"
echo ""
