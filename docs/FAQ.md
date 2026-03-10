# FAQ - Perguntas Frequentes

Respostas para dúvidas comuns sobre Oracle Cloud Always Free Tier.

## 🆓 Always Free Tier

### O que é o Oracle Cloud Always Free?

Um plano gratuito **permanente** (não é trial) que oferece:
- 2 VMs AMD (Ampere A1) com até 4 OCPUs e 24GB RAM total
- 200 GB de block storage
- 10 TB de bandwidth por mês
- 20 GB de object storage

**Importante**: É diferente do trial de 30 dias/300 dólares. O Always Free continua após o trial expirar.

### Precisa de cartão de crédito?

Sim, a Oracle exige cartão de crédito para verificação de identidade, mas **não cobra** se você ficar dentro dos limites do Always Free.

### Posso ter mais de uma VM Always Free?

Sim! Você pode ter até **2 VMs** no Always Free Tier, dividindo os recursos:
- Exemplo: 1 VM com 4 OCPUs + 24GB RAM
- Ou: 2 VMs com 2 OCPUs + 12GB RAM cada

### Quais regiões oferecem Always Free?

Nem todas as regiões têm capacidade disponível. Regiões recomendadas:
- **Brazil Southeast (Vinhedo)** - `sa-vinhedo-1` ✅ (Recomendada para BR)
- US East (Ashburn)
- US West (Phoenix)

**Dica**: Se aparecer "Out of capacity", tente:
1. Horários diferentes (madrugada costuma funcionar)
2. Regiões diferentes
3. Usar o script de "spam" (tenta criar várias vezes até conseguir)

## 🖥️ Instância e Recursos

### Por que manter CPU acima de 20%?

A Oracle pode **reclamar** (deletar) instâncias que ficam com CPU muito baixa por 7+ dias consecutivos. 

**Solução**: Use o `cpu-keepalive.service` incluído neste guia.

### O que acontece se passar dos limites do Always Free?

Depende da configuração da sua conta:
- Se tiver **apenas Always Free** habilitado: recursos são **bloqueados** (não cobra)
- Se tiver **upgrade to Pay-As-You-Go**: você será **cobrado** pelo excedente

**Recomendação**: Configure os alertas de monitoramento deste guia!

### A VM é reiniciada automaticamente?

Sim, a Oracle pode fazer maintenance reboots. Por isso é importante:
- Usar `restart: unless-stopped` nos containers Docker
- Configurar serviços com `systemctl enable`
- Ter backups automáticos configurados

### Posso usar IP fixo?

Sim! O Always Free inclui **2 IPs públicos** gratuitos (IPv4). Eles são fixos enquanto a instância existir.

## 🔒 Segurança

### Preciso configurar firewall?

**SIM!** Dois níveis:

1. **Oracle Cloud Security Lists** (cloud firewall)
   - Já vem com algumas portas abertas
   - Configure em: VCN → Security Lists

2. **UFW no servidor** (firewall local)
   - Recomendado como segunda camada
   - Veja [Security Hardening](SSH-SECURITY.md)

### É seguro usar a porta 22 (SSH)?

Funcionalmente sim, mas é alvo de bots. Recomendações:
- Usar apenas chave SSH (desabilitar senha) ✅
- Instalar fail2ban ✅
- Opcional: trocar a porta SSH

### Devo expor portas de serviços?

**Não!** Use Nginx Proxy Manager:
- Serviços ficam em `localhost` apenas
- NPM faz proxy reverso com SSL
- Expõe apenas portas 80/443

Exemplo:
```yaml
n8n:
  ports:
    - '127.0.0.1:5678:5678'  # ✅ Bom (localhost apenas)
    # - '5678:5678'          # ❌ Ruim (expõe para internet)
```

## 🐳 Docker e Containers

### Qual a diferença entre docker e docker-compose?

- **docker**: Gerencia containers individuais
- **docker-compose**: Gerencia múltiplos containers de uma vez (stack)

**Use docker-compose** para projetos com vários serviços.

### Containers reiniciam após reboot?

Sim, se configurado com `restart: unless-stopped`:

```yaml
services:
  n8n:
    restart: unless-stopped  # Reinicia automaticamente
```

### Como atualizar containers?

Duas formas:

**Manual**:
```bash
docker-compose pull
docker-compose up -d
```

**Automático**:
Use Watchtower (incluído neste guia) - atualiza automaticamente.

### Containers estão consumindo muito espaço

```bash
# Ver uso
docker system df

# Limpar tudo (CUIDADO!)
docker system prune -a --volumes

# Limpar apenas imagens antigas
docker image prune -a
```

## 💾 Backups

### Com que frequência fazer backup?

Recomendado:
- **n8n workflows**: A cada 6 horas (via API) ✅
- **n8n data completo**: Diariamente ✅
- **Configs do servidor**: Semanalmente
- **Snapshot da VM**: Mensalmente (Oracle Console)

### Onde fazer backup?

**Não** apenas no servidor! Use:
- Google Drive (via rclone) ✅
- Outro provedor cloud
- Máquina local
- Git (para configs)

**Regra 3-2-1**: 3 cópias, 2 mídias diferentes, 1 offsite.

### Posso usar o Object Storage da Oracle para backup?

Sim! Os 20GB são gratuitos. Mas considere também:
- Backup externo (Google Drive) para disaster recovery
- Não depender apenas da Oracle

## 🌐 Rede e Domínios

### Preciso de um domínio?

Não é obrigatório, mas muito recomendado para:
- SSL/HTTPS (Let's Encrypt exige domínio)
- URLs amigáveis (n8n.seudominio.com vs IP:5678)
- Webhooks do n8n

Opções gratuitas:
- Freenom (grátis mas instável)
- Duck DNS (subdomínio grátis)
- Cloudflare (gerenciamento DNS)

### Como configurar DNS?

1. Registrar domínio
2. Adicionar registro A: `n8n.seudominio.com → IP_DA_VM`
3. Configurar Proxy Host no Nginx Proxy Manager
4. Gerar certificado SSL automático

Tempo de propagação: 5 minutos a 48 horas.

### Posso usar Cloudflare?

Sim! Mas atenção:
- **Proxy OFF** (nuvem cinza) para RustDesk e outras portas não-HTTP
- **Proxy ON** (nuvem laranja) para sites e APIs HTTP/HTTPS

## 🔧 Problemas Comuns

### "Out of capacity" ao criar VM

A região não tem recursos disponíveis. Soluções:
1. Tentar em horários diferentes (madrugada)
2. Trocar de região
3. Usar scripts que tentam criar automaticamente

### "Instance reclaimed"

A Oracle deletou sua VM por baixo uso. **Prevenção**:
- CPU Keep-Alive rodando ✅
- Monitoramento ativo ✅
- Alertas configurados ✅

Se acontecer: restaurar de backup.

### Não consigo conectar via SSH

Checklist:
1. IP correto?
2. Chave SSH correta? (`ssh -i caminho/para/chave`)
3. Permissões da chave? (`chmod 600 ~/.ssh/sua-chave`)
4. Porta 22 aberta no Security List?
5. VM está rodando? (verificar no console)

### Serviço não acessível pela internet

Duas camadas de firewall:

**Oracle Cloud**:
- VCN → Security Lists → Ingress Rules
- Adicionar: `0.0.0.0/0` → `TCP` → `PORTA`

**No servidor**:
```bash
sudo ufw allow PORTA/tcp
```

Testar: `telnet SEU_IP PORTA`

## 📊 Monitoramento

### Por que usar Slack para alertas?

- Notificações em tempo real
- Histórico de alertas
- Fácil de configurar
- Gratuito

Alternativas: Discord, Telegram, Email.

### Preciso monitorar 24/7?

Não precisa ficar olhando, mas configure alertas para:
- ✅ CPU baixa (< 20%)
- ✅ Storage alto (> 80%)
- ✅ Bandwidth alto (> 80%)

Os scripts deste guia fazem isso automaticamente.

## 🆘 Suporte

### Onde pedir ajuda?

1. **Documentação deste guia** (veja `docs/`)
2. **Issues do GitHub** (abra uma issue)
3. **Comunidades**:
   - r/oraclecloud
   - r/selfhosted
   - Discord do n8n (se for sobre n8n)

### Oracle tem suporte?

Always Free não tem suporte oficial da Oracle. Use:
- Documentação oficial: https://docs.oracle.com/cloud/
- Community Forums
- Este guia 😉

## 💡 Dicas e Boas Práticas

### Vale a pena usar Oracle Always Free?

**Prós**:
- ✅ Gratuito permanentemente
- ✅ Recursos generosos (4 OCPUs, 24GB RAM)
- ✅ IP fixo incluído
- ✅ Sem limite de tempo

**Contras**:
- ❌ Pode reclamar VM se CPU baixa
- ❌ "Out of capacity" em algumas regiões
- ❌ Sem suporte oficial

**Veredicto**: Excelente para homelab, projetos pessoais, aprendizado!

### Posso usar para produção?

Tecnicamente sim, mas considere:
- Configure monitoramento e alertas ✅
- Tenha backups offsite ✅
- CPU Keep-Alive ativo ✅
- Plano de disaster recovery

Para produção crítica: considere pagar por uma cloud com SLA.

### O que fazer primeiro depois de criar a VM?

1. ✅ Configurar SSH com chave (sem senha)
2. ✅ Instalar fail2ban
3. ✅ Configurar firewall (UFW)
4. ✅ Configurar CPU Keep-Alive
5. ✅ Instalar scripts de monitoramento
6. ✅ Configurar backups automáticos
7. ✅ Trocar senhas padrão (se usar Nginx PM, etc.)

Use o [QUICKSTART.md](../QUICKSTART.md) deste guia!

---

## 🤔 Sua dúvida não está aqui?

1. Veja [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Procure nas [Issues do GitHub](https://github.com/wolsadek/oracle-free-server-guide/issues)
3. Abra uma nova issue com sua pergunta

**Contribua**: Se descobrir algo útil, abra um PR para adicionar aqui!
