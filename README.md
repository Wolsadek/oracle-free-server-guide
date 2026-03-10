# Oracle Free Server Guide

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Bash](https://img.shields.io/badge/bash-5.0+-green.svg)
![Oracle Cloud](https://img.shields.io/badge/oracle_cloud-always_free-red.svg)
![Docker](https://img.shields.io/badge/docker-compose-blue.svg)
![Monitoring](https://img.shields.io/badge/monitoring-slack-purple.svg)

Guia completo em português para configurar e monitorar um servidor gratuito da Oracle Cloud Always Free Tier. Inclui scripts de monitoramento, backups automáticos, stack Docker e muito mais.

## ⚡ Quick Start

**Pressa?** → [Setup em 10 minutos](QUICKSTART.md)

## 🎯 O que é isso?

Este guia te ensina a configurar um servidor **gratuito para sempre** na Oracle Cloud com:

- 🖥️ **4 vCPUs + 24GB RAM** (grátis!)
- 📊 **Monitoramento automático** (CPU, Storage, Bandwidth)
- 🔔 **Alertas no Slack** quando algo anormal acontece
- 💾 **Backups automáticos** para Google Drive
- 🐳 **Stack Docker** pronta (Nginx PM, n8n, RustDesk)
- 🔒 **Segurança** (fail2ban, UFW, SSH hardening)

## 📺 Vídeos Tutoriais

- [Como criar servidor GRÁTIS na Oracle Cloud](https://www.youtube.com/watch?v=1XSsxMhnGTs)
- [Tutorial Complementar](https://www.youtube.com/watch?v=SsK4YIIR69w)

## 📚 Documentação

### 🚀 Começando
- [**QUICKSTART.md**](QUICKSTART.md) - Setup completo em 10 minutos
- [**Billing Alerts**](docs/BILLING-ALERTS.md) - ⚠️ Configure alertas de cobrança (FAÇA PRIMEIRO!)
- [**Disaster Recovery**](docs/DISASTER-RECOVERY.md) - 🆘 Plano de contingência e backup completo
- [**FAQ**](docs/FAQ.md) - 50+ perguntas frequentes sobre Always Free

### 🔧 Guias Técnicos
- [**Access Guide**](docs/ACCESS-GUIDE.md) - Referência rápida de comandos e acesso
- [**SSH Security**](docs/SSH-SECURITY.md) - Chaves SSH, tunneling, hardening
- [**Services**](docs/SERVICES.md) - Nginx PM, n8n, RustDesk, Watchtower
- [**Docker Compose**](docs/DOCKER-COMPOSE-EXAMPLES.md) - Stack completa production-ready

### 🎨 Customização
- [**MOTD**](docs/MOTD.md) - Banner personalizado ao fazer SSH

### 🆘 Suporte
- [**Troubleshooting**](docs/TROUBLESHOOTING.md) - Soluções para problemas comuns
- [**Índice Completo**](docs/README.md) - Toda documentação disponível

## 🎯 Oracle Always Free Tier - O que você ganha

| Recurso | Limite Always Free |
|---------|-------------------|
| **Compute** | 2 VMs (até 4 OCPUs + 24GB RAM total) |
| **Block Storage** | 200 GB |
| **Object Storage** | 20 GB |
| **Bandwidth** | 10 TB/mês de saída |
| **IP Público** | 2 IPs fixos |

**⚠️ Importante**: CPU deve ficar acima de 20% para evitar reclamação da instância!

## 🚀 Instalação Rápida

```bash
# 1. Clone o repositório
git clone https://github.com/wolsadek/oracle-free-server-guide.git
cd oracle-free-server-guide

# 2. Execute o setup automático
chmod +x scripts/setup.sh
./scripts/setup.sh

# 3. Configure suas credenciais (veja instruções no final do setup)
```

Depois siga as instruções em [QUICKSTART.md](QUICKSTART.md) para:
- Configurar Oracle CLI
- Configurar Slack (alertas)
- Ativar CPU Keep-Alive
- Configurar monitoramento

## 📦 O que está incluído?

### Scripts de Monitoramento
- `cpu_monitor.sh` - Monitora CPU (alerta < 20%)
- `storage_monitor.sh` - Monitora storage (200GB limit)
- `bandwidth_monitor.sh` - Monitora bandwidth (10TB/mês)
- Alertas automáticos no Slack

### Backups Automáticos (n8n)
- `daily_backup.sh` - Backup completo do n8n
- `workflow_backup.sh` - Backup de workflows via API
- Sync com Google Drive via rclone

### Stack Docker (Opcional)
- **Nginx Proxy Manager** - Proxy reverso + SSL automático
- **n8n** - Automação de workflows (tipo Zapier)
- **RustDesk** - Servidor de acesso remoto próprio
- **Watchtower** - Auto-update de containers

### Utilitários
- `setup.sh` - Instalação automática de tudo
- `diagnostico.sh` - Gera relatório completo do servidor
- `monthly_report.sh` - Relatório mensal automático por email
- `cpu-keepalive.service` - Mantém CPU sempre ativa

## 💡 Por que usar Oracle Always Free?

**Vantagens**:
- ✅ **Grátis para sempre** (não é trial)
- ✅ **Hardware potente** (4 vCPUs Ampere A1, 24GB RAM)
- ✅ **IP fixo incluído**
- ✅ **Sem limite de tempo**

**Cuidados**:
- ⚠️ Manter CPU > 20% (use cpu-keepalive)
- ⚠️ Configurar backups (pode reclamar instância)
- ⚠️ Monitorar recursos (alertas incluídos neste guia)

## 🔧 Pré-requisitos

- Conta Oracle Cloud (aceita cartão de crédito mas não cobra no free tier)
- Servidor Ubuntu 24.04 provisionado
- Slack workspace (para alertas) - opcional mas recomendado

## 📖 Documentação Completa

Veja o [índice completo de documentação](docs/README.md) para:
- Guias detalhados de cada serviço
- Configurações avançadas
- Troubleshooting específico
- Dicas de otimização

## ⚠️ Dicas Importantes

### Região
Escolha **Brazil Southeast (Vinhedo)** - `sa-vinhedo-1`:
- Menor latência para BR
- Infraestrutura mais atual
- Melhor disponibilidade

### CPU Keep-Alive
**CRÍTICO**: A Oracle pode reclamar VMs com CPU baixa por 7+ dias.
- Use o serviço `cpu-keepalive` incluído (já configurado no setup)
- Scripts de monitoramento alertam se CPU ficar < 20%

### Backups
**Faça backups!** A Oracle pode:
- Reclamar instância por baixo uso
- Ter problemas na infraestrutura
- Fazer manutenções

Scripts de backup incluídos para n8n. Configure conforme [documentação](docs/SERVICES.md#-backups-do-n8n-opcional).

## 🤝 Contribuindo

Contribuições são bem-vindas! Veja [CONTRIBUTING.md](CONTRIBUTING.md).

**Ideias de contribuição**:
- Melhorias na documentação
- Novos scripts de monitoramento
- Suporte a outros serviços
- Correção de bugs
- Traduções

## 📝 Changelog

Veja [CHANGELOG.md](CHANGELOG.md) para histórico de versões.

## 📄 Licença

MIT License - veja [LICENSE](LICENSE) para detalhes.

## 🙏 Créditos

Baseado em experiências reais com Oracle Cloud Always Free Tier e scripts desenvolvidos pela comunidade.

---

**⭐ Se este guia foi útil, considere dar uma estrela no repositório!**

**💬 Dúvidas?** Abra uma [issue](https://github.com/wolsadek/oracle-free-server-guide/issues) ou consulte o [FAQ](docs/FAQ.md).
