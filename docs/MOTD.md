# MOTD Customizado (Message of the Day)

Guia para configurar um banner personalizado ao fazer login SSH no servidor.

## 🎨 O que é MOTD?

MOTD (Message of the Day) é o banner que aparece quando você faz login via SSH. Por padrão, mostra informações básicas do sistema, mas podemos customizar para mostrar informações úteis.

## 📋 MOTD Customizado - Layout Completo

Este é um exemplo de MOTD que mostra:
- ✅ Neofetch com informações visuais do sistema
- ✅ Status de todos os containers Docker
- ✅ Últimos 2 logins no servidor
- ✅ Cores customizadas

### Instalação

#### 1. Instalar Neofetch

```bash
sudo apt update
sudo apt install neofetch -y
```

#### 2. Criar o script de MOTD customizado

```bash
sudo nano /etc/update-motd.d/05-custom-welcome
```

Cole o seguinte conteúdo:

```bash
#!/bin/bash

# --- Paleta de Cores ---
# Use estas variáveis para mudar as cores facilmente.
# O '-e' no comando 'echo' é necessário para interpretar as cores.

NC='\033[0m'       # No Color (reseta a formatação)
BOLD='\033[1m'     # Negrito

# Cores Normais
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# --- Fim da Paleta de Cores ---


# Roda o neofetch para um visual incrível (ele já tem suas próprias cores)
neofetch

# Uma linha divisória para organizar
echo -e "${BLUE}----------------------------------------------------------------${NC}"

# Mostra o status dos seus contêineres Docker (com portas!)
echo -e "${BOLD}${CYAN} > Status dos Contêineres Ativos:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
echo

# Mostra os 2 últimos logins anteriores
echo -e "${BOLD}${YELLOW} > Últimos Logins Anteriores:${NC}"
last -n 3 -w | head -n 2
echo -e "${BLUE}----------------------------------------------------------------${NC}"
```

#### 3. Dar permissões de execução

```bash
sudo chmod +x /etc/update-motd.d/05-custom-welcome
```

#### 4. Testar o MOTD

```bash
# Executar manualmente para testar
sudo /etc/update-motd.d/05-custom-welcome

# Ou fazer logout e login novamente
exit
# Logue novamente via SSH
```

## 🎯 Exemplo de Output

```
            .-/+oossssoo+/-.               ubuntu@instance-20250922-1338
        `:+ssssssssssssssssss+:`           ----------------------------- 
      -+ssssssssssssssssssyyssss+-         OS: Ubuntu 24.04 LTS x86_64 
    .ossssssssssssssssssdMMMNysssso.       Host: Oracle Cloud Infrastructure
   /ssssssssssshdMMMMMMMMMMMMMMyyyssss/    Kernel: 6.8.0-1021-oracle 
  +ssssssssshmNMMMMMMMMMMMMMMMMNhssssss+   Uptime: 107 days, 9 hours, 31 mins 
 /ssssssshNMMMyhhhhhhhhyhmNMMMMMNmhsssss/  Packages: 1567 (dpkg) 
.ssssssssdMMMNhsssssssssshNMMMdmMMMhsssss. Shell: bash 5.2.21 
+sssshhhyNMMNyssssssssssssyNMMMhNMMMyssss+ CPU: AMD EPYC 7551 (4) @ 1.996GHz 
ossyNMMMNyMMhssssssssssssshhmMMNMMNhssssso Memory: 3521MiB / 23446MiB 
ossyNMMMNyMMhssssssssssssshhmMMNMMNhssssso
+sssshhhyNMMNyssssssssssssyNMMMhNMMMyssss+                         
.ssssssssdMMMNhsssssssssshNMMMdmMMMhsssss.
 /ssssssshNMMMyhhhhhhhhyhmNMMMMMNmhsssss/
  +ssssssssshmNMMMMMMMMMMMMMMMMNhssssss+
   /ssssssssssshdMMMMMMMMMMMMMMyyyssss/
    .ossssssssssssssssssdMMMNysssso.
      -+sssssssssssssssssyyyssss+-
        `:+ssssssssssssssssss+:`
            .-/+oossssoo+/-.

----------------------------------------------------------------
 > Status dos Contêineres Ativos:
NAMES        STATUS              PORTS                       IMAGE
n8n          Up 2 weeks          127.0.0.1:5678->5678/tcp    n8nio/n8n:latest
watchtower   Restarting (1)                                  containrrr/watchtower
hbbs         Up 2 months                                     rustdesk/rustdesk-server:latest
hbbr         Up 2 months                                     rustdesk/rustdesk-server:latest
npm          Up 3 months         0.0.0.0:80-81->80-81/tcp    jc21/nginx-proxy-manager:latest

 > Últimos Logins Anteriores:
ubuntu   pts/0    189.112.195.21   Mon Mar 10 16:35   still logged in
ubuntu   pts/0    189.112.195.21   Mon Mar 10 16:11 - 16:22  (00:11)
----------------------------------------------------------------
```

## 🔧 Customizações Adicionais

### Mostrar uso de disco

Adicione antes da linha divisória final:

```bash
# Uso de disco
echo -e "${BOLD}${GREEN} > Uso de Disco:${NC}"
df -h / | awk 'NR==2 {printf "   Root: %s de %s usado (%s)\n", $3, $2, $5}'
echo
```

### Mostrar uso de memória

```bash
# Uso de memória
echo -e "${BOLD}${MAGENTA} > Uso de Memória:${NC}"
free -h | awk 'NR==2 {printf "   RAM: %s de %s usado\n", $3, $2}'
echo
```

### Mostrar temperatura da CPU (se disponível)

```bash
# Temperatura
if command -v sensors &> /dev/null; then
    echo -e "${BOLD}${RED} > Temperatura:${NC}"
    sensors | grep "Core 0" | awk '{print "   CPU: " $3}'
    echo
fi
```

### Avisos de updates pendentes

```bash
# Updates disponíveis
echo -e "${BOLD}${YELLOW} > Sistema:${NC}"
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
if [ $UPDATES -gt 0 ]; then
    echo -e "   ${YELLOW}⚠${NC} $UPDATES pacotes podem ser atualizados"
else
    echo -e "   ${GREEN}✓${NC} Sistema atualizado"
fi
echo
```

## 🎨 Paleta de Cores Disponíveis

```bash
# Cores Normais
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

# Cores Brilhantes
BRIGHT_RED='\033[1;31m'
BRIGHT_GREEN='\033[1;32m'
BRIGHT_YELLOW='\033[1;33m'
BRIGHT_BLUE='\033[1;34m'
BRIGHT_MAGENTA='\033[1;35m'
BRIGHT_CYAN='\033[1;36m'
BRIGHT_WHITE='\033[1;37m'

# Formatação
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
REVERSE='\033[7m'
HIDDEN='\033[8m'

# Reset
NC='\033[0m'
```

## 🚫 Desabilitar Scripts de MOTD Padrão

Se quiser remover algumas mensagens padrão do Ubuntu:

```bash
# Remover permissões de execução de scripts indesejados
sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/50-motd-news
sudo chmod -x /etc/update-motd.d/91-contract-ua-esm-status
```

## 🔍 Troubleshooting

### Neofetch não aparece

```bash
# Verificar se está instalado
which neofetch

# Reinstalar se necessário
sudo apt install --reinstall neofetch
```

### Docker ps não mostra containers

O script precisa rodar como o usuário que tem permissão de usar Docker:

```bash
# Adicionar usuário ao grupo docker (se ainda não estiver)
sudo usermod -aG docker $USER

# Fazer logout e login novamente
```

### Script não executa

```bash
# Verificar permissões
ls -la /etc/update-motd.d/05-custom-welcome

# Deve mostrar: -rwxr-xr-x (executável)
# Se não estiver, corrigir:
sudo chmod +x /etc/update-motd.d/05-custom-welcome
```

## 📝 Scripts de MOTD Existentes

O Ubuntu vem com vários scripts em `/etc/update-motd.d/`:

```bash
00-header               # Header com nome do OS
10-help-text           # Texto de ajuda
50-landscape-sysinfo   # Informações do sistema
50-motd-news           # Notícias do Ubuntu
85-fwupd               # Updates de firmware
90-updates-available   # Pacotes disponíveis para atualizar
91-contract-ua-esm-status  # Status do Ubuntu Advantage
91-release-upgrade     # Avisos de nova versão
92-unattended-upgrades # Status de updates automáticos
95-hwe-eol             # Avisos de EOL do hardware enablement
97-overlayroot         # Status do overlayroot
98-fsck-at-reboot      # Aviso se precisa fsck
98-reboot-required     # Aviso se precisa reboot
```

Eles são executados em ordem numérica. Nosso `05-custom-welcome` executa antes de todos!

## 💡 Alternativas ao Neofetch

### Fastfetch (mais rápido)

```bash
# Instalar
sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
sudo apt update
sudo apt install fastfetch

# Usar no script
fastfetch
```

### Screenfetch

```bash
sudo apt install screenfetch
screenfetch
```

### ASCII Art Customizado (sem ferramentas)

```bash
cat << "EOF"
    ___                   _        
   /___\_ __ __ _  ___ __| | ___   
  //  // '__/ _` |/ __/ _` |/ _ \  
 / \_//| | | (_| | (_| (_| |  __/  
 \___/ |_|  \__,_|\___\__,_|\___|  
   ____  _                 _       
  / ___|| | ___  _   _  __| |      
 | |    | |/ _ \| | | |/ _` |      
 | |___ | | (_) | |_| | (_| |      
  \____||_|\___/ \__,_|\__,_|      
                                   
EOF
```

---

**Pro tip**: Execute `run-parts /etc/update-motd.d/` para ver como ficaria seu MOTD sem precisar fazer logout!
