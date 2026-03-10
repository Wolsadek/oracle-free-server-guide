# SSH - Segurança e Acesso

Guia completo de configuração SSH, chaves, tunneling e boas práticas de segurança.

## 🔑 SSH Keys - Setup Completo

### Gerando Novas Chaves SSH

Se você ainda não tem um par de chaves SSH:

```bash
# No seu computador local (não no servidor!)
ssh-keygen -t ed25519 -C "seu-email@exemplo.com" -f ~/.ssh/oracle-key

# Ou RSA se ed25519 não for suportado
ssh-keygen -t rsa -b 4096 -C "seu-email@exemplo.com" -f ~/.ssh/oracle-key
```

Isso cria dois arquivos:
- `oracle-key` - Chave privada (NUNCA compartilhe!)
- `oracle-key.pub` - Chave pública (pode compartilhar)

### Adicionando Chave Pública ao Servidor

**Opção 1: Durante criação da VM na Oracle Console**
- Cole o conteúdo de `oracle-key.pub` no campo "SSH Key"

**Opção 2: Servidor já existe**
```bash
# No servidor
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Cole sua chave pública
nano ~/.ssh/authorized_keys
# Cole o conteúdo de oracle-key.pub

# Ajustar permissões
chmod 600 ~/.ssh/authorized_keys
```

### Configurando Permissões Corretas

```bash
# Chave privada - DEVE ser 600
chmod 600 ~/.ssh/oracle-key

# Chave pública - pode ser 644
chmod 644 ~/.ssh/oracle-key.pub

# Diretório .ssh - DEVE ser 700
chmod 700 ~/.ssh
```

**Importante**: SSH recusa chaves com permissões muito abertas por segurança!

## 🖥️ Conectando ao Servidor

### Conexão Básica

```bash
ssh -i ~/.ssh/oracle-key ubuntu@SEU_IP
```

### Adicionando Chave ao SSH Agent

Para não precisar especificar `-i` toda vez:

```bash
# Iniciar ssh-agent
eval "$(ssh-agent -s)"

# Adicionar sua chave
ssh-add ~/.ssh/oracle-key

# Verificar chaves carregadas
ssh-add -l

# Agora conecta sem -i
ssh ubuntu@SEU_IP
```

### Configuração SSH Permanente

Crie/edite `~/.ssh/config`:

```bash
nano ~/.ssh/config
```

Adicione:

```
Host oracle
    HostName SEU_IP
    User ubuntu
    IdentityFile ~/.ssh/oracle-key
    ServerAliveInterval 60
    ServerAliveCountMax 3

Host oracle-n8n-tunnel
    HostName SEU_IP
    User ubuntu
    IdentityFile ~/.ssh/oracle-key
    LocalForward 8181 localhost:81
```

Agora conecta simplesmente com:

```bash
# Conexão normal
ssh oracle

# Conexão com tunnel
ssh oracle-n8n-tunnel
```

## 🔐 Hardening - Segurança Avançada

### 1. Desabilitar Autenticação por Senha

**⚠️ IMPORTANTE**: Só faça isso depois de testar que consegue logar via chave SSH!

```bash
# No servidor
sudo nano /etc/ssh/sshd_config
```

Encontre e modifique:

```
# Desabilitar senha
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no

# Desabilitar root login
PermitRootLogin no

# Apenas chave SSH
PubkeyAuthentication yes
```

Restart SSH:

```bash
sudo systemctl restart sshd

# TESTE em outra janela antes de desconectar!
ssh oracle
```

### 2. Instalar e Configurar Fail2Ban

Protege contra brute force:

```bash
sudo apt install fail2ban -y

# Criar config local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

Configure:

```ini
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
destemail = seu-email@exemplo.com
sendername = Fail2Ban-Oracle

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 3
```

Ativar:

```bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Ver status
sudo fail2ban-client status sshd
```

### 3. Trocar Porta SSH (Opcional)

Reduz tentativas de bots:

```bash
sudo nano /etc/ssh/sshd_config
```

Mudar:

```
Port 2222  # ou qualquer porta > 1024
```

**IMPORTANTE**: Antes de reiniciar SSH:

1. **Oracle Cloud Security List**: Adicionar ingress rule para nova porta
2. **UFW**: `sudo ufw allow 2222/tcp`
3. Manter sessão SSH aberta e testar em outra janela

```bash
sudo systemctl restart sshd

# Testar em nova janela
ssh -p 2222 ubuntu@SEU_IP
```

### 4. UFW Firewall

```bash
# Instalar
sudo apt install ufw -y

# Regras básicas
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir SSH (IMPORTANTE!)
sudo ufw allow 22/tcp
# ou se trocou a porta:
# sudo ufw allow 2222/tcp

# Permitir HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Habilitar
sudo ufw enable

# Ver status
sudo ufw status verbose
```

## 🚇 SSH Tunneling (Port Forwarding)

### O que é SSH Tunnel?

Permite acessar portas do servidor remoto como se fossem locais. Útil para:
- Acessar serviços não expostos publicamente
- Contornar firewalls
- Segurança extra (tráfego criptografado)

### Tunnel Local (Local Port Forwarding)

**Sintaxe**: `ssh -L [porta_local]:[destino]:[porta_remota] usuario@servidor`

#### Exemplo 1: Acessar Nginx Proxy Manager

NPM roda na porta 81 do servidor, mas não quer expor publicamente:

```bash
# Criar tunnel
ssh -L 8181:localhost:81 ubuntu@SEU_IP -i ~/.ssh/oracle-key

# Agora acesse no navegador:
# http://localhost:8181
```

O que acontece:
1. Você acessa `localhost:8181` no seu PC
2. SSH encaminha para `localhost:81` no servidor
3. Nginx Proxy Manager responde

#### Exemplo 2: Acessar n8n Diretamente

```bash
# n8n roda na porta 5678
ssh -L 5678:localhost:5678 ubuntu@SEU_IP -i ~/.ssh/oracle-key

# Acesse: http://localhost:5678
```

#### Exemplo 3: Múltiplos Tunnels

```bash
ssh -L 8181:localhost:81 \
    -L 5678:localhost:5678 \
    ubuntu@SEU_IP \
    -i ~/.ssh/oracle-key
```

### Tunnel Remoto (Remote Port Forwarding)

Expõe porta local para o servidor remoto.

**Sintaxe**: `ssh -R [porta_remota]:localhost:[porta_local] usuario@servidor`

```bash
# Expor servidor web local (porta 8080) no servidor remoto
ssh -R 8080:localhost:8080 ubuntu@SEU_IP
```

### Tunnel Dinâmico (SOCKS Proxy)

Cria um proxy SOCKS para rotear todo tráfego:

```bash
ssh -D 8888 ubuntu@SEU_IP

# Configure navegador para usar SOCKS5 proxy: localhost:8888
```

### Manter Tunnel Aberto

Tunnels fecham quando a conexão SSH cai. Soluções:

**Opção 1: ServerAliveInterval**
```bash
ssh -L 8181:localhost:81 \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    ubuntu@SEU_IP
```

**Opção 2: autossh** (mantém tunnel sempre ativo)
```bash
# Instalar
sudo apt install autossh

# Usar
autossh -M 0 -f -N \
    -o "ServerAliveInterval 60" \
    -o "ServerAliveCountMax 3" \
    -L 8181:localhost:81 \
    ubuntu@SEU_IP
```

**Opção 3: systemd service** (persiste após reboot)
```bash
sudo nano /etc/systemd/system/npm-tunnel.service
```

```ini
[Unit]
Description=SSH Tunnel to Nginx Proxy Manager
After=network.target

[Service]
User=seu-usuario
ExecStart=/usr/bin/ssh -N -L 8181:localhost:81 oracle
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable npm-tunnel
sudo systemctl start npm-tunnel
```

## 🔄 Gerenciando Múltiplas Chaves SSH

### Estrutura Organizada

```
~/.ssh/
├── config                  # Configuração SSH
├── oracle-key              # Chave Oracle
├── oracle-key.pub
├── github-key              # Chave GitHub
├── github-key.pub
└── trabalho-key            # Chave do trabalho
    └── trabalho-key.pub
```

### Config para Múltiplas Chaves

```
# Servidor Oracle
Host oracle
    HostName SEU_IP
    User ubuntu
    IdentityFile ~/.ssh/oracle-key

# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github-key

# Servidor do trabalho
Host trabalho
    HostName 10.0.0.50
    User admin
    IdentityFile ~/.ssh/trabalho-key
```

## 💾 Backup de Chaves SSH

### Fazer Backup

**⚠️ CUIDADO**: Chaves privadas são sensíveis!

```bash
# Copiar para pendrive/HD externo criptografado
cp ~/.ssh/oracle-key /caminho/seguro/

# Ou fazer backup criptografado
tar czf - ~/.ssh/oracle-key | \
    gpg -c > ~/backup/oracle-ssh-key.tar.gz.gpg
```

### Restaurar Backup

**Cenário**: Novo computador ou chave perdida

```bash
# Baixar suas chaves do backup seguro
# (Google Drive privado, gerenciador de senhas, pendrive, etc)

# Criar diretório .ssh
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Mover chaves para ~/.ssh/
mv ~/Downloads/sua-chave.key ~/.ssh/
mv ~/Downloads/sua-chave.key.pub ~/.ssh/

# Ajustar permissões
chmod 600 ~/.ssh/sua-chave.key
chmod 644 ~/.ssh/sua-chave.key.pub

# Adicionar ao agent
ssh-add ~/.ssh/sua-chave.key

# Testar conexão
ssh -i ~/.ssh/sua-chave.key ubuntu@SEU_IP
```

**💡 Dica**: Mantenha backup das chaves em:
- Google Drive (pasta privada)
- Gerenciador de senhas (1Password, Bitwarden)
- Pendrive/HD externo criptografado
- Múltiplas localizações (regra 3-2-1)

## 📝 Checklist de Segurança SSH

- [ ] Chave SSH criada com algoritmo forte (ed25519 ou RSA 4096)
- [ ] Permissões corretas (chave privada: 600, .ssh/: 700)
- [ ] Autenticação por senha desabilitada
- [ ] Root login desabilitado
- [ ] Fail2ban instalado e configurado
- [ ] UFW firewall ativo
- [ ] Porta SSH não-padrão (opcional)
- [ ] ServerAliveInterval configurado
- [ ] Backup de chaves SSH em local seguro
- [ ] ~/.ssh/config criado para facilitar acesso

## 🆘 Troubleshooting SSH

### "Permission denied (publickey)"

```bash
# Verificar permissões
ls -la ~/.ssh/
chmod 600 ~/.ssh/oracle-key
chmod 700 ~/.ssh

# Testar conexão verbose
ssh -vvv -i ~/.ssh/oracle-key ubuntu@SEU_IP

# Verificar authorized_keys no servidor
cat ~/.ssh/authorized_keys
```

### "Bad permissions"

```bash
# SSH recusa se permissões muito abertas
chmod 600 ~/.ssh/oracle-key
```

### "Connection timed out"

- Porta 22 (ou sua porta custom) aberta no Oracle Security List?
- IP correto?
- Servidor está rodando? (verificar no console Oracle)

### "Too many authentication failures"

```bash
# Muitas chaves no ssh-agent
ssh-add -D  # Remove todas
ssh-add ~/.ssh/oracle-key  # Adiciona apenas a necessária
```

## 🔗 Recursos Adicionais

- [SSH.com - SSH Keys](https://www.ssh.com/academy/ssh/key)
- [SSH Tunneling Explained](https://www.ssh.com/academy/ssh/tunneling)
- [Fail2Ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)

---

**💡 Dica Pro**: Salve seus comandos SSH mais usados em aliases no `~/.bashrc`:

```bash
alias oracle-ssh='ssh -i ~/.ssh/sua-chave.key ubuntu@SEU_IP'
alias oracle-npm='ssh -L 8181:localhost:81 -i ~/.ssh/sua-chave.key ubuntu@SEU_IP'
```
