# Troubleshooting - Guia de Resolução de Problemas

Soluções para problemas comuns no servidor Oracle Cloud Always Free.

## 🐛 Watchtower

### Erro: "client version 1.25 is too old"

**Sintoma**: Watchtower fica reiniciando constantemente com erro `Error response from daemon: client version 1.25 is too old. Minimum supported API version is 1.44`

**Causa**: Imagem do Watchtower muito antiga, incompatível com versão atual do Docker

**Solução**:

```bash
# Método 1: Via docker-compose
cd ~/docker  # ou onde está seu docker-compose.yml
docker-compose pull watchtower
docker-compose up -d watchtower

# Método 2: Manual
docker stop watchtower
docker rm watchtower
docker pull containrrr/watchtower:latest
docker run -d \
  --name watchtower \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e WATCHTOWER_CLEANUP=true \
  containrrr/watchtower:latest

# Verificar se funcionou
docker logs watchtower --tail 20
```

### Watchtower não atualiza containers

**Possíveis causas**:

1. **Container com label de exclusão**
   ```bash
   # Ver labels do container
   docker inspect nome-container | grep -i watchtower
   ```

2. **Imagem com tag específica (não :latest)**
   ```bash
   # Watchtower só atualiza se usar :latest
   # Ruim:  image: n8nio/n8n:1.0.0
   # Bom:   image: n8nio/n8n:latest
   ```

3. **Notificações não configuradas**
   ```bash
   # Adicionar ao docker-compose do Watchtower
   environment:
     - WATCHTOWER_NOTIFICATIONS=slack
     - WATCHTOWER_NOTIFICATION_SLACK_HOOK_URL=seu_webhook
   ```

---

## 🌐 Nginx Proxy Manager

### Não consegue acessar porta 81

**Verificações**:

```bash
# 1. Container está rodando?
docker ps | grep npm

# 2. Porta está aberta no host?
sudo netstat -tulpn | grep 81

# 3. Firewall local
sudo ufw status
sudo ufw allow 81/tcp

# 4. Oracle Cloud Security List
# Console Web → VCN → Security Lists → Ingress Rules
# Adicionar: 0.0.0.0/0 → TCP → 81
```

### Certificados SSL falham

**Erro comum**: Challenge failed for domain

**Soluções**:

1. **DNS não está apontando corretamente**
   ```bash
   # Verificar DNS
   nslookup seu-dominio.com
   dig seu-dominio.com
   ```

2. **Portas 80/443 não estão acessíveis**
   ```bash
   # Testar externamente
   curl -I http://seu-ip
   curl -I https://seu-ip
   ```

3. **Rate limit do Let's Encrypt**
   - Limite: 5 certificados por domínio por semana
   - Use staging durante testes

### Proxy host não funciona

```bash
# Ver logs do NPM
docker logs npm --tail 100 -f

# Verificar conectividade interna
docker exec npm ping nome-do-container

# Se containers estão em redes diferentes
# Adicione ambos à mesma rede:
networks:
  - proxy-network
```

---

## 🔄 n8n

### Container não inicia

```bash
# Ver logs
docker logs n8n --tail 50

# Problema comum: permissões
sudo chown -R 1000:1000 ~/docker/n8n-data/

# Restart
docker restart n8n
```

### Workflows não executam

**Verificações**:

1. **Webhook URL configurada**
   ```bash
   docker exec n8n env | grep WEBHOOK
   # Deve mostrar: WEBHOOK_URL=https://seu-dominio.com/
   ```

2. **Proxy configurado corretamente**
   - No NPM, criar Proxy Host
   - Domain: n8n.seu-dominio.com
   - Forward to: n8n:5678
   - Websockets Support: ✅ ON

3. **Memória suficiente**
   ```bash
   docker stats n8n
   # Se estiver alto, considere limitar execuções simultâneas
   ```

### Perda de dados

```bash
# Verificar se volume está montado
docker inspect n8n | grep -A 10 Mounts

# Backup manual imediato
docker exec n8n tar czf /tmp/n8n-backup.tar.gz /home/node/.n8n
docker cp n8n:/tmp/n8n-backup.tar.gz ~/backups/
```

---

## 🖥️ RustDesk

### Cliente não conecta ao servidor

**Checklist**:

```bash
# 1. Portas abertas no firewall
sudo ufw status | grep 211
sudo ufw allow 21115:21119/tcp

# 2. Oracle Cloud Security List
# Portas 21115-21119/TCP devem estar liberadas

# 3. Containers rodando
docker ps | grep rust

# 4. Logs
docker logs hbbs --tail 20
docker logs hbbr --tail 20

# 5. Chave pública está correta?
cat ~/rustdesk/id_ed25519.pub
```

**Configuração no cliente**:
- ID Server: `seu-ip-ou-dominio`
- Relay Server: `seu-ip-ou-dominio`
- Key: conteúdo de `id_ed25519.pub`

### Conexão lenta ou instável

```bash
# Verificar latência
ping seu-servidor-ip

# Verificar bandwidth usage
docker stats hbbr hbbs

# Considerar usar relay público para testes
# No cliente: deixar "Relay Server" vazio temporariamente
```

---

## 🔧 Docker

### Container não inicia

```bash
# Logs detalhados
docker logs nome-container --tail 100

# Ver eventos
docker events --since 5m

# Inspecionar
docker inspect nome-container

# Forçar recriação
docker-compose up -d --force-recreate nome-container
```

### Erro: "no space left on device"

```bash
# Ver uso de disco
df -h

# Limpar containers parados
docker container prune -f

# Limpar imagens não usadas
docker image prune -a -f

# Limpar volumes não usados (CUIDADO!)
docker volume prune -f

# Limpar tudo (CUIDADO!)
docker system prune -a --volumes -f
```

### Docker daemon não responde

```bash
# Restart do Docker
sudo systemctl restart docker

# Se não resolver, reboot
sudo reboot

# Ver status
sudo systemctl status docker

# Ver logs do daemon
sudo journalctl -u docker --since "1 hour ago"
```

---

## 🔐 Oracle CLI

### Erro: "Authentication failed"

```bash
# Verificar configuração
cat ~/.oci/config

# Testar autenticação
oci iam region list

# Reconfigurar se necessário
oci setup config
```

### Erro: "Permission denied"

```bash
# Verificar permissões da chave
ls -la ~/.oci/
chmod 600 ~/.oci/oci_api_key
chmod 644 ~/.oci/oci_api_key_public.pem
```

---

## 💾 Backups

### Backup não executa

```bash
# Ver logs do cron
tail -f ~/rclone_n8n_backup.log

# Testar backup manual
~/scripts/daily_backup.sh

# Verificar se rclone está configurado
rclone listremotes
rclone ls gdrive:
```

### Rclone falha com erro 403

```bash
# Token expirou, reautorizar
rclone config reconnect gdrive:

# Ou reconfigurar do zero
rclone config
```

---

## 📊 Monitoramento

### Scripts de monitoramento não enviam alertas

```bash
# Verificar se WEBHOOK_URL está configurado
grep WEBHOOK /opt/oci_scripts/monitoring/*.sh

# Testar webhook manualmente
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Teste de alerta"}' \
  SEU_WEBHOOK_URL

# Ver logs
tail -f /var/log/oci/*.log
```

### CPU Keep-Alive não está funcionando

```bash
# Verificar serviço
sudo systemctl status cpu-keepalive

# Ver logs
sudo journalctl -u cpu-keepalive -n 50

# Verificar uso de CPU
htop
top

# Restart
sudo systemctl restart cpu-keepalive
```

---

## 🌐 Rede

### Porta não está acessível externamente

**Checklist completo**:

1. **Serviço está rodando?**
   ```bash
   sudo netstat -tulpn | grep PORTA
   ```

2. **Firewall local (UFW)**
   ```bash
   sudo ufw status
   sudo ufw allow PORTA/tcp
   ```

3. **iptables**
   ```bash
   sudo iptables -L -n -v
   ```

4. **Oracle Cloud Security List**
   - Console → VCN → Security Lists
   - Ingress Rules → Add Rule
   - Source: 0.0.0.0/0
   - Protocol: TCP
   - Port: PORTA

5. **Testar externamente**
   ```bash
   # De outro computador
   telnet SEU_IP PORTA
   nc -zv SEU_IP PORTA
   ```

### Alta latência

```bash
# MTR para diagnóstico
mtr -r seu-servidor-ip

# Traceroute
traceroute seu-servidor-ip

# Verificar bandwidth
speedtest-cli
```

---

## 💡 Problemas Gerais

### Sistema lento

```bash
# Ver processos
htop
top

# Ver I/O
iotop

# Verificar memória
free -h

# Ver disco
df -h
du -sh /* | sort -h

# Processos zumbis
ps aux | grep defunct
```

### Unattended-upgrades causou problemas

```bash
# Ver o que foi atualizado
cat /var/log/unattended-upgrades/unattended-upgrades.log

# Reverter pacote específico
sudo apt-cache policy nome-pacote
sudo apt install nome-pacote=versao-anterior

# Desabilitar temporariamente
sudo systemctl stop unattended-upgrades
```

### Instância foi reclamada pela Oracle

**Prevenção**:
- ✅ CPU Keep-Alive sempre ativo
- ✅ Monitoramento de CPU configurado
- ✅ Alertas no Slack funcionando

**Se aconteceu**:
1. Provisionar nova instância
2. Restaurar backups do Google Drive
3. Reconfigurar DNS
4. Reconfigurar Oracle CLI

---

## 📞 Onde Buscar Ajuda

1. **Logs são seus amigos**
   - Sempre verifique logs antes de perguntar
   - `/var/log/` para sistema
   - `docker logs` para containers

2. **Documentação oficial**
   - Docker: https://docs.docker.com/
   - Oracle Cloud: https://docs.oracle.com/cloud/
   - n8n: https://docs.n8n.io/

3. **Issues do GitHub**
   - Abra uma issue no repositório
   - Inclua logs relevantes
   - Descreva o problema claramente

4. **Comunidades**
   - r/oraclecloud
   - r/selfhosted
   - Discord do n8n

---

## 🛠️ Scripts Úteis de Debug

### Script de diagnóstico completo

```bash
#!/bin/bash

echo "=== DIAGNÓSTICO DO SISTEMA ==="
date
echo ""

echo "=== DISCO ==="
df -h
echo ""

echo "=== MEMÓRIA ==="
free -h
echo ""

echo "=== CPU ==="
uptime
echo ""

echo "=== DOCKER ==="
docker ps -a
echo ""

echo "=== PORTAS ==="
sudo ss -tulpn | grep LISTEN
echo ""

echo "=== ÚLTIMAS LINHAS DOS LOGS ==="
for log in /var/log/oci/*.log; do
    echo "--- $log ---"
    tail -n 5 "$log"
    echo ""
done

echo "=== LOGS DO DOCKER ==="
for container in $(docker ps --format '{{.Names}}'); do
    echo "--- $container ---"
    docker logs "$container" --tail 5
    echo ""
done
```

Salve como `diagnostico.sh`, execute e compartilhe o output ao pedir ajuda!
