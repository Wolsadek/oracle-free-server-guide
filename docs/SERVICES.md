# Serviços e Aplicações

Documentação dos serviços rodando no servidor Oracle Cloud Always Free.

## 📦 Container Stack

### Nginx Proxy Manager (npm)

Dashboard web para gerenciar proxy reverso, SSL certificates e redirecionamentos.

**Portas**:
- 80 (HTTP)
- 81 (Admin Interface - https://seu-ip:81)
- 443 (HTTPS)

**Acesso**: 
- URL: `http://seu-ip:81`
- Login padrão:
  - Email: `admin@example.com`
  - Password: `changeme`
  - ⚠️ **MUDE A SENHA IMEDIATAMENTE APÓS PRIMEIRO LOGIN!**

**Docker Compose**:
```yaml
version: '3.8'

services:
  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: npm
    restart: unless-stopped
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    environment:
      DB_SQLITE_FILE: "/data/database.sqlite"
```

**Funcionalidades**:
- Proxy Hosts (redirecionar domínios para containers/serviços)
- SSL Certificates automáticos via Let's Encrypt
- Access Lists (controle de acesso)
- Stream (TCP/UDP proxying)

---

### n8n - Workflow Automation

Ferramenta de automação similar ao Zapier/Make.

**Porta**: 5678 (localhost apenas, exposto via Nginx Proxy Manager)

**Acesso**: Configure um Proxy Host no Nginx Proxy Manager para expor via domínio

**Docker Compose**:
```yaml
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - '127.0.0.1:5678:5678'
    volumes:
      - ./n8n-data:/home/node/.n8n
    environment:
      - N8N_HOST=n8n.seu-dominio.com
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://n8n.seu-dominio.com/
```

**Backups**: Veja [scripts de backup](../scripts/n8n/)

---

### RustDesk Server

Servidor próprio de acesso remoto (alternativa ao TeamViewer/AnyDesk).

**Por que usar servidor próprio?**
- Privacidade total
- Sem limite de dispositivos
- Sem mensalidades
- Controle completo dos dados

**Portas**:
- 21115 (TCP) - hbbs web console
- 21116 (TCP) - hbbs TCP hole punching
- 21117 (TCP) - hbbr relay
- 21118 (TCP) - hbbs websocket
- 21119 (TCP) - hbbr websocket

**Docker Compose**:
```yaml
version: '3.8'

services:
  hbbs:
    image: rustdesk/rustdesk-server:latest
    container_name: hbbs
    restart: unless-stopped
    command: hbbs -r rustdesk.seu-dominio.com:21117
    volumes:
      - ./rustdesk:/root
    network_mode: "host"
    depends_on:
      - hbbr

  hbbr:
    image: rustdesk/rustdesk-server:latest
    container_name: hbbr
    restart: unless-stopped
    command: hbbr
    volumes:
      - ./rustdesk:/root
    network_mode: "host"
```

**Configuração do Cliente RustDesk**:

1. Baixe o cliente: https://rustdesk.com/
2. Clique em "⋮" ao lado de "Ready"
3. Settings → Network → ID Server
4. Configure:
   - ID Server: `seu-ip-ou-dominio`
   - Relay Server: `seu-ip-ou-dominio`
   - API Server: `http://seu-ip-ou-dominio:21114` (opcional)
   - Key: (encontre em `~/rustdesk/id_ed25519.pub`)

**Obter a chave pública**:
```bash
cat ~/rustdesk/id_ed25519.pub
```

**Firewall Oracle Cloud**:
Certifique-se de liberar as portas 21115-21119 no Security List da VCN.

---

### Watchtower - Auto-Update de Containers

Monitora e atualiza automaticamente os containers Docker quando novas imagens estão disponíveis.

**Docker Compose**:
```yaml
version: '3.8'

services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_SCHEDULE=0 0 4 * * *  # Verifica às 4h da manhã
      - WATCHTOWER_NOTIFICATIONS=slack
      - WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=https://hooks.slack.com/services/YOUR_WEBHOOK
    command: --interval 86400  # Verifica a cada 24h
```

**Configurações**:
- `--cleanup`: Remove imagens antigas após update
- `--schedule`: Cron schedule (4h da manhã)
- Pode notificar via Slack, Discord, Email, etc.

**Excluir containers específicos**:
```yaml
services:
  meu-container:
    labels:
      - "com.centurylinklabs.watchtower.enable=false"
```

---

## 🔧 Serviços do Sistema

### Unattended Upgrades

Atualizações automáticas de segurança do sistema.

**Status**:
```bash
systemctl status unattended-upgrades
```

**Configuração**: `/etc/apt/apt.conf.d/50unattended-upgrades`

**Recursos configurados**:
- ✅ Auto-install security updates
- ✅ Auto-reboot às 07:00 quando necessário
- ✅ Remove pacotes não utilizados após upgrade

**Logs**:
```bash
# Ver últimos updates
cat /var/log/unattended-upgrades/unattended-upgrades.log

# Ver histórico de instalação
grep "Unattended-Upgrade" /var/log/dpkg.log
```

**Desabilitar temporariamente**:
```bash
sudo systemctl stop unattended-upgrades
```

---

## 📊 Portas em Uso

| Porta | Serviço | Descrição |
|-------|---------|-----------|
| 22 | SSH | Acesso remoto |
| 80 | Nginx PM | HTTP |
| 81 | Nginx PM | Admin Interface |
| 443 | Nginx PM | HTTPS |
| 5678 | n8n | Workflow automation (localhost) |
| 21115-21119 | RustDesk | Remote desktop server |

---

## 🔐 Segurança

### Firewall (UFW)

Se ainda não configurou, recomenda-se:

```bash
# Instalar UFW
sudo apt install ufw -y

# Permitir SSH
sudo ufw allow 22/tcp

# Permitir HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Permitir Nginx Proxy Manager admin
sudo ufw allow 81/tcp

# Permitir RustDesk
sudo ufw allow 21115:21119/tcp

# Habilitar
sudo ufw enable
```

### Fail2Ban

Proteção contra brute force:

```bash
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

## 🚀 Comandos Úteis

### Docker

```bash
# Ver todos os containers
docker ps -a

# Ver logs
docker logs -f nome-container

# Restart container
docker restart nome-container

# Ver uso de recursos
docker stats

# Limpar containers parados e imagens não usadas
docker system prune -a
```

### Verificar uso de recursos

```bash
# CPU e memória
htop

# Disco
df -h

# Uso por diretório
du -sh ~/* | sort -h
```

---

## 📝 Manutenção

### Backup de Configs

```bash
# Backup de todos os docker-compose
tar -czf docker-configs-backup-$(date +%Y%m%d).tar.gz \
  ~/docker-compose.yml \
  ~/n8n-data \
  ~/rustdesk \
  ~/letsencrypt

# Upload para Google Drive (via rclone)
rclone copy docker-configs-backup-*.tar.gz gdrive:Backups/ServidorOracle/configs/
```

### Updates Manuais

```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Docker containers (via Watchtower ou manualmente)
docker-compose pull
docker-compose up -d
```
