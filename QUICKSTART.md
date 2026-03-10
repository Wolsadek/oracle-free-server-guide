# Quick Start - Começando em 10 Minutos

Guia rápido para colocar o servidor Oracle Cloud Always Free funcionando rapidamente.

## 🚀 Setup Inicial (5 minutos)

### 1. Conectar ao servidor

```bash
ssh ubuntu@SEU_IP_ORACLE
```

### 2. Clone o repositório

```bash
git clone https://github.com/seu-usuario/oracle-free-server-guide.git
cd oracle-free-server-guide
```

### 3. Execute o script de setup

```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

O script vai instalar:
- ✅ Python, pipx, stress-ng
- ✅ Oracle CLI
- ✅ Diretórios necessários
- ✅ Scripts de monitoramento
- ✅ CPU Keep-Alive service

## ⚙️ Configuração Rápida (5 minutos)

### 1. Configure a Oracle CLI

```bash
oci iam region list
```

Siga o wizard:
- **Config file?** yes
- **Browser?** no  
- **User OCID**: Console → Profile → User Settings (copia o OCID)
- **Tenancy OCID**: Console → Profile → Tenancy (copia o OCID)
- **Region**: Escolha Vinhedo (60)
- **Generate key?** yes
- **Passphrase**: Escolha uma senha

Adicione a chave pública no Oracle Console:
```bash
cat ~/.oci/oci_api_key_public.pem
```
Console → Profile → User Settings → API Keys → Add API Key → Cole a chave

### 2. Configure Slack Webhook (opcional mas recomendado)

1. Acesse https://api.slack.com/apps
2. Create New App → From scratch
3. Incoming Webhooks → Activate → Add New Webhook
4. Copie a URL do webhook

Edite os scripts:
```bash
nano /opt/oci_scripts/monitoring/cpu_monitor.sh
# Substitua: WEBHOOK_URL="sua_url_aqui"
# Substitua: COMPARTMENT_ID="seu_tenancy_ocid"

# Repita para os outros scripts
nano /opt/oci_scripts/monitoring/storage_monitor.sh
nano /opt/oci_scripts/monitoring/bandwidth_monitor.sh
```

### 3. Ative o CPU Keep-Alive

```bash
sudo systemctl enable cpu-keepalive
sudo systemctl start cpu-keepalive
sudo systemctl status cpu-keepalive
```

### 4. Configure Crontab

```bash
crontab -e
```

Cole estas linhas:

```cron
# Monitoramento Oracle Cloud
0 */6 * * * /opt/oci_scripts/monitoring/cpu_monitor.sh >> /var/log/oci/cpu_monitor_cron.log 2>&1
0 9 * * * /opt/oci_scripts/monitoring/storage_monitor.sh >> /var/log/oci/storage_monitor_cron.log 2>&1
0 */12 * * * /opt/oci_scripts/monitoring/bandwidth_monitor.sh >> /var/log/oci/bandwidth_monitor_cron.log 2>&1
```

## ✅ Verificação

```bash
# 1. CPU Keep-Alive rodando?
sudo systemctl status cpu-keepalive

# 2. Scripts no lugar?
ls -la /opt/oci_scripts/monitoring/

# 3. Crontab configurado?
crontab -l

# 4. Oracle CLI funciona?
source /opt/oracle-cli-venv/bin/activate
oci iam region list
```

## 🎉 Pronto!

Seu servidor agora tem:
- ✅ Monitoramento de CPU, Storage e Bandwidth
- ✅ Alertas no Slack quando algo anormal acontece
- ✅ CPU sempre acima de 20% (evita reclamação)
- ✅ Updates de segurança automáticos

## 📚 Próximos Passos (Opcional)

### Setup Docker Stack

```bash
# Instalar Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Logout e login novamente

# Criar estrutura
mkdir -p ~/docker/{npm-data,n8n-data,rustdesk}
cd ~/docker
```

Copie os exemplos de `docs/DOCKER-COMPOSE-EXAMPLES.md` e ajuste conforme necessário.

### Configurar MOTD Customizado

```bash
# Instalar neofetch
sudo apt install neofetch -y

# Copiar script de MOTD
sudo cp /caminho/para/05-custom-welcome /etc/update-motd.d/
sudo chmod +x /etc/update-motd.d/05-custom-welcome

# Testar
sudo /etc/update-motd.d/05-custom-welcome
```

### Configurar Backups do n8n

Se você instalou n8n:

```bash
# Instalar rclone
curl https://rclone.org/install.sh | sudo bash

# Configurar Google Drive
rclone config

# Copiar scripts de backup
cp scripts/n8n/*.sh ~/scripts/
chmod +x ~/scripts/*.sh

# Testar
~/scripts/daily_backup.sh
```

## 🆘 Problemas?

**Não funciona?** Veja [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

**Dúvidas?** Leia a [documentação completa](README.md)

**Bug?** Abra uma [issue](https://github.com/seu-usuario/oracle-free-server-guide/issues)

## 📖 Documentação Completa

- [README.md](README.md) - Documentação principal
- [docs/SERVICES.md](docs/SERVICES.md) - Serviços Docker
- [docs/DOCKER-COMPOSE-EXAMPLES.md](docs/DOCKER-COMPOSE-EXAMPLES.md) - Stack Docker
- [docs/MOTD.md](docs/MOTD.md) - Banner customizado
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Resolução de problemas

---

**💡 Dica**: Documente suas customizações! Isso vai te salvar no futuro 😉
