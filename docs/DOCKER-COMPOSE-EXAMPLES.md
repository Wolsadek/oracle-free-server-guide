# Docker Compose - Exemplos Completos

Stack completa de containers Docker para servidor Oracle Cloud Always Free.

## 📦 Stack Completa

Arquivo único com todos os serviços organizados.

### Estrutura de Diretórios Recomendada

```
~/docker/
├── docker-compose.yml          # Stack principal
├── .env                        # Variáveis de ambiente (não commitar!)
├── npm-data/                   # Nginx Proxy Manager
├── n8n-data/                   # n8n workflows e dados
├── rustdesk/                   # RustDesk server data
└── backups/                    # Backups locais
```

### docker-compose.yml - Stack Completa

```yaml
version: '3.8'

services:
  # Nginx Proxy Manager - Reverse Proxy e SSL
  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: npm
    restart: unless-stopped
    ports:
      - '80:80'      # HTTP
      - '81:81'      # Admin UI
      - '443:443'    # HTTPS
    volumes:
      - ./npm-data:/data
      - ./letsencrypt:/etc/letsencrypt
    environment:
      DB_SQLITE_FILE: "/data/database.sqlite"
    networks:
      - proxy-network
    healthcheck:
      test: ["CMD", "/bin/check-health"]
      interval: 30s
      timeout: 3s
      retries: 3

  # n8n - Workflow Automation
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
    restart: unless-stopped
    ports:
      - '127.0.0.1:5678:5678'  # Apenas localhost
    volumes:
      - ./n8n-data:/home/node/.n8n
      - /etc/localtime:/etc/localtime:ro
    environment:
      - N8N_HOST=${N8N_HOST:-n8n.exemplo.com}
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${N8N_HOST:-n8n.exemplo.com}/
      - GENERIC_TIMEZONE=${TIMEZONE:-America/Sao_Paulo}
      - TZ=${TIMEZONE:-America/Sao_Paulo}
      # Segurança
      - N8N_BASIC_AUTH_ACTIVE=false  # Usar autenticação via NPM
      # Executors (para otimização de memória)
      - EXECUTIONS_MODE=regular
      - N8N_DIAGNOSTICS_ENABLED=false
    networks:
      - proxy-network
    depends_on:
      - npm
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 3s
      retries: 3

  # RustDesk - Remote Desktop Server (hbbs)
  hbbs:
    image: rustdesk/rustdesk-server:latest
    container_name: hbbs
    restart: unless-stopped
    command: hbbs -r ${RUSTDESK_RELAY_SERVER:-rustdesk.exemplo.com:21117}
    volumes:
      - ./rustdesk:/root
    network_mode: "host"
    depends_on:
      - hbbr

  # RustDesk - Relay Server (hbbr)
  hbbr:
    image: rustdesk/rustdesk-server:latest
    container_name: hbbr
    restart: unless-stopped
    command: hbbr
    volumes:
      - ./rustdesk:/root
    network_mode: "host"

  # Watchtower - Auto-update de containers
  watchtower:
    image: containrrr/watchtower:latest
    container_name: watchtower
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_RESTARTING=true
      - WATCHTOWER_INCLUDE_STOPPED=false
      - WATCHTOWER_SCHEDULE=0 0 4 * * *  # 4h da manhã
      - WATCHTOWER_NOTIFICATIONS=slack
      - WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=${SLACK_WEBHOOK_URL}
      - WATCHTOWER_NOTIFICATION_SLACK_IDENTIFIER=Oracle-Server-Watchtower
      - TZ=${TIMEZONE:-America/Sao_Paulo}
    command: --interval 86400  # Check a cada 24h
    networks:
      - proxy-network

networks:
  proxy-network:
    driver: bridge
```

### .env - Variáveis de Ambiente

```bash
# Timezone
TIMEZONE=America/Sao_Paulo

# n8n Configuration
N8N_HOST=n8n.seu-dominio.com

# RustDesk Configuration
RUSTDESK_RELAY_SERVER=rustdesk.seu-dominio.com:21117

# Slack Webhook (para Watchtower notifications)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR_WEBHOOK_HERE
```

## 🚀 Instalação e Deploy

### 1. Criar estrutura de diretórios

```bash
mkdir -p ~/docker/{npm-data,n8n-data,rustdesk,letsencrypt,backups}
cd ~/docker
```

### 2. Criar arquivos de configuração

```bash
# Criar docker-compose.yml
nano docker-compose.yml
# Cole o conteúdo acima

# Criar .env
nano .env
# Cole e edite as variáveis acima
```

### 3. Iniciar a stack

```bash
# Subir todos os serviços
docker-compose up -d

# Ver logs
docker-compose logs -f

# Ver status
docker-compose ps
```

### 4. Verificar saúde dos containers

```bash
# Health checks
docker-compose ps
docker inspect --format='{{.State.Health.Status}}' npm
docker inspect --format='{{.State.Health.Status}}' n8n
```

## 🔧 Comandos Úteis

### Gerenciamento

```bash
# Parar todos os serviços
docker-compose down

# Restart de um serviço específico
docker-compose restart n8n

# Ver logs de um serviço
docker-compose logs -f npm

# Atualizar um serviço
docker-compose pull n8n
docker-compose up -d n8n

# Atualizar todos
docker-compose pull
docker-compose up -d
```

### Backup

```bash
# Backup de toda a stack
docker-compose down
tar -czf docker-backup-$(date +%Y%m%d).tar.gz \
  docker-compose.yml .env npm-data/ n8n-data/ rustdesk/

# Upload para Google Drive
rclone copy docker-backup-*.tar.gz gdrive:Backups/ServidorOracle/docker/

# Subir novamente
docker-compose up -d
```

### Restauração

```bash
# Baixar backup
rclone copy gdrive:Backups/ServidorOracle/docker/docker-backup-YYYYMMDD.tar.gz ~/

# Extrair
tar -xzf docker-backup-YYYYMMDD.tar.gz

# Subir containers
docker-compose up -d
```

## 🔍 Troubleshooting

### Watchtower não atualiza

**Problema**: "client version 1.25 is too old"

**Solução**:
```bash
docker-compose pull watchtower
docker-compose up -d watchtower
```

### n8n não inicia

```bash
# Ver logs detalhados
docker-compose logs -f n8n

# Verificar permissões
ls -la n8n-data/
sudo chown -R 1000:1000 n8n-data/

# Restart
docker-compose restart n8n
```

### Nginx Proxy Manager não acessa porta 81

```bash
# Verificar se porta está aberta
sudo netstat -tulpn | grep 81

# Verificar firewall
sudo ufw status

# Verificar Oracle Cloud Security List
# No console web: VCN → Security Lists → Ingress Rules
```

### RustDesk não conecta

```bash
# Verificar se portas estão abertas
sudo ss -tulpn | grep 211

# Portas necessárias: 21115-21119
# Liberar no UFW:
sudo ufw allow 21115:21119/tcp

# Verificar logs
docker logs hbbs
docker logs hbbr

# Ver a chave pública
cat rustdesk/id_ed25519.pub
```

## 📊 Monitoramento

### Ver uso de recursos

```bash
# CPU e memória de todos os containers
docker stats

# Apenas containers ativos
docker stats $(docker ps --format={{.Names}})

# Disco usado
du -sh ~/docker/*
```

### Logs centralizados

```bash
# Ver todos os logs
docker-compose logs --tail=100 -f

# Apenas erros
docker-compose logs --tail=100 -f | grep -i error

# Serviço específico
docker-compose logs --tail=50 -f n8n
```

## 🔐 Segurança

### Boas Práticas

1. **Nunca exponha portas desnecessariamente**
   - n8n: `127.0.0.1:5678:5678` (apenas localhost)
   - Use Nginx Proxy Manager para expor com SSL

2. **Use secrets em vez de variáveis de ambiente**
   ```yaml
   secrets:
     n8n_encryption_key:
       file: ./secrets/n8n_encryption_key.txt
   ```

3. **Limite recursos**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '1.0'
         memory: 1G
       reservations:
         cpus: '0.5'
         memory: 512M
   ```

4. **Backups automáticos**
   - Configure cronjob para backups diários
   - Mantenha múltiplas cópias (local + nuvem)

### Firewall Oracle Cloud

No console Oracle Cloud, libere apenas as portas necessárias:

```
Porta 22    (SSH)
Porta 80    (HTTP)
Porta 443   (HTTPS)
Porta 81    (NPM Admin) - Opcional, considere VPN
Portas 21115-21119 (RustDesk) - Se usar
```

## 📁 Alternativa: Docker Compose por Serviço

Se preferir, pode ter um `docker-compose.yml` para cada serviço:

```
~/docker/
├── npm/
│   └── docker-compose.yml
├── n8n/
│   └── docker-compose.yml
├── rustdesk/
│   └── docker-compose.yml
└── watchtower/
    └── docker-compose.yml
```

Então gerencia com:

```bash
cd ~/docker/n8n && docker-compose up -d
cd ~/docker/npm && docker-compose up -d
```

## 🎯 Próximos Passos

1. Configurar domínios no Nginx Proxy Manager
2. Gerar certificados SSL via Let's Encrypt
3. Configurar backups automáticos
4. Configurar alertas do Watchtower
5. Otimizar recursos baseado no uso real
