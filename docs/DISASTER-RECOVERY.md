# 🆘 Disaster Recovery - Plano de Contingência

O que fazer se a Oracle tirar teu servidor ou algo der errado.

## ⚠️ Cenários de Risco

### 1. Oracle reclama instância
- CPU abaixo de 20% por 7+ dias
- **Prevenção**: CPU Keep-Alive (incluído neste guia)

### 2. Oracle muda política Always Free
- Raro, mas pode acontecer
- Podem avisar com antecedência ou não

### 3. Problemas técnicos
- Datacenter offline
- Corrupção de dados
- Hardware failure

### 4. Ban da conta
- Violação de ToS
- Atividade suspeita
- Múltiplas contas

### 5. Você deleta algo sem querer
- `rm -rf` errado
- Terminate instance acidental

## 🛡️ Estratégia de Backup 3-2-1

**Regra 3-2-1**:
- **3** cópias dos dados
- **2** tipos de mídia diferentes
- **1** cópia offsite (fora do servidor)

### Aplicado ao teu servidor:

1. **Original**: No servidor Oracle (running)
2. **Backup 1**: Google Drive (rclone) - já configurado!
3. **Backup 2**: HD externo ou outro cloud

## 💾 Backup Completo do Servidor

### O que deve ser salvo

#### Crítico (SEMPRE):
- ✅ Dados do n8n (`~/n8n-data`)
- ✅ Workflows n8n (via API)
- ✅ Configs do Nginx PM (`~/npm-data`)
- ✅ Chaves SSH (`~/.ssh/`)
- ✅ Oracle CLI config (`~/.oci/`)
- ✅ Docker compose files
- ✅ Scripts customizados
- ✅ Configs de serviços (`/etc/systemd/system/`)

#### Importante:
- ⚠️ RustDesk keys (`~/rustdesk/id_ed25519*`)
- ⚠️ Certificados SSL (`~/letsencrypt/`)
- ⚠️ Logs importantes
- ⚠️ Banco de dados (se tiver)

#### Opcional:
- 📦 Imagens Docker (grandes, pode re-baixar)
- 📦 System packages (reinstala depois)

### Script de Backup Completo

```bash
#!/bin/bash
# Backup completo do servidor Oracle

BACKUP_DIR="$HOME/full-backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

echo "🔄 Iniciando backup completo..."

# n8n
echo "📦 Backup n8n..."
tar -czf "$BACKUP_DIR/n8n-data.tar.gz" ~/n8n-data 2>/dev/null

# Nginx Proxy Manager
echo "📦 Backup NPM..."
tar -czf "$BACKUP_DIR/npm-data.tar.gz" ~/npm-data 2>/dev/null

# RustDesk
echo "📦 Backup RustDesk..."
tar -czf "$BACKUP_DIR/rustdesk.tar.gz" ~/rustdesk 2>/dev/null

# Configs importantes
echo "📦 Backup configs..."
mkdir -p "$BACKUP_DIR/configs"
cp -r ~/.ssh "$BACKUP_DIR/configs/" 2>/dev/null
cp -r ~/.oci "$BACKUP_DIR/configs/" 2>/dev/null
cp ~/.bashrc "$BACKUP_DIR/configs/" 2>/dev/null
cp ~/.msmtprc "$BACKUP_DIR/configs/" 2>/dev/null

# Scripts
echo "📦 Backup scripts..."
tar -czf "$BACKUP_DIR/scripts.tar.gz" ~/scripts 2>/dev/null

# Docker configs
echo "📦 Backup docker..."
mkdir -p "$BACKUP_DIR/docker"
[ -f ~/docker-compose.yml ] && cp ~/docker-compose.yml "$BACKUP_DIR/docker/"
[ -f ~/.env ] && cp ~/.env "$BACKUP_DIR/docker/"

# Systemd services
echo "📦 Backup services..."
mkdir -p "$BACKUP_DIR/systemd"
sudo cp /etc/systemd/system/cpu-keepalive.service "$BACKUP_DIR/systemd/" 2>/dev/null

# Crontab
echo "📦 Backup crontab..."
crontab -l > "$BACKUP_DIR/crontab.txt" 2>/dev/null

# Info do sistema
echo "📦 Info do sistema..."
cat > "$BACKUP_DIR/system-info.txt" << EOF
Backup criado em: $(date)
Hostname: $(hostname)
OS: $(lsb_release -d | cut -f2)
Kernel: $(uname -r)
Docker: $(docker --version 2>/dev/null || echo "N/A")

Containers:
$(docker ps --format "{{.Names}}: {{.Image}}" 2>/dev/null)

IPs:
$(ip -4 addr show | grep inet | grep -v 127.0.0.1)
EOF

# Compactar tudo
echo "🗜️  Compactando backup final..."
cd "$HOME"
tar -czf "full-backup-$(date +%Y%m%d).tar.gz" "full-backup-$(date +%Y%m%d)/"
rm -rf "$BACKUP_DIR"

echo "✅ Backup completo salvo em: $HOME/full-backup-$(date +%Y%m%d).tar.gz"
echo "📤 Enviando para Google Drive..."

# Upload para Google Drive
rclone copy "$HOME/full-backup-$(date +%Y%m%d).tar.gz" gdrive:Backups/ServidorOracle/FullBackup/

echo "🎉 Backup completo finalizado!"
```

Salve como `~/scripts/full_backup.sh` e rode:
```bash
chmod +x ~/scripts/full_backup.sh
./scripts/full_backup.sh
```

### Agendar Backup Mensal

```bash
crontab -e
```

Adicione:
```cron
# Backup completo - todo dia 1 do mês às 3h
0 3 1 * * /home/ubuntu/scripts/full_backup.sh >> /var/log/full_backup.log 2>&1
```

## 🏗️ Plano de Restauração

### Cenário 1: Instância foi reclamada

**Tempo estimado**: 2-4 horas

#### Passo 1: Criar nova instância
```
1. Oracle Console → Compute → Create Instance
2. Shape: VM.Standard.A1.Flex (4 OCPUs, 24GB RAM)
3. Image: Ubuntu 24.04
4. SSH Key: Use a mesma chave ou crie nova
5. Create
```

#### Passo 2: Setup básico
```bash
# SSH na nova instância
ssh ubuntu@NOVO_IP

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar essenciais
sudo apt install -y git docker.io docker-compose curl wget
sudo usermod -aG docker ubuntu
```

#### Passo 3: Restaurar configs
```bash
# Baixar backup do Google Drive
# (assumindo que rclone já configurado ou configure novamente)
rclone copy gdrive:Backups/ServidorOracle/FullBackup/full-backup-YYYYMMDD.tar.gz ~/

# Extrair
tar -xzf full-backup-YYYYMMDD.tar.gz
cd full-backup-YYYYMMDD

# Restaurar configs
cp -r configs/.ssh ~/
chmod 600 ~/.ssh/*
cp -r configs/.oci ~/
cp configs/.bashrc ~/

# Restaurar scripts
tar -xzf scripts.tar.gz -C ~/
```

#### Passo 4: Restaurar serviços
```bash
# n8n
tar -xzf n8n-data.tar.gz -C ~/

# Nginx PM
tar -xzf npm-data.tar.gz -C ~/

# RustDesk
tar -xzf rustdesk.tar.gz -C ~/

# Docker
cp docker/* ~/
```

#### Passo 5: Subir containers
```bash
cd ~
docker-compose up -d
```

#### Passo 6: Restaurar serviços do sistema
```bash
# CPU Keep-Alive
sudo cp systemd/cpu-keepalive.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cpu-keepalive
sudo systemctl start cpu-keepalive

# Crontab
crontab crontab.txt
```

#### Passo 7: Atualizar DNS
```
Seu domínio → Apontamento A → NOVO_IP
Aguardar propagação (5min - 48h)
```

### Cenário 2: Dados corrompidos (servidor ainda existe)

```bash
# 1. Parar serviços
docker-compose down

# 2. Fazer backup do estado atual (por segurança)
mv ~/n8n-data ~/n8n-data.old

# 3. Restaurar do backup
rclone copy gdrive:Backups/ServidorOracle/FullBackup/full-backup-LATEST.tar.gz ~/
tar -xzf full-backup-LATEST.tar.gz
cd full-backup-YYYYMMDD
tar -xzf n8n-data.tar.gz -C ~/

# 4. Subir novamente
docker-compose up -d
```

## 🔄 Alternativas à Oracle

Se Oracle tirar ou quiser diversificar:

### Clouds Alternativas (Free/Baratas)

1. **Google Cloud** (Always Free)
   - E2-micro (0.25 vCPU, 1GB RAM)
   - 30GB storage
   - Menor que Oracle, mas funciona

2. **AWS** (Free 12 meses)
   - t2.micro (1 vCPU, 1GB RAM)
   - 30GB storage
   - Depois: ~$10/mês

3. **Azure** (Free 12 meses)
   - B1S (1 vCPU, 1GB RAM)
   - Depois: ~$13/mês

4. **Hetzner** (Pago, mas barato)
   - €4.15/mês (2 vCPU, 4GB RAM, 40GB)
   - Muito confiável
   - Datacenter Alemanha

5. **DigitalOcean**
   - $4/mês (1 vCPU, 512MB RAM)
   - $6/mês (1 vCPU, 1GB RAM)

6. **Contabo** (Muito barato)
   - €4/mês (4 vCPU, 8GB RAM, 200GB)
   - Alemanha
   - Suporte questionável

### Self-Hosted Local

**Raspberry Pi 4/5**:
- One-time: ~$100
- Custos: só energia (~$2/mês)
- 24/7 em casa
- Precisa IP fixo ou DynDNS

**Mini PC (N100/N5105)**:
- One-time: ~$150-200
- Mais potente que Pi
- Silencioso

## 📋 Checklist Mensal

- [ ] Backup completo rodou? (check logs)
- [ ] Backup está no Google Drive?
- [ ] Download local teste (1x por trimestre)
- [ ] Documentação atualizada?
- [ ] Chaves SSH backup em 2+ lugares?
- [ ] Sabe seu Compartment ID de cor?

## 🆘 Contatos de Emergência

Salve em local seguro:

```
Oracle Tenancy OCID: ocid1.tenancy.oc1...
Oracle User OCID: ocid1.user.oc1...
Oracle Region: sa-vinhedo-1
Google Drive Backup: drive.google.com/...
GitHub Repo: github.com/wolsadek/oracle-free-server-guide

Email Backup Config: estudominucioso@gmail.com
Slack Webhook: hooks.slack.com/services/...
```

## 💡 Dicas Finais

### Minimize Downtime

1. **Mantenha documentação atualizada**
   - Anote toda mudança que fizer
   - Update este guia

2. **Teste restauração**
   - 1x por ano, crie VM nova e teste restaurar
   - Cronometre quanto tempo leva

3. **Múltiplos backups**
   - Google Drive (primary)
   - HD externo (secondary)
   - Outro cloud (tertiary)

4. **Monitoramento externo**
   - UptimeRobot avisando se cair
   - Você age ANTES de perder tudo

5. **Chaves SSH everywhere**
   - Laptop, Desktop, Pendrive
   - Gerenciador de senhas
   - Google Drive (privado!)

### Piores Cenários

**Conta Oracle banida permanentemente**:
- Backups salvam tudo
- 4 horas pra recriar em outro cloud
- Domínios continuam funcionando

**Google Drive deletado**:
- Por isso backup 3-2-1
- HD externo salva

**Tudo perdido (casa pegou fogo)**:
- Backup em cloud (Google Drive)
- Chaves SSH em gerenciador de senhas (cloud)
- Recria tudo em 1 dia

## 📖 Recursos Adicionais

- [Estratégia 3-2-1](https://www.backblaze.com/blog/the-3-2-1-backup-strategy/)
- [Oracle ToS](https://www.oracle.com/cloud/terms/)
- [Migrating between clouds](https://www.cloudamize.com/cloud-migration/)

---

**🎯 Bottom Line**: 

Com backups corretos, você **NUNCA** perde nada. Worst case: 4h de trabalho pra recriar em outro lugar.

**Ação Imediata**: 
1. Rode script de full backup HOJE
2. Baixe 1 cópia local
3. Durma tranquilo 😴
