# 💰 Alertas de Cobrança (Budget Alerts)

Guia para configurar alertas de email se a Oracle Cloud começar a cobrar algo.

## ⚠️ Por que isso é importante?

Mesmo no Always Free Tier, você pode ser cobrado se:
- Exceder os limites gratuitos (10TB bandwidth, 200GB storage, etc)
- Criar recursos fora do Always Free
- Fazer upgrade acidental para Pay-As-You-Go

**Solução**: Configure alertas para te avisar **ANTES** de qualquer cobrança!

## 🚀 Configurar Budget Alert (Recomendado!)

### 1. Acessar Budgets

Oracle Console → Menu (☰) → **Billing & Cost Management** → **Budgets**

Ou acesse direto: https://cloud.oracle.com/cost-management/budgets

### 2. Criar Budget

Clique em **Create Budget**

**Name**: `Always-Free-Alert` (ou qualquer nome criativo!)

💡 **Dica**: Use nomes que te motivem a agir rápido. Exemplos:
- "SE-FUDEU" (clássico brasileiro)
- "CANCELA-TUDO"
- "APAGA-GERAL"
- "911-ORACLE"

**Target Compartment**: Selecione seu compartment (geralmente o root/tenancy)

**Budget Amount**: `0.50` (meio dólar - qualquer cobrança acima de 50 centavos te alerta)

**Reset Period**: `Monthly` (reseta todo mês)

**Processing**: `Invoice`

### 3. Configurar Alert

**Alert Rule 1 - Forecast (Previsto)**:
- **Threshold Metric**: `Forecast Spend`
- **Threshold Type**: `Percentage`
- **Threshold**: `100%` (ou seja, se previr gastar $0.50)
- **Email Recipients**: `seu-email@gmail.com`
- **Message**: (seja criativo!)
  ```
  ⚠️ ALERTA: Oracle Cloud está prevendo gastos!
  Verifique seus recursos imediatamente.
  ```
  
  Ou algo mais... motivador:
  ```
  🔥 O valor passou de 5 real, cancela tudooo!
  ```

**Alert Rule 2 - Gasto Real**:
- **Threshold Metric**: `Actual Spend`
- **Threshold Type**: `Percentage`
- **Threshold**: `80%` (ou seja, se gastar $0.40)
- **Email Recipients**: `seu-email@gmail.com`
- **Message**:
  ```
  🚨 CRÍTICO: Você está sendo cobrado na Oracle Cloud!
  Gasto: $0.40 de $0.50
  Verifique AGORA o que está consumindo recursos.
  ```

**Alert Rule 3 - Urgente**:
- **Threshold Metric**: `Actual Spend`
- **Threshold Type**: `Percentage`
- **Threshold**: `100%` (gastou $0.50 ou mais)
- **Email Recipients**: `seu-email@gmail.com`
- **Message**:
  ```
  🔴 URGENTE: Cobrança confirmada na Oracle Cloud!
  Você ultrapassou $0.50
  DELETE recursos não essenciais IMEDIATAMENTE!
  ```

### 4. Salvar

Clique em **Create** e pronto!

## 📧 Testando os Alertas

Oracle envia emails automáticos:
- Diariamente com previsão de gastos
- Imediatamente quando atingir thresholds

**Primeiro email**: Pode demorar até 24h

**Subject do email**: `OCI Budget Alert: [Nome do Budget]`

## 🔍 Verificar Budget Existente

Se você já criou mas não lembra:

1. Console → **Budgets**
2. Você verá todos os budgets ativos
3. Clique no nome para ver/editar configurações

## 📊 Monitorar Gastos Atuais

### Via Console

**Cost Analysis**:
- Menu → **Billing & Cost Management** → **Cost Analysis**
- Veja gráficos de custos diários/mensais

**Usage Report**:
- Menu → **Billing & Cost Management** → **Usage**
- Detalhamento por serviço

### Via CLI

Se configurou Oracle CLI (veja guia principal):

```bash
# Ativar venv
source /opt/oracle-cli-venv/bin/activate

# Ver gastos do mês
oci usage-api usage-summary list-usage \
  --tenant-id SEU_TENANCY_OCID \
  --time-usage-started $(date -d "$(date +%Y-%m-01)" '+%Y-%m-%dT00:00:00Z') \
  --time-usage-ended $(date '+%Y-%m-%dT23:59:59Z') \
  --granularity DAILY
```

## 🛡️ Proteções Adicionais

### 1. Billing Address

Certifique-se de que seu billing address está correto para receber invoices.

**Console** → **Account Management** → **Billing Information**

### 2. Payment Method

Verifique que tem um cartão válido cadastrado.

**Console** → **Account Management** → **Payment Methods**

### 3. Spending Limit

**⚠️ IMPORTANTE**: 

Se sua conta é **Always Free Only**: Oracle NÃO cobra, mesmo se exceder limites (apenas bloqueia recursos).

Se você fez **Upgrade to Pay-As-You-Go**: Pode ser cobrado!

**Verificar seu tipo de conta**:
Console → **Account Management** → **Account Settings**

### 4. Service Limits (Opcional)

Para evitar criar recursos acidentalmente:

Console → **Governance & Administration** → **Service Limits**

Pode configurar limits para:
- Compute instances
- Block volumes
- Object storage buckets

## 📋 Checklist de Segurança Financeira

- [ ] Budget configurado com alertas
- [ ] Email de alerta testado e funcionando
- [ ] Tipo de conta verificado (Always Free Only ou PAYG)
- [ ] Payment method válido cadastrado
- [ ] Monitora Cost Analysis semanalmente
- [ ] Scripts de monitoramento rodando (deste guia)
- [ ] Backup dos recursos importantes

## 🚨 O que fazer se receber alerta de cobrança

### Passo 1: NÃO ENTRE EM PÂNICO

Às vezes são centavos por testes ou recursos temporários.

### Passo 2: Verificar o que está gastando

Console → **Cost Analysis** → Filtre por serviço

### Passo 3: Identificar culpado

Serviços mais comuns que cobram:
- ❌ Compute instances fora do Always Free
- ❌ Block storage > 200GB
- ❌ Bandwidth > 10TB/mês
- ❌ Load balancers (NÃO são gratuitos)
- ❌ Backups automáticos (alguns tipos)
- ❌ Object storage > 20GB

### Passo 4: Deletar recursos desnecessários

**Compute**:
```bash
# Via console
Console → Compute → Instances → Terminate

# Via CLI
oci compute instance terminate --instance-id INSTANCE_OCID --force
```

**Block Volumes**:
```bash
Console → Block Storage → Block Volumes → Terminate
```

**Load Balancers** (caro!):
```bash
Console → Networking → Load Balancers → Delete
```

### Passo 5: Contestar cobrança (se necessário)

Se foi erro ou cobrança indevida:

1. **Support Ticket**: Console → Help → Create Support Request
2. **Chat**: Live chat no console (canto inferior direito)
3. **Email**: oracle-cloud-infrastructure_us@oracle.com

**Template de email**:
```
Subject: Unexpected Charges on Always Free Account

Hello Oracle Support,

I have an Always Free account (Tenancy OCID: SEU_OCID) and 
received an unexpected charge of $X.XX on [DATE].

I believe this is an error because [REASON - ex: I only use 
Always Free resources].

Could you please review and reverse this charge?

Account details:
- Username: [SEU_USER]
- Tenancy OCID: [SEU_TENANCY]
- Invoice Number: [SE_TIVER]

Thank you.
```

## 💡 Dicas para Evitar Cobranças

1. **Sempre use Shape Always Free**:
   - `VM.Standard.A1.Flex` (Ampere A1)
   - Máximo: 4 OCPUs + 24GB RAM total

2. **Não crie Load Balancers**:
   - Use Nginx Proxy Manager (incluído neste guia)
   - Load Balancers da Oracle custam ~$15/mês

3. **Cuidado com Block Volumes**:
   - Limite: 200GB total
   - Delete volumes de instâncias deletadas
   - Use script de monitoramento (storage_monitor.sh)

4. **Bandwidth**:
   - Limite: 10TB/mês
   - Principalmente saída (outbound)
   - Use script bandwidth_monitor.sh

5. **Object Storage**:
   - Limite: 20GB
   - Delete backups antigos regularmente

## 📖 Links Úteis

- [Oracle Free Tier FAQ](https://www.oracle.com/cloud/free/faq.html)
- [Always Free Services](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [Cost Management](https://docs.oracle.com/en-us/iaas/Content/Billing/home.htm)

## 🆘 Precisa de Ajuda?

Veja também:
- [FAQ.md](FAQ.md) - Perguntas sobre Always Free
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Resolução de problemas

---

**💡 Dica Final**: Configure o budget alert HOJE. É rápido (2 minutos) e te salva de surpresas na fatura! 

**🔒 Tranquilidade**: Com monitoramento (scripts deste guia) + budget alerts + Always Free Only account = praticamente impossível ser cobrado.
