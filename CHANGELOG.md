# Changelog

Todas as mudanças notáveis neste projeto serão documentadas aqui.

## [1.0.0] - 2026-03-10

### Adicionado

#### Scripts de Monitoramento
- `cpu_monitor.sh` - Monitora uso de CPU (alertas < 20%)
- `storage_monitor.sh` - Monitora storage (block e object, 200GB limit)
- `bandwidth_monitor.sh` - Monitora bandwidth mensal (10TB limit)
- `cpu-keepalive.service` - Serviço systemd para manter CPU ativa

#### Scripts de Backup (n8n)
- `daily_backup.sh` - Backup completo dos dados do n8n via rclone
- `workflow_backup.sh` - Backup individual de workflows via API

#### Automação e Setup
- `setup.sh` - Script de instalação automatizada completa
- `config.example.sh` - Arquivo de exemplo de configuração

#### Documentação Principal
- `README.md` - Guia completo com índice navegável
- `CONTRIBUTING.md` - Guia de contribuição
- `CHANGELOG.md` - Histórico de versões
- `.gitignore` - Proteção de credenciais

#### Badges e Melhorias Visuais
- Badges informativos no README
- Estrutura organizada e navegável
- Links rápidos para documentação

#### Documentação Adicional (`/docs`)
- `SERVICES.md` - Documentação completa de serviços:
  - Nginx Proxy Manager
  - n8n (workflow automation)
  - RustDesk Server (acesso remoto próprio)
  - Watchtower (auto-update)
  - Unattended Upgrades
  - Tabela de portas em uso
  - Comandos úteis
  
- `DOCKER-COMPOSE-EXAMPLES.md` - Stack Docker completa:
  - docker-compose.yml unificado
  - Variáveis de ambiente (.env)
  - Health checks
  - Redes Docker
  - Comandos de gerenciamento
  - Backup e restauração
  - Boas práticas de segurança
  
- `MOTD.md` - Banner personalizado SSH:
  - Setup com Neofetch
  - Status de containers Docker
  - Últimos logins
  - Paleta de cores customizável
  - Customizações avançadas (disco, memória, temperatura)
  
- `TROUBLESHOOTING.md` - Resolução de problemas:
  - Watchtower (client version too old)
  - Nginx Proxy Manager (portas, SSL)
  - n8n (permissões, webhooks)
  - RustDesk (conectividade)
  - Docker (espaço, daemon)
  - Oracle CLI (autenticação)
  - Backups (rclone)
  - Scripts de diagnóstico

- `SSH-SECURITY.md` - Segurança e acesso SSH:
  - Gerenciamento completo de chaves SSH
  - Setup inicial em novo computador
  - SSH tunneling detalhado (local, remote, dinâmico)
  - Hardening (desabilitar senha, fail2ban, UFW)
  - Configuração ~/.ssh/config
  - Backup e restauração de chaves
  - Troubleshooting completo

- `FAQ.md` - Perguntas frequentes:
  - Always Free Tier explicado
  - Limites e políticas
  - Segurança e firewall
  - Docker e containers
  - Backups
  - Rede e domínios
  - Suporte e comunidades

- `ACCESS-GUIDE.md` - Guia de acesso rápido:
  - Setup inicial em novo computador
  - Comandos SSH prontos para uso
  - Configurações ~/.ssh/config
  - Acesso a todos os serviços
  - Tabela de portas
  - Comandos de emergência
  - Workflow diário
  - Links úteis e backups

### Recursos
- Vídeos tutoriais incluídos
- Dicas sobre escolha de região (Vinhedo > São Paulo)
- Passo a passo de configuração da Oracle CLI
- Setup de API Keys e credenciais
- Configuração de crontab para automação
- Integração com Slack para alertas
- Suporte para backup via rclone no Google Drive
- Documentação de logs e debugging
- Exemplos de docker-compose production-ready
- MOTD customizado com neofetch
- RustDesk server setup completo

## Próximas Versões

### Planejado para v1.1.0
- [ ] Script de restauração automática de backups
- [ ] Dashboard de métricas (opcional)
- [ ] Suporte para outros serviços além do n8n
- [ ] Scripts de otimização de performance
- [ ] Alertas via Telegram/Discord

## Contribuindo

Veja [CONTRIBUTING.md](CONTRIBUTING.md) para detalhes sobre como contribuir.
