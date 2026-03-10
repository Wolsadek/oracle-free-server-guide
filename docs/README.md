# Documentação Completa

Índice de toda a documentação disponível neste guia.

## 📖 Documentos Disponíveis

### 🚀 [ACCESS-GUIDE.md](ACCESS-GUIDE.md)
**Guia de acesso rápido e referência de comandos**

Perfeito para:
- Setup inicial em novo computador
- Referência rápida de comandos SSH
- Como acessar cada serviço (n8n, NPM, RustDesk)
- Workflow diário
- Comandos de emergência

Use quando: Precisar de acesso rápido ou estiver configurando novo PC.

---

### ❓ [FAQ.md](FAQ.md)
**Perguntas frequentes sobre Oracle Cloud Always Free**

Responde:
- O que é Always Free Tier?
- Precisa cartão de crédito?
- O que acontece se passar dos limites?
- Por que manter CPU > 20%?
- Como funciona firewall?
- Com que frequência fazer backup?

Use quando: Tiver dúvidas sobre políticas, limites ou funcionamento.

---

### 🐳 [SERVICES.md](SERVICES.md)
**Documentação completa de todos os serviços**

Cobre:
- **Nginx Proxy Manager** - Configuração, acesso, uso
- **n8n** - Setup, environment vars, backups
- **RustDesk** - Servidor próprio de acesso remoto
- **Watchtower** - Auto-update de containers
- **Unattended Upgrades** - Updates automáticos
- Tabela de portas
- Comandos úteis

Use quando: Precisar configurar ou entender algum serviço específico.

---

### 🐋 [DOCKER-COMPOSE-EXAMPLES.md](DOCKER-COMPOSE-EXAMPLES.md)
**Stack Docker completa e production-ready**

Inclui:
- `docker-compose.yml` completo
- Variáveis de ambiente (`.env`)
- Health checks
- Networks
- Comandos de gerenciamento
- Backup e restauração
- Troubleshooting Docker

Use quando: For configurar Docker stack ou adicionar novos serviços.

---

### 🎨 [MOTD.md](MOTD.md)
**Banner customizado ao fazer login SSH**

Ensina:
- Instalar e configurar Neofetch
- Criar MOTD personalizado
- Mostrar status de containers
- Últimos logins
- Customizações (cores, disco, memória)
- Alternativas (fastfetch, screenfetch)

Use quando: Quiser personalizar o banner de login SSH.

---

### 🔑 [SSH-SECURITY.md](SSH-SECURITY.md)
**Guia completo de SSH, chaves e segurança**

Cobre:
- Gerar e gerenciar chaves SSH
- Configurar permissões corretas
- SSH Agent e ~/.ssh/config
- **SSH Tunneling** (local, remote, dinâmico)
- Hardening (desabilitar senha, fail2ban, UFW)
- Múltiplas chaves SSH
- Backup de chaves
- Troubleshooting SSH completo

Use quando: Precisar configurar SSH, criar tunnels ou resolver problemas de conexão.

---

### 🔧 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
**Soluções para problemas comuns**

Resolve:
- **Watchtower** - "client version too old"
- **Nginx Proxy Manager** - Portas, SSL, proxy hosts
- **n8n** - Container não inicia, workflows
- **RustDesk** - Conectividade
- **Docker** - Espaço, daemon
- **Oracle CLI** - Autenticação
- **Backups** - rclone, permissões
- **Rede** - Portas, firewall
- Scripts de diagnóstico

Use quando: Algo não estiver funcionando ou tiver um erro.

---

## 🎯 Começando

### Novo no projeto?

1. Leia [../QUICKSTART.md](../QUICKSTART.md) - Setup em 10 minutos
2. Veja [ACCESS-GUIDE.md](ACCESS-GUIDE.md) - Como acessar tudo
3. Configure [SSH-SECURITY.md](SSH-SECURITY.md) - Segurança básica
4. Consulte [FAQ.md](FAQ.md) - Entenda o Always Free Tier

### Já tem o servidor rodando?

- **Adicionar serviço**: [DOCKER-COMPOSE-EXAMPLES.md](DOCKER-COMPOSE-EXAMPLES.md)
- **Problema**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Dúvida**: [FAQ.md](FAQ.md)
- **Acesso**: [ACCESS-GUIDE.md](ACCESS-GUIDE.md)

### Quer customizar?

- **Banner SSH**: [MOTD.md](MOTD.md)
- **Segurança**: [SSH-SECURITY.md](SSH-SECURITY.md)
- **Services**: [SERVICES.md](SERVICES.md)

## 📊 Estrutura da Documentação

```
docs/
├── README.md                      # Este arquivo (índice)
├── ACCESS-GUIDE.md                # Referência rápida de acesso
├── FAQ.md                         # Perguntas frequentes
├── SSH-SECURITY.md                # SSH, chaves, tunneling, segurança
├── SERVICES.md                    # Nginx PM, n8n, RustDesk, Watchtower
├── DOCKER-COMPOSE-EXAMPLES.md     # Stack Docker completa
├── MOTD.md                        # Banner SSH customizado
└── TROUBLESHOOTING.md             # Resolução de problemas
```

## 🔍 Buscar Informação Específica

### Quer saber sobre...

**SSH e Acesso**:
- Como conectar: [ACCESS-GUIDE.md](ACCESS-GUIDE.md#-acesso-ssh)
- SSH Tunneling: [SSH-SECURITY.md](SSH-SECURITY.md#-ssh-tunneling-port-forwarding)
- Chaves SSH: [SSH-SECURITY.md](SSH-SECURITY.md#-ssh-keys---setup-completo)
- Novo computador: [ACCESS-GUIDE.md](ACCESS-GUIDE.md#setup-inicial-em-novo-computador)

**Serviços**:
- n8n: [SERVICES.md](SERVICES.md#n8n---workflow-automation)
- Nginx PM: [SERVICES.md](SERVICES.md#nginx-proxy-manager-npm)
- RustDesk: [SERVICES.md](SERVICES.md#rustdesk-server)
- Watchtower: [SERVICES.md](SERVICES.md#watchtower---auto-update-de-containers)

**Docker**:
- docker-compose: [DOCKER-COMPOSE-EXAMPLES.md](DOCKER-COMPOSE-EXAMPLES.md)
- Comandos: [DOCKER-COMPOSE-EXAMPLES.md](DOCKER-COMPOSE-EXAMPLES.md#-comandos-úteis)
- Troubleshooting: [TROUBLESHOOTING.md](TROUBLESHOOTING.md#-docker)

**Segurança**:
- Firewall: [FAQ.md](FAQ.md#preciso-configurar-firewall)
- Fail2ban: [SSH-SECURITY.md](SSH-SECURITY.md#2-instalar-e-configurar-fail2ban)
- Hardening: [SSH-SECURITY.md](SSH-SECURITY.md#-hardening---segurança-avançada)

**Problemas**:
- Container não inicia: [TROUBLESHOOTING.md](TROUBLESHOOTING.md#container-não-inicia)
- SSH não conecta: [TROUBLESHOOTING.md](TROUBLESHOOTING.md#não-consigo-conectar-via-ssh)
- Porta não acessível: [TROUBLESHOOTING.md](TROUBLESHOOTING.md#porta-não-está-acessível-externamente)
- Watchtower reiniciando: [TROUBLESHOOTING.md](TROUBLESHOOTING.md#erro-client-version-125-is-too-old)

**Oracle Cloud**:
- Limites: [FAQ.md](FAQ.md#-oracle-always-free-tier-limites)
- Regiões: [FAQ.md](FAQ.md#quais-regiões-oferecem-always-free)
- Custos: [FAQ.md](FAQ.md#o-que-acontece-se-passar-dos-limites-do-always-free)
- Reclamação: [FAQ.md](FAQ.md#por-que-manter-cpu-acima-de-20)

## 💡 Dicas de Uso

### Para Iniciantes

1. **Siga o QUICKSTART** primeiro
2. **Configure SSH** corretamente ([SSH-SECURITY.md](SSH-SECURITY.md))
3. **Leia o FAQ** para entender os limites
4. **Use ACCESS-GUIDE** como referência rápida

### Para Avançados

- **SERVICES.md** - Configurações avançadas
- **DOCKER-COMPOSE-EXAMPLES.md** - Stack production-ready
- **SSH-SECURITY.md** - Tunneling e hardening

### Para Troubleshooting

1. Consulte [TROUBLESHOOTING.md](TROUBLESHOOTING.md) primeiro
2. Use o script `diagnostico.sh` para gerar relatório
3. Procure no [FAQ.md](FAQ.md)
4. Abra uma issue no GitHub

## 🤝 Contribuindo

Documentação incompleta ou errada? Veja [../CONTRIBUTING.md](../CONTRIBUTING.md)

## 📝 Changelog

Veja [../CHANGELOG.md](../CHANGELOG.md) para histórico de mudanças.

---

**🏠 Voltar para**: [README principal](../README.md) | [Quick Start](../QUICKSTART.md)
