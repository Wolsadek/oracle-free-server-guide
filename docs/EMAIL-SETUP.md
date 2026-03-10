# 📧 Configurar Email no Servidor (Opcional)

Como enviar emails do servidor Ubuntu usando Gmail SMTP.

## 🎯 Casos de Uso

Útil para:
- Alertas de scripts (alternativa ao Slack)
- Notificações de backup
- Logs de erros críticos
- Relatórios automáticos

## 📋 Pré-requisitos

- Conta Gmail
- App Password do Gmail (não usa senha normal)

## 🚀 Setup com msmtp + mailutils

### 1. Instalar pacotes

```bash
sudo apt update
sudo apt install msmtp msmtp-mta mailutils -y
```

### 2. Configurar Gmail App Password

1. Acesse: https://myaccount.google.com/apppasswords
2. Nome: "Oracle Server"
3. Gerar
4. Copie a senha (16 caracteres, sem espaços)

### 3. Configurar msmtp

```bash
nano ~/.msmtprc
```

Cole:

```
# Gmail SMTP
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           SEU_EMAIL@gmail.com
user           SEU_EMAIL@gmail.com
password       SUA_APP_PASSWORD_AQUI

account default : gmail
```

**Ajustar permissões** (importante!):

```bash
chmod 600 ~/.msmtprc
```

### 4. Testar

```bash
echo "Teste do servidor Oracle!" | mail -s "Email Funcionando" seu-email@gmail.com
```

Deve receber o email em alguns segundos!

## 🔧 Usar em Scripts

### Exemplo 1: Alerta simples

```bash
#!/bin/bash

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')

if (( $(echo "$CPU > 80" | bc -l) )); then
    echo "CPU está em ${CPU}%!" | mail -s "⚠️ Alerta CPU Alta" seu-email@gmail.com
fi
```

### Exemplo 2: Relatório diário

```bash
#!/bin/bash

REPORT=$(cat << EOF
=== Relatório Diário - $(date) ===

CPU: $(uptime | awk -F'load average:' '{print $2}')
Memória: $(free -h | awk 'NR==2{print $3 "/" $2}')
Disco: $(df -h / | awk 'NR==2{print $5}')

Containers:
$(docker ps --format "table {{.Names}}\t{{.Status}}")

EOF
)

echo "$REPORT" | mail -s "📊 Relatório Oracle Server" seu-email@gmail.com
```

### Exemplo 3: Integrar com scripts de monitoramento

Edite `cpu_monitor.sh` para também enviar email:

```bash
# Adicionar após send_slack_alert
send_email_alert() {
    local message="$1"
    echo "$message" | mail -s "🚨 Oracle Cloud Alert" seu-email@gmail.com
}
```

## 📝 dead.letter

O arquivo `~/dead.letter` guarda emails que falharam ao enviar.

**Ver conteúdo**:
```bash
cat ~/dead.letter
```

**Deletar**:
```bash
rm ~/dead.letter
```

**Por que falha?**
- SMTP não configurado (antes do setup)
- Senha/usuário errado
- Gmail bloqueou (precisa App Password)

## 🔐 Segurança

### Proteger senha

Permissões corretas:
```bash
chmod 600 ~/.msmtprc
```

### Não commitar no git

Já está em `.gitignore`:
```
.msmtprc
```

### Alternativa: variáveis de ambiente

```bash
# Em ~/.bashrc
export GMAIL_PASSWORD="sua_app_password"
```

Depois no `.msmtprc`:
```
passwordeval "echo $GMAIL_PASSWORD"
```

## 🆚 Email vs Slack

| | Email | Slack |
|---|-------|-------|
| **Setup** | Mais complexo | Simples (webhook) |
| **Custo** | Grátis | Grátis |
| **Confiabilidade** | Alta | Alta |
| **Notificações** | Push (app Gmail) | Push (app Slack) |
| **Histórico** | Infinito (Gmail) | 90 dias (free) |
| **Formatação** | Texto simples | Rich formatting |

**Recomendação**: Use ambos!
- Slack: alertas em tempo real
- Email: backup e relatórios

## 💡 Dicas

### Testar conexão SMTP

```bash
msmtp --serverinfo --host=smtp.gmail.com --tls=on --tls-certcheck=off
```

### Ver log

```bash
tail -f ~/.msmtp.log
```

### Enviar com anexo

```bash
echo "Veja o relatório anexo" | mail -s "Relatório" -A /path/to/file.txt seu-email@gmail.com
```

### HTML Email

```bash
cat << EOF | mail -a "Content-Type: text/html" -s "Test HTML" seu-email@gmail.com
<html>
<body>
<h1>Relatório do Servidor</h1>
<p><strong>Status:</strong> OK ✅</p>
</body>
</html>
EOF
```

## 🆘 Troubleshooting

### "Authentication failed"

- Certifique-se de usar **App Password**, não senha normal
- Verifique user e password no `.msmtprc`

### "Could not connect"

```bash
# Testar conexão
telnet smtp.gmail.com 587

# Se não funcionar, pode ser firewall
sudo ufw allow out 587/tcp
```

### "Permission denied"

```bash
chmod 600 ~/.msmtprc
```

### Email vai para spam

Adicione `From:` header:
```bash
echo "Teste" | mail -s "Subject" -a "From: Oracle Server <seu-email@gmail.com>" destino@gmail.com
```

## 🔗 Alternativas

### Outros provedores SMTP

**Outlook/Hotmail**:
```
host           smtp-mail.outlook.com
port           587
```

**SendGrid** (200 emails/dia grátis):
```
host           smtp.sendgrid.net
port           587
user           apikey
password       SUA_API_KEY
```

**Mailgun** (grátis até 5000/mês):
```
host           smtp.mailgun.org
port           587
```

## 📊 Relatório Mensal Automático

Quer receber um relatório completo do servidor todo mês? Use o script incluído!

### Setup

```bash
# 1. Editar o script com seu email
nano scripts/monthly_report.sh
# Mude: EMAIL_TO="seu-email@gmail.com"

# 2. Testar
./scripts/monthly_report.sh

# 3. Agendar para todo dia 1 do mês às 9h
crontab -e
# Adicionar:
0 9 1 * * /path/to/oracle-free-server-guide/scripts/monthly_report.sh
```

### O que o relatório inclui

- 📈 Resumo executivo (uptime, disco, memória)
- 🐳 Status dos containers Docker
- 🔥 Histórico de CPU
- 💾 Uso de storage
- 🌐 Consumo de bandwidth
- 💾 Status dos backups
- 🔒 Segurança (fail2ban, tentativas de login)
- 📦 Updates disponíveis
- 💰 Custos (sempre R$ 0 se Always Free!)
- 💡 Recomendações automáticas

**Preview**: Relatório formatado com emojis e seções organizadas!

## 📖 Links Úteis

- [msmtp Documentation](https://marlam.de/msmtp/)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)

---

**💡 Dica**: Para alertas críticos, use Email + Slack simultaneamente. Double layer!
