#!/bin/bash

# Full Server Backup Script
# Cria backup completo de tudo importante no servidor

set -euo pipefail

BACKUP_NAME="full-backup-$(date +%Y%m%d-%H%M)"
BACKUP_DIR="$HOME/$BACKUP_NAME"
FINAL_FILE="$HOME/${BACKUP_NAME}.tar.gz"

echo "╔════════════════════════════════════════════════════╗"
echo "║  💾 BACKUP COMPLETO DO SERVIDOR                    ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Iniciado em: $(date '+%d/%m/%Y %H:%M:%S')"
echo ""

# Criar diretório
mkdir -p "$BACKUP_DIR"/{configs,docker,systemd,data}

# ======================================
# DADOS DOS SERVIÇOS
# ======================================

echo "📦 Backup de dados dos serviços..."

if [ -d "$HOME/n8n-data" ]; then
    echo "  → n8n data"
    tar -czf "$BACKUP_DIR/data/n8n-data.tar.gz" -C "$HOME" n8n-data 2>/dev/null || echo "    ⚠️  Erro ao fazer backup n8n"
fi

if [ -d "$HOME/npm-data" ]; then
    echo "  → Nginx Proxy Manager"
    tar -czf "$BACKUP_DIR/data/npm-data.tar.gz" -C "$HOME" npm-data 2>/dev/null || echo "    ⚠️  Erro ao fazer backup NPM"
fi

if [ -d "$HOME/rustdesk" ]; then
    echo "  → RustDesk"
    tar -czf "$BACKUP_DIR/data/rustdesk.tar.gz" -C "$HOME" rustdesk 2>/dev/null || echo "    ⚠️  Erro ao fazer backup RustDesk"
fi

if [ -d "$HOME/n8n_workflows_backup" ]; then
    echo "  → n8n workflows"
    tar -czf "$BACKUP_DIR/data/n8n-workflows.tar.gz" -C "$HOME" n8n_workflows_backup 2>/dev/null || echo "    ⚠️  Erro ao fazer backup workflows"
fi

# ======================================
# CONFIGURAÇÕES
# ======================================

echo ""
echo "⚙️  Backup de configurações..."

# SSH
if [ -d "$HOME/.ssh" ]; then
    echo "  → SSH keys"
    cp -r "$HOME/.ssh" "$BACKUP_DIR/configs/" 2>/dev/null || echo "    ⚠️  Erro ao copiar .ssh"
fi

# Oracle CLI
if [ -d "$HOME/.oci" ]; then
    echo "  → Oracle CLI"
    cp -r "$HOME/.oci" "$BACKUP_DIR/configs/" 2>/dev/null || echo "    ⚠️  Erro ao copiar .oci"
fi

# Bashrc
if [ -f "$HOME/.bashrc" ]; then
    echo "  → .bashrc"
    cp "$HOME/.bashrc" "$BACKUP_DIR/configs/"
fi

# msmtprc (email)
if [ -f "$HOME/.msmtprc" ]; then
    echo "  → .msmtprc (email config)"
    cp "$HOME/.msmtprc" "$BACKUP_DIR/configs/"
fi

# ======================================
# SCRIPTS
# ======================================

echo ""
echo "📜 Backup de scripts..."

if [ -d "$HOME/scripts" ]; then
    echo "  → ~/scripts"
    tar -czf "$BACKUP_DIR/scripts.tar.gz" -C "$HOME" scripts 2>/dev/null
fi

# ======================================
# DOCKER
# ======================================

echo ""
echo "🐳 Backup de configurações Docker..."

[ -f "$HOME/docker-compose.yml" ] && cp "$HOME/docker-compose.yml" "$BACKUP_DIR/docker/" && echo "  → docker-compose.yml"
[ -f "$HOME/.env" ] && cp "$HOME/.env" "$BACKUP_DIR/docker/" && echo "  → .env"

# Salvar imagens Docker (opcional, comentado por ser grande)
# docker save $(docker images -q) -o "$BACKUP_DIR/docker/images.tar"

# ======================================
# SYSTEMD SERVICES
# ======================================

echo ""
echo "⚙️  Backup de serviços systemd..."

if [ -f "/etc/systemd/system/cpu-keepalive.service" ]; then
    sudo cp /etc/systemd/system/cpu-keepalive.service "$BACKUP_DIR/systemd/" 2>/dev/null && echo "  → cpu-keepalive.service"
fi

# ======================================
# CRONTAB
# ======================================

echo ""
echo "⏰ Backup de crontab..."

crontab -l > "$BACKUP_DIR/crontab.txt" 2>/dev/null && echo "  → crontab" || echo "  ⚠️  Nenhum crontab configurado"

# ======================================
# INFO DO SISTEMA
# ======================================

echo ""
echo "ℹ️  Coletando informações do sistema..."

cat > "$BACKUP_DIR/system-info.txt" << EOF
════════════════════════════════════════════════════
INFORMAÇÕES DO SISTEMA - BACKUP
════════════════════════════════════════════════════

Backup criado em: $(date '+%d/%m/%Y %H:%M:%S')
Hostname: $(hostname)
OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
Kernel: $(uname -r)
Uptime: $(uptime -p)

════════════════════════════════════════════════════
DOCKER
════════════════════════════════════════════════════

Docker Version: $(docker --version 2>/dev/null || echo "Não instalado")

Containers ativos:
$(docker ps --format "{{.Names}}: {{.Image}} ({{.Status}})" 2>/dev/null || echo "Nenhum container")

════════════════════════════════════════════════════
REDE
════════════════════════════════════════════════════

IPs:
$(ip -4 addr show 2>/dev/null | grep inet | grep -v 127.0.0.1 || echo "Erro ao obter IPs")

Portas abertas:
$(sudo ss -tulpn 2>/dev/null | grep LISTEN | awk '{print $5, $7}' | sort -u || echo "Erro ao listar portas")

════════════════════════════════════════════════════
STORAGE
════════════════════════════════════════════════════

$(df -h / /home 2>/dev/null | grep -v tmpfs)

════════════════════════════════════════════════════
MEMÓRIA
════════════════════════════════════════════════════

$(free -h)

════════════════════════════════════════════════════
SERVIÇOS IMPORTANTES
════════════════════════════════════════════════════

CPU Keep-Alive: $(systemctl is-active cpu-keepalive 2>/dev/null || echo "não instalado")
Unattended-upgrades: $(systemctl is-active unattended-upgrades 2>/dev/null || echo "não instalado")
Fail2ban: $(systemctl is-active fail2ban 2>/dev/null || echo "não instalado")
UFW: $(sudo ufw status 2>/dev/null | head -1 || echo "não instalado")

════════════════════════════════════════════════════
ORACLE CLOUD INFO
════════════════════════════════════════════════════

Region: $(cat ~/.oci/config 2>/dev/null | grep region | cut -d'=' -f2 | xargs || echo "N/A")
Tenancy OCID: $(cat ~/.oci/config 2>/dev/null | grep tenancy | cut -d'=' -f2 | xargs || echo "N/A")

EOF

echo "  → system-info.txt"

# ======================================
# README
# ======================================

cat > "$BACKUP_DIR/README.txt" << EOF
════════════════════════════════════════════════════
BACKUP COMPLETO - ORACLE FREE SERVER
════════════════════════════════════════════════════

Data: $(date '+%d/%m/%Y %H:%M:%S')

CONTEÚDO:
---------
📁 configs/       - Configurações (.ssh, .oci, .bashrc, etc)
📁 data/          - Dados dos serviços (n8n, npm, rustdesk)
📁 docker/        - Docker compose e .env
📁 systemd/       - Serviços systemd
📄 crontab.txt    - Crontab do usuário
📄 scripts.tar.gz - Scripts customizados
📄 system-info.txt - Informações do sistema

RESTAURAÇÃO:
------------
Ver guia completo em: docs/DISASTER-RECOVERY.md

Resumo rápido:
1. Criar nova instância Oracle
2. Extrair este backup
3. Copiar configs para ~/.ssh, ~/.oci, etc
4. Extrair dados para ~/
5. Subir docker-compose
6. Configurar serviços systemd
7. Restaurar crontab

IMPORTANTE:
-----------
⚠️  Mantenha este backup em múltiplos locais:
   - Google Drive (primary)
   - HD externo (secondary)
   - Outro cloud (tertiary)

⚠️  Chaves SSH e Oracle CLI são CRÍTICAS para acesso!

⚠️  Teste restauração pelo menos 1x por ano!

════════════════════════════════════════════════════
Gerado por: Oracle Free Server Guide
https://github.com/wolsadek/oracle-free-server-guide
════════════════════════════════════════════════════
EOF

# ======================================
# COMPACTAR TUDO
# ======================================

echo ""
echo "🗜️  Compactando backup..."

cd "$HOME"
tar -czf "$FINAL_FILE" "$BACKUP_NAME/" 2>/dev/null

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$FINAL_FILE" | cut -f1)
    echo "  ✅ Backup compactado: $BACKUP_SIZE"
    
    # Limpar diretório temporário
    rm -rf "$BACKUP_DIR"
else
    echo "  ❌ Erro ao compactar backup"
    exit 1
fi

# ======================================
# UPLOAD PARA GOOGLE DRIVE
# ======================================

echo ""
echo "☁️  Enviando para Google Drive..."

if command -v rclone &> /dev/null; then
    if rclone copy "$FINAL_FILE" gdrive:Backups/ServidorOracle/FullBackup/ 2>/dev/null; then
        echo "  ✅ Upload concluído!"
    else
        echo "  ⚠️  Erro no upload - verifique configuração do rclone"
    fi
else
    echo "  ⚠️  rclone não instalado - backup salvo apenas localmente"
fi

# ======================================
# LIMPAR BACKUPS ANTIGOS
# ======================================

echo ""
echo "🧹 Limpando backups antigos (mantém últimos 3)..."

cd "$HOME"
ls -t full-backup-*.tar.gz 2>/dev/null | tail -n +4 | xargs rm -f 2>/dev/null || true

# ======================================
# RESUMO FINAL
# ======================================

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║  ✅ BACKUP COMPLETO FINALIZADO                     ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "📄 Arquivo: $FINAL_FILE"
echo "📊 Tamanho: $(du -h "$FINAL_FILE" | cut -f1)"
echo "⏰ Concluído: $(date '+%d/%m/%Y %H:%M:%S')"
echo ""
echo "💡 Próximos passos:"
echo "   1. Baixar cópia local (backup externo)"
echo "   2. Verificar se está no Google Drive"
echo "   3. Testar restauração (1x por ano)"
echo ""
echo "📖 Documentação completa: docs/DISASTER-RECOVERY.md"
echo ""
