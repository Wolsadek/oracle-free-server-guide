# Oracle Free Server Guide

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Bash](https://img.shields.io/badge/bash-5.0+-green.svg)
![Oracle Cloud](https://img.shields.io/badge/oracle_cloud-always_free-red.svg)
![Docker](https://img.shields.io/badge/docker-compose-blue.svg)
![Monitoring](https://img.shields.io/badge/monitoring-slack-purple.svg)

Guia completo para configurar e monitorar um servidor gratuito da Oracle Cloud Always Free Tier, incluindo scripts de monitoramento de CPU, storage e bandwidth com alertas no Slack.

## ⚡ Quick Start

**Quer começar rápido?** Veja o [QUICKSTART.md](QUICKSTART.md) para setup em 10 minutos!

## 📑 Índice

- [Recursos](#-recursos)
- [Oracle Always Free Tier - Limites](#-oracle-always-free-tier---limites)
- [Dicas Importantes](#️-dicas-importantes)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação](#-instalação)
  - [Opção A: Instalação Automática](#opção-a-instalação-automática-recomendada)
  - [Opção B: Instalação Manual](#opção-b-instalação-manual)
- [Scripts de Monitoramento](#-scripts-de-monitoramento)
- [Logs](#-logs)
- [Backups do n8n](#-backups-do-n8n-opcional)
- [Troubleshooting](#-troubleshooting)
- [Documentação Adicional](#-documentação-adicional)
- [Notas Importantes](#-notas-importantes)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Contribuições](#-contribuições)
- [Licença](#-licença)

## 📚 Recursos

### Vídeos Tutoriais
- [Tutorial Principal](https://www.youtube.com/watch?v=1XSsxMhnGTs&t=2s)
- [Tutorial Complementar](https://www.youtube.com/watch?v=SsK4YIIR69w)

## 🎯 Oracle Always Free Tier - Limites

- **Compute**: 2 VMs com processador Ampere A1 (até 4 OCPUs e 24GB RAM no total)
- **Block Storage**: 200 GB total
- **Object Storage**: 20 GB
- **Archive Storage**: 10 GB
- **Bandwidth**: 10 TB de saída por mês
- **CPU Usage**: Deve manter acima de 20% para evitar reclamação da instância

## ⚠️ Dicas Importantes

### Região
Ao criar a conta, escolha a região **Brazil Southeast (Vinhedo)** - `sa-vinhedo-1`:
- Menor latência
- Infraestrutura mais atual
- Melhor disponibilidade de instâncias comparado a São Paulo East

## 📋 Pré-requisitos

- Conta Oracle Cloud criada
- Servidor Ubuntu provisionado na Oracle Cloud
- Acesso SSH ao servidor
- Slack Webhook URL (para alertas)

## 🚀 Instalação

### Opção A: Instalação Automática (Recomendada)

Clone o repositório e execute o script de setup:

```bash
# Clonar o repositório
git clone https://github.com/seu-usuario/oracle-free-server-guide.git
cd oracle-free-server-guide

# Executar script de setup
chmod +x scripts/setup.sh
./scripts/setup.sh
```

O script vai instalar todas as dependências e configurar os diretórios necessários. Depois, siga as instruções exibidas no final do script.

### Opção B: Instalação Manual

Se preferir fazer o setup manualmente, siga os passos abaixo:

#### 1. Dependências Básicas

```bash
sudo apt update
sudo apt install -y python3-pip python3-venv python3-dev python3-full stress-ng
sudo apt install -y pipx
```

### 2. Instalação da Oracle CLI

Crie um ambiente virtual Python para a Oracle CLI:

```bash
# Criar ambiente virtual
python3 -m venv /opt/oracle-cli-venv

# Ativar o ambiente
source /opt/oracle-cli-venv/bin/activate

# Instalar OCI CLI via pipx
pipx install oci-cli
pipx ensurepath
```

### 3. Configuração da Oracle CLI

Execute qualquer comando OCI para iniciar a configuração (exemplo: `oci iam region list`):

```bash
oci iam region list
```

Responda as perguntas da seguinte forma:

```
Create config file? yes
Through browser? no
Location: /home/ubuntu/.oci/config (ou /root/.oci/config se for root)
```

#### Obtendo as Credenciais

**User OCID**:
1. Acesse Oracle Console
2. Clique no ícone de perfil (canto superior direito)
3. Vá em **User Settings**
4. Copie o OCID (começa com `ocid1.user.oc1...`)

**Tenancy OCID**:
1. Acesse Oracle Console
2. Clique no ícone de perfil
3. Vá em **Tenancy**
4. Copie o OCID (começa com `ocid1.tenancy.oc1...`)

**Region**:
- Digite o número correspondente à sua região (ex: `60` para `sa-vinhedo-1`)

#### Gerando a API Key

```
Generate new API signing RSA key pair? yes
Choose directory: /home/ubuntu/.oci (ou /root/.oci)
Enter name for the key: oci_api_key (padrão)
Choose passphrase: [sua senha]
Write passphrase to file? yes
```

#### Adicionando a Public Key no Console Oracle

```bash
cat /home/ubuntu/.oci/oci_api_key_public.pem
```

Copie o conteúdo e:
1. Acesse Oracle Console
2. Profile icon → **User Settings**
3. **Tokens and Keys**
4. Clique em **Add API Key**
5. Selecione **Paste Public Key**
6. Cole a chave pública
7. Clique em **Add**

### 4. Setup do CPU Keep-Alive

Para evitar que a Oracle reclame a instância por baixo uso de CPU:

```bash
# Instalar stress-ng
sudo apt install stress-ng -y

# Copiar o arquivo de serviço
sudo cp scripts/systemd/cpu-keepalive.service /etc/systemd/system/

# Habilitar e iniciar o serviço
sudo systemctl daemon-reload
sudo systemctl enable cpu-keepalive
sudo systemctl start cpu-keepalive

# Verificar status
sudo systemctl status cpu-keepalive
```

Este serviço mantém a CPU com ~25% de uso constante usando 4 cores.

### 5. Setup dos Scripts de Monitoramento

#### Criar diretórios

```bash
sudo mkdir -p /opt/oci_scripts/monitoring
sudo mkdir -p /var/log/oci
sudo chown ubuntu:ubuntu /opt/oci_scripts/monitoring
sudo chown ubuntu:ubuntu /var/log/oci
```

#### Copiar scripts

```bash
# Copiar scripts para o servidor
sudo cp scripts/cpu_monitor.sh /opt/oci_scripts/monitoring/
sudo cp scripts/storage_monitor.sh /opt/oci_scripts/monitoring/
sudo cp scripts/bandwidth_monitor.sh /opt/oci_scripts/monitoring/

# Dar permissões de execução
sudo chmod +x /opt/oci_scripts/monitoring/*.sh
```

#### Configurar Webhooks e Compartment ID

Edite cada script e substitua:

```bash
# Seu Slack Webhook URL
WEBHOOK_URL="https://hooks.slack.com/services/YOUR_WEBHOOK_URL_HERE"

# Seu Compartment ID (Tenancy OCID)
COMPARTMENT_ID="ocid1.tenancy.oc1..aaaaaaaa..."
```

Para encontrar seu Compartment ID:
1. Oracle Console → Profile → Tenancy
2. Copie o OCID da Tenancy (este é seu Compartment ID raiz)

#### Criar Webhook no Slack

1. Acesse https://api.slack.com/apps
2. Crie um novo app
3. Ative **Incoming Webhooks**
4. Crie um novo webhook para o canal desejado
5. Copie a URL do webhook

### 6. Configurar Crontab

Adicione os scripts ao crontab para execução automática:

```bash
crontab -e
```

Adicione as seguintes linhas:

```cron
# Monitoramento de CPU - a cada 6 horas
0 */6 * * * /opt/oci_scripts/monitoring/cpu_monitor.sh >> /var/log/oci/cpu_monitor_cron.log 2>&1

# Monitoramento de Storage - diariamente às 9h
0 9 * * * /opt/oci_scripts/monitoring/storage_monitor.sh >> /var/log/oci/storage_monitor_cron.log 2>&1

# Monitoramento de Bandwidth - a cada 12 horas
0 */12 * * * /opt/oci_scripts/monitoring/bandwidth_monitor.sh >> /var/log/oci/bandwidth_monitor_cron.log 2>&1
```

## 📊 Scripts de Monitoramento

### CPU Monitor (`cpu_monitor.sh`)

**Função**: Monitora o uso de CPU para evitar reclamação da instância pela Oracle.

**Thresholds**:
- **Warning**: Abaixo de 25%
- **Critical**: Abaixo de 20% (risco de reclamação após 7 dias)

**Alertas enviados quando**:
- CPU cai abaixo de 25% (warning)
- CPU cai abaixo de 20% (critical - risco de perder a instância)

### Storage Monitor (`storage_monitor.sh`)

**Função**: Monitora uso de armazenamento (block storage e object storage).

**Limites Always Free**:
- Block Storage: 200 GB
- Object Storage: 20 GB

**Alertas**: Enviados em 70%, 80%, 85%, 90% e 95% de uso.

### Bandwidth Monitor (`bandwidth_monitor.sh`)

**Função**: Monitora uso de bandwidth mensal.

**Limite Always Free**: 10 TB/mês de saída

**Alertas**: 
- A cada 1% de uso
- Alertas especiais em 80%, 90% e 95%
- Reseta automaticamente no início de cada mês

## 🔍 Logs

Todos os scripts geram logs em `/var/log/oci/`:

```bash
# Ver logs de CPU
tail -f /var/log/oci/cpu_monitor.log

# Ver logs de Storage
tail -f /var/log/oci/storage_monitor.log

# Ver logs de Bandwidth
tail -f /var/log/oci/bandwidth_monitor.log

# Ver logs do cron
tail -f /var/log/oci/*_cron.log
```

## 💾 Backups do n8n (Opcional)

Se você estiver rodando n8n no seu servidor Oracle, esses scripts ajudam a fazer backup automático dos seus workflows e dados para o Google Drive usando rclone.

### Por que fazer backup?

- n8n armazena todos os workflows e credenciais localmente
- Se perder a instância, perde tudo
- Backup externo garante recuperação em caso de problemas

### Pré-requisitos

```bash
# Instalar rclone
curl https://rclone.org/install.sh | sudo bash

# Instalar jq (para processar JSON)
sudo apt install jq -y
```

### Configurar rclone com Google Drive

```bash
# Iniciar configuração
rclone config

# Seguir os passos:
# n) New remote
# name> gdrive
# Storage> google drive (geralmente opção 15 ou 18)
# client_id> (deixe em branco)
# client_secret> (deixe em branco)
# scope> 1 (Full access)
# root_folder_id> (deixe em branco)
# service_account_file> (deixe em branco)
# Use auto config? n (porque estamos em um servidor sem interface)
```

O rclone vai gerar uma URL. Copie e abra em um navegador no seu computador local, faça login com sua conta Google e autorize o acesso. Depois cole o código de autorização de volta no terminal.

```bash
# Continuar:
# Configure this as a team drive? n
# Yes this is OK> y
# q) Quit config
```

### Testar a configuração

```bash
# Listar arquivos no Google Drive
rclone ls gdrive:

# Criar pasta de teste
rclone mkdir gdrive:TestBackup
```

### Setup dos Scripts de Backup

#### 1. Copiar scripts

```bash
# Copiar scripts para o diretório home
cp scripts/n8n/daily_backup.sh ~/scripts/
cp scripts/n8n/workflow_backup.sh ~/scripts/

# Dar permissões de execução
chmod +x ~/scripts/daily_backup.sh
chmod +x ~/scripts/workflow_backup.sh
```

#### 2. Configurar API Key do n8n

Para o script `workflow_backup.sh`, você precisa gerar uma API key no n8n:

1. Acesse seu n8n (ex: `http://seu-ip:5678`)
2. Vá em **Settings** → **API**
3. Clique em **Create API Key**
4. Copie a chave gerada
5. Edite o script e cole a chave:

```bash
nano ~/scripts/workflow_backup.sh

# Substitua:
API_KEY="YOUR_N8N_API_KEY_HERE"
# Por:
API_KEY="sua_chave_aqui"
```

#### 3. Testar os scripts manualmente

```bash
# Testar backup dos dados do n8n
~/scripts/daily_backup.sh

# Testar backup dos workflows via API
~/scripts/workflow_backup.sh

# Verificar se os backups apareceram no Google Drive
rclone ls gdrive:Backups/ServidorOracle/
```

#### 4. Automatizar com Crontab

```bash
crontab -e
```

Adicione as linhas:

```cron
# Backup diário dos dados do n8n - às 3h da manhã
0 3 * * * /home/ubuntu/scripts/daily_backup.sh >> /home/ubuntu/backup_cron.log 2>&1

# Backup dos workflows do n8n - a cada 6 horas
0 */6 * * * /home/ubuntu/scripts/workflow_backup.sh >> /home/ubuntu/workflows_cron.log 2>&1
```

### Diferença entre os dois scripts

**`daily_backup.sh`**:
- Faz backup completo da pasta `/home/ubuntu/n8n-data`
- Inclui: banco de dados SQLite, credenciais, configurações, etc.
- Mais pesado, mas backup completo

**`workflow_backup.sh`**:
- Exporta cada workflow individualmente em JSON via API
- Mais leve e rápido
- Ideal para versionamento de workflows
- Não inclui credenciais (por segurança)

### Verificar logs dos backups

```bash
# Ver log do backup diário
tail -f ~/rclone_n8n_backup.log

# Ver log do backup de workflows
tail -f ~/rclone_workflows_backup.log

# Ver logs do cron
tail -f ~/backup_cron.log
tail -f ~/workflows_cron.log
```

### Restaurar backup

#### Restaurar dados completos

```bash
# Parar o n8n primeiro
docker stop n8n  # ou sudo systemctl stop n8n

# Baixar backup do Google Drive
rclone sync gdrive:Backups/ServidorOracle/n8n /home/ubuntu/n8n-data-restore

# Mover para pasta do n8n
rm -rf /home/ubuntu/n8n-data/*
cp -r /home/ubuntu/n8n-data-restore/* /home/ubuntu/n8n-data/

# Reiniciar n8n
docker start n8n  # ou sudo systemctl start n8n
```

#### Restaurar workflow individual

1. Baixe o arquivo JSON do workflow do Google Drive
2. No n8n, vá em **Workflows** → **Import from File**
3. Selecione o arquivo JSON

## 🔧 Troubleshooting

### Oracle CLI não encontrada

Certifique-se de ativar o ambiente virtual antes de usar a CLI:

```bash
source /opt/oracle-cli-venv/bin/activate
oci --version
```

### Permissões negadas

```bash
# Ajustar proprietário dos diretórios
sudo chown -R ubuntu:ubuntu /opt/oci_scripts
sudo chown -R ubuntu:ubuntu /var/log/oci

# Ajustar permissões dos scripts
sudo chmod +x /opt/oci_scripts/monitoring/*.sh
```

### Scripts não enviam alertas

Verifique:
1. Se o WEBHOOK_URL está correto
2. Se o COMPARTMENT_ID está correto
3. Se há conectividade com o Slack: `curl -X POST $WEBHOOK_URL`
4. Os logs em `/var/log/oci/` para erros

### CPU Keep-Alive não está funcionando

```bash
# Verificar status do serviço
sudo systemctl status cpu-keepalive

# Ver logs do serviço
sudo journalctl -u cpu-keepalive -f

# Reiniciar serviço
sudo systemctl restart cpu-keepalive
```

## 📚 Documentação Adicional

Documentação detalhada disponível em `/docs`:

### 🐳 [Serviços e Aplicações](docs/SERVICES.md)
Documentação completa dos serviços rodando no servidor:
- **Nginx Proxy Manager** - Proxy reverso e SSL
- **n8n** - Automação de workflows
- **RustDesk** - Servidor de acesso remoto próprio
- **Watchtower** - Auto-update de containers
- Configurações, portas, e troubleshooting específico

### 🐋 [Docker Compose Examples](docs/DOCKER-COMPOSE-EXAMPLES.md)
Stack completa e organizada de containers:
- `docker-compose.yml` unificado
- Variáveis de ambiente
- Comandos úteis
- Backups e restauração
- Boas práticas de segurança

### 🎨 [MOTD Customizado](docs/MOTD.md)
Banner personalizado ao fazer SSH:
- Neofetch com informações do sistema
- Status dos containers Docker
- Últimos logins
- Customizações avançadas com cores

### 🔧 [Troubleshooting Completo](docs/TROUBLESHOOTING.md)
Soluções para problemas comuns:
- Watchtower (client version too old)
- Nginx Proxy Manager
- n8n
- RustDesk
- Docker
- Oracle CLI
- Scripts de diagnóstico

### 🔑 [SSH Security](docs/SSH-SECURITY.md)
Configuração completa de SSH:
- Gerenciamento de chaves SSH
- SSH tunneling (port forwarding)
- Hardening e segurança
- Fail2ban e UFW
- Múltiplas chaves
- Troubleshooting SSH

### ❓ [FAQ](docs/FAQ.md)
Perguntas frequentes:
- Always Free Tier explicado
- Limites e custos
- Segurança e firewall
- Docker e containers
- Backups e disaster recovery
- Rede e domínios

### 📖 [Access Guide](docs/ACCESS-GUIDE.md)
Referência rápida de acesso:
- Setup inicial em novo PC
- Comandos SSH prontos
- Como acessar cada serviço
- Portas e URLs
- Workflow diário
- Comandos de emergência

## 📝 Notas Importantes

1. **Ambiente Virtual**: Sempre ative o ambiente virtual (`source /opt/oracle-cli-venv/bin/activate`) antes de usar comandos `oci` manualmente.

2. **CPU Usage**: O serviço `cpu-keepalive` é CRÍTICO para evitar que a Oracle reclame sua instância. Não desative-o!

3. **Alertas Duplicados**: Os scripts possuem mecanismo anti-spam que evita enviar o mesmo alerta múltiplas vezes no mesmo dia.

4. **Bandwidth**: O limite de 10TB é contado pela saída (outbound) apenas. Entrada é ilimitada.

5. **Custos**: Todos os recursos descritos aqui estão dentro do Always Free Tier. Se exceder os limites, você será cobrado!

## 📁 Estrutura do Projeto

```
oracle-free-server-guide/
├── README.md                          # Este arquivo - documentação principal
├── CONTRIBUTING.md                    # Guia de contribuição
├── CHANGELOG.md                       # Histórico de mudanças
├── LICENSE                            # Licença MIT
├── .gitignore                         # Arquivos ignorados pelo git
└── scripts/
    ├── setup.sh                       # Script de instalação automática
    ├── config.example.sh              # Exemplo de arquivo de configuração
    ├── cpu_monitor.sh                 # Monitor de CPU
    ├── storage_monitor.sh             # Monitor de storage
    ├── bandwidth_monitor.sh           # Monitor de bandwidth
    ├── n8n/
    │   ├── daily_backup.sh            # Backup diário do n8n
    │   └── workflow_backup.sh         # Backup de workflows via API
    └── systemd/
        └── cpu-keepalive.service      # Serviço systemd para manter CPU ativa
```

## 🤝 Contribuições

Contribuições são bem-vindas! Leia [CONTRIBUTING.md](CONTRIBUTING.md) para saber como contribuir.

Algumas formas de contribuir:
- 🐛 Reportar bugs
- 💡 Sugerir novas features
- 📝 Melhorar a documentação
- 🔧 Adicionar novos scripts
- 🌍 Traduzir para outros idiomas

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 🙏 Créditos

Baseado nas dicas e scripts compartilhados pela comunidade Oracle Cloud Always Free Tier.

Agradecimentos especiais aos criadores dos vídeos tutoriais que ajudaram a documentar o processo.

---

**⭐ Se este guia foi útil, considere dar uma estrela no repositório!**
