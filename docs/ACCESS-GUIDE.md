# Guia de Acesso Rápido

Referência rápida para acessar o servidor e serviços.

> **📝 Nota**: Este é um guia template. Substitua os valores de exemplo pelos seus próprios (IP, domínios, caminhos de chaves).

## 🔑 Informações do Servidor

```
IP: SEU_IP_AQUI (ex: 123.456.78.90)
Usuário: ubuntu
Região: Brazil Southeast (Vinhedo) - sa-vinhedo-1
```

## 🖥️ Acesso SSH

### Setup Inicial em Novo Computador

```bash
# 1. Criar diretório .ssh
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 2. Baixar/copiar suas chaves SSH
# Opção A: Baixar do seu backup (Google Drive, Dropbox, etc)
# Opção B: Copiar de pendrive/HD externo
# Opção C: Gerar novas chaves (veja SSH-SECURITY.md)

# 3. Mover chaves para ~/.ssh/
mv ~/Downloads/sua-chave.key ~/.ssh/
mv ~/Downloads/sua-chave.key.pub ~/.ssh/

# 4. Ajustar permissões
chmod 600 ~/.ssh/sua-chave.key
chmod 644 ~/.ssh/sua-chave.key.pub

# 5. Adicionar ao SSH Agent
ssh-add ~/.ssh/sua-chave.key

# 6. Testar conexão
ssh -i ~/.ssh/sua-chave.key ubuntu@SEU_IP
```

**💡 Dica**: Mantenha backup das suas chaves SSH em local seguro (Google Drive privado, gerenciador de senhas, etc).

### Conexão Rápida

```bash
# Conexão SSH normal
ssh -i ~/.ssh/sua-chave.key ubuntu@SEU_IP

# Com tunnel para Nginx Proxy Manager (porta 81)
ssh -L 8181:localhost:81 ubuntu@SEU_IP -i ~/.ssh/sua-chave.key
```

### Configuração Permanente (~/.ssh/config)

Crie/edite `~/.ssh/config`:

```bash
# Conexão normal
Host oracle
    HostName SEU_IP
    User ubuntu
    IdentityFile ~/.ssh/sua-chave.key
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Conexão com tunnel NPM
Host oracle-npm
    HostName SEU_IP
    User ubuntu
    IdentityFile ~/.ssh/sua-chave.key
    LocalForward 8181 localhost:81
    ServerAliveInterval 60

# Conexão com tunnel n8n direto
Host oracle-n8n
    HostName SEU_IP
    User ubuntu
    IdentityFile ~/.ssh/sua-chave.key
    LocalForward 5678 localhost:5678
    ServerAliveInterval 60
```

Depois conecta simplesmente:

```bash
ssh oracle              # Conexão normal
ssh oracle-npm          # Com tunnel NPM (acesse http://localhost:8181)
ssh oracle-n8n          # Com tunnel n8n (acesse http://localhost:5678)
```

## 🌐 Acessando Serviços

### n8n

**URL Pública**: https://n8n.seudominio.com.br (configure seu domínio)

**Configuração**:
- Domínio gerenciado pelo seu provedor DNS
- Proxy reverso via Nginx Proxy Manager
- SSL via Let's Encrypt (automático)

### Nginx Proxy Manager

**Acesso via SSH Tunnel** (recomendado para segurança):

```bash
# 1. Criar tunnel
ssh -L 8181:localhost:81 ubuntu@SEU_IP -i ~/.ssh/sua-chave.key

# 2. Acessar no navegador
http://localhost:8181

# Credenciais padrão (TROQUE IMEDIATAMENTE!):
# Email: admin@example.com
# Senha: changeme
```

**Nota**: A porta 81 NÃO deve estar exposta publicamente por segurança!

### RustDesk (Acesso Remoto)

**Servidor**: SEU_IP (ou seu domínio)
**Portas**: 21115-21119

**Configuração no Cliente RustDesk**:
1. Baixar cliente: https://rustdesk.com/
2. Settings → Network → ID Server
3. Configurar:
   - ID Server: `SEU_IP` (ou seu domínio)
   - Relay Server: `SEU_IP` (ou seu domínio)
   - Key: (consultar `~/rustdesk/id_ed25519.pub` no servidor)

**Obter Key**:
```bash
ssh oracle
cat ~/rustdesk/id_ed25519.pub
```

## 📊 Portas em Uso

| Porta | Serviço | Acesso |
|-------|---------|--------|
| 22 | SSH | ssh oracle |
| 80 | HTTP (NPM) | http://SEU_IP |
| 81 | NPM Admin | Via tunnel: http://localhost:8181 |
| 443 | HTTPS (NPM) | https://seudominio.com |
| 5678 | n8n | Via NPM ou tunnel |
| 21115-21119 | RustDesk | Cliente RustDesk |

## 🔒 Segurança - Checklist Rápido

```bash
# Ver serviços rodando
docker ps

# Ver uso de recursos
htop

# Ver logs recentes
sudo journalctl -n 50

# Ver tentativas de login SSH
sudo tail -f /var/log/auth.log

# Ver status do firewall
sudo ufw status

# Ver IPs banidos pelo Fail2Ban
sudo fail2ban-client status sshd
```

## 💾 Backup Rápido

```bash
# Conectar ao servidor
ssh oracle

# Backup manual do n8n
~/scripts/daily_backup.sh

# Backup de workflows via API
~/scripts/workflow_backup.sh

# Ver últimos backups
rclone ls gdrive:Backups/ServidorOracle/
```

## 🆘 Comandos de Emergência

### Servidor não responde

```bash
# 1. Verificar no Oracle Console se VM está running
# Console → Compute → Instances

# 2. Se VM está stopped: Start
# Se VM está running mas SSH não conecta: Reboot
```

### Container parou

```bash
# Ver todos os containers
docker ps -a

# Restart container específico
docker restart nome-container

# Ver logs do container
docker logs nome-container --tail 50

# Restart toda a stack
cd ~/docker
docker-compose restart
```

### CPU Keep-Alive parou

```bash
# Ver status
sudo systemctl status cpu-keepalive

# Restart
sudo systemctl restart cpu-keepalive

# Ver uso de CPU atual
htop
```

### Disk full

```bash
# Ver uso
df -h

# Limpar Docker
docker system prune -a

# Ver maiores diretórios
du -sh /* | sort -h

# Limpar logs antigos
sudo journalctl --vacuum-time=7d
```

## 📱 Apps Recomendados

### Desktop

- **SSH Client**: Terminal nativo, [Termius](https://termius.com/) (multi-plataforma)
- **SFTP**: [FileZilla](https://filezilla-project.org/)
- **Docker Management**: [Portainer](https://www.portainer.io/) (pode instalar no servidor)

### Mobile

- **SSH**: Termius, JuiceSSH (Android), Blink Shell (iOS)
- **RustDesk**: App oficial

## 🔗 Links Úteis

### Serviços
- Oracle Cloud Console: https://cloud.oracle.com/
- n8n: https://n8n.seudominio.com (configure seu domínio)
- Slack Workspace: (configure seu workspace)

### Documentação
- [FAQ](FAQ.md) - Perguntas frequentes
- [SSH Security](SSH-SECURITY.md) - Guia completo de SSH
- [Services](SERVICES.md) - Todos os serviços rodando
- [Troubleshooting](TROUBLESHOOTING.md) - Resolução de problemas

### Backups
- Mantenha suas chaves SSH em local seguro (Google Drive privado, gerenciador de senhas, etc)
- Configure backups automáticos com rclone (veja scripts/n8n/)

## 📝 Aliases Úteis (Opcional)

Adicione ao `~/.bashrc` ou `~/.zshrc`:

```bash
# SSH
alias oracle='ssh -i ~/.ssh/sua-chave.key ubuntu@SEU_IP'
alias oracle-npm='ssh -L 8181:localhost:81 ubuntu@SEU_IP -i ~/.ssh/sua-chave.key'
alias oracle-n8n='ssh -L 5678:localhost:5678 ubuntu@SEU_IP -i ~/.ssh/sua-chave.key'

# Docker (use após conectar via SSH)
alias dps='docker ps'
alias dlog='docker logs -f'
alias dstats='docker stats'
alias dclean='docker system prune -a'

# Monitoramento
alias oracle-status='ssh oracle "docker ps && df -h && free -h"'
```

Depois: `source ~/.bashrc` e use:

```bash
oracle          # Conecta ao servidor
oracle-npm      # Conecta com tunnel NPM
oracle-status   # Ver status rápido
```

## 🎯 Workflow Diário

### Manhã - Check de Status

```bash
# 1. Verificar se servidor está up
ping SEU_IP

# 2. Ver se containers estão rodando
ssh oracle "docker ps"

# 3. Checar uso de recursos
ssh oracle "htop" # Press q to quit
```

### Trabalho - Acessar n8n

```bash
# Opção 1: Via domínio público
# Abrir: https://n8n.seudominio.com

# Opção 2: Via tunnel (se quiser acesso direto)
ssh oracle-n8n
# Abrir: http://localhost:5678
```

### Manutenção - Ajustar Nginx Proxy Manager

```bash
# 1. Criar tunnel
ssh oracle-npm

# 2. Acessar: http://localhost:8181

# 3. Fazer mudanças necessárias

# 4. Testar: https://n8n.seudominio.com
```

---

**💡 Dica**: Imprima esta página ou salve como favorito para referência rápida!
