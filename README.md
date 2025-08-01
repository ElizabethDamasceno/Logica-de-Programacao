# 📊 Sistema de Consolidado Operacional Automático

Sistema automatizado para processamento de dados operacionais de múltiplos setores (SESMET, RH, Biogás, Autoclave, Operação de Aterro) com integração ao Google Cloud Platform.

## 🎯 Visão Geral

Este sistema foi desenvolvido para automatizar o processamento de planilhas Excel contendo dados operacionais de diferentes setores, transformando informações dispersas em um consolidado estruturado e disponível em tempo real no BigQuery.

### ✨ Funcionalidades Principais

- **Processamento Automático**: Detecta e processa automaticamente planilhas enviadas ao Cloud Storage
- **Múltiplas Seções**: Suporte para SESMET, RH, Biogás, Autoclave e Operação de Aterro
- **Validação de Dados**: Validação automática e tratamento de inconsistências
- **Métricas Consolidadas**: Cálculo automático de KPIs e indicadores
- **Integração GCP**: Deploy automático com Cloud Functions e BigQuery
- **Alertas Inteligentes**: Sistema de alertas baseado em thresholds configuráveis

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Planilha Excel │───▶│  Cloud Storage   │───▶│ Cloud Function  │
│   (Múltiplas    │    │   (Trigger)      │    │  (Processamento)│
│    Seções)      │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                                                         ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Dashboard     │◀───│    BigQuery      │◀───│ Dados Estrutu-  │
│   (Opcional)    │    │   (Data Warehouse│    │ rados + Métricas│
│                 │    │    + Analytics)  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📦 Componentes do Sistema

### 1. `consolidado_automatico.py`
Módulo principal para processamento de dados:
- Identificação automática de seções na planilha
- Extração e estruturação de dados por setor
- Cálculo de métricas consolidadas
- Validação e tratamento de dados

### 2. `gcp_cloud_function.py`
Cloud Function para integração com GCP:
- Trigger automático por upload no Storage
- Endpoint HTTP para processamento manual
- Integração com BigQuery
- Gerenciamento de logs e erros

### 3. `template_configuracao.json`
Configurações centralizadas:
- Definição de estruturas por setor
- Parâmetros de validação
- Thresholds para alertas
- Schemas do BigQuery

## 🚀 Como Usar

### Pré-requisitos

1. **Conta Google Cloud Platform** com APIs habilitadas:
   - Cloud Functions
   - Cloud Storage
   - BigQuery
   - Eventarc

2. **gcloud CLI** instalado e configurado
3. **Python 3.11+** (para desenvolvimento local)

### Instalação e Deploy

1. **Clone o repositório e configure o projeto:**
   ```bash
   # Edite o arquivo deploy_gcp.sh com suas configurações
   nano deploy_gcp.sh
   
   # Configure PROJECT_ID, BUCKET_NAME, etc.
   ```

2. **Execute o deploy automático:**
   ```bash
   chmod +x deploy_gcp.sh
   ./deploy_gcp.sh
   ```

3. **O script irá:**
   - Habilitar APIs necessárias
   - Criar bucket de armazenamento
   - Criar dataset no BigQuery  
   - Fazer deploy das Cloud Functions
   - Configurar triggers automáticos

### Uso do Sistema

#### 🔄 Processamento Automático
```bash
# Faça upload da planilha para o bucket
gsutil cp planilha_operacional.xlsx gs://dados-operacionais/

# O sistema processará automaticamente e carregará no BigQuery
```

#### 🛠️ Processamento Manual
```bash
# Via API REST
curl -X POST https://REGION-PROJECT.cloudfunctions.net/consolidado-operacional-manual \
     -H "Content-Type: application/json" \
     -d '{"arquivo": "planilha_operacional.xlsx"}'
```

#### 📊 Consultar Resultados
```sql
-- No BigQuery, consulte as tabelas criadas:
SELECT * FROM `projeto.consolidado_operacional.dados_recursos_humanos`
WHERE mes = 'JUNHO';

SELECT * FROM `projeto.consolidado_operacional.dados_biogas` 
WHERE captado > 1500;

-- Métricas consolidadas
SELECT * FROM `projeto.consolidado_operacional.dados_metricas`
WHERE tipo_metrica = 'indicador_chave';
```

## 📊 Estrutura de Dados

### Seções Suportadas

#### 🏢 **Recursos Humanos**
- Admissões, demissões, funcionários ativos
- Absenteísmo, turnover, horas extras
- Entrevistas, vagas, temporários

#### ⛽ **Biogás**
- Captação de biogás e metano
- Performance vs metas
- Eficiência da planta
- Número de poços ativos

#### 🛡️ **SESMET**
- Acidentes e incidentes
- Treinamentos de segurança
- Auditorias e não conformidades
- Taxas de frequência e gravidade

#### 🔧 **Autoclave**
- Volume de resíduos tratados
- Eficiência energética
- Disponibilidade do equipamento
- Manutenções preventivas/corretivas

#### 🏭 **Operação de Aterro**
- Solo depositado e área exposta
- Consumo de diesel e britas
- Horas de operação de máquinas
- Indicadores ambientais

## ⚙️ Configuração Avançada

### Personalizar Validações

Edite `template_configuracao.json` para:
- Adicionar novos setores
- Modificar validações de dados
- Ajustar thresholds de alertas
- Definir novos campos

### Alertas Personalizados

```python
# Exemplo de configuração de alerta no template
"BIOGAS": {
  "eficiencia_captacao_min": 45.0,  # Alerta se < 45%
  "disponibilidade_planta_min": 95.0,  # Alerta se < 95%
  "variacao_producao_max": 20.0  # Alerta se variação > 20%
}
```

### Desenvolvimento Local

```bash
# Instale dependências
pip install -r requirements.txt

# Execute localmente
python consolidado_automatico.py

# Teste com planilha de exemplo
python -c "
from consolidado_automatico import ConsolidadorOperacional
consolidador = ConsolidadorOperacional('planilha_teste.xlsx')
resultado = consolidador.processar_consolidado()
print('Seções processadas:', list(resultado['dados_por_secao'].keys()))
"
```

## 📈 Métricas e KPIs Calculados

### 📊 **KPIs Automáticos por Setor**

| Setor | Métricas Principais |
|-------|-------------------|
| **RH** | Taxa de Rotatividade, Índice de Absenteísmo, Eficiência de Recrutamento |
| **Biogás** | Eficiência de Captação, Performance vs Meta, Produtividade por Poço |
| **SESMET** | Taxa de Acidentes, Eficiência de Treinamentos, Cumprimento de Auditorias |
| **Autoclave** | Disponibilidade, Eficiência de Tratamento, Custo Energético |
| **Aterro** | Eficiência de Cobertura, Produtividade de Máquinas, Cumprimento Ambiental |

### 🎯 **Indicadores Consolidados**
- Resumo mensal cross-setorial
- Tendências de performance
- Alertas de desvio de metas
- Correlações entre setores

## 🔧 Troubleshooting

### Problemas Comuns

1. **Planilha não processada:**
   ```bash
   # Verifique logs da Cloud Function
   gcloud functions logs read consolidado-operacional-trigger --region=us-central1
   ```

2. **Dados não aparecem no BigQuery:**
   ```bash
   # Verifique permissões do dataset
   bq show consolidado_operacional
   ```

3. **Erro de schema:**
   ```bash
   # Force recriação das tabelas
   bq rm -f -t projeto:consolidado_operacional.dados_recursos_humanos
   ```

### Logs e Monitoramento

- **Cloud Functions Logs**: Console GCP > Cloud Functions > Logs
- **BigQuery Jobs**: Console GCP > BigQuery > Job History  
- **Storage Events**: Console GCP > Cloud Storage > Logs

## 🔐 Segurança e Permissões

### IAM Roles Necessárias

- `Cloud Functions Developer`
- `Storage Admin` (para o bucket)
- `BigQuery Admin` (para o dataset)
- `Eventarc Admin` (para triggers)

### Boas Práticas

- Use service accounts específicas para produção
- Configure VPC para funções sensíveis
- Implemente audit logs para compliance
- Use Cloud KMS para dados sensíveis

## 📚 Recursos Adicionais

### Links Úteis
- [Documentação Cloud Functions](https://cloud.google.com/functions/docs)
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices)
- [Cloud Storage Triggers](https://cloud.google.com/functions/docs/calling/storage)

### Exemplos de Consultas SQL

```sql
-- Análise mensal de performance
WITH monthly_performance AS (
  SELECT 
    rh.mes,
    rh.ativos as funcionarios,
    bg.captado as biogas_captado,
    bg.eficiencia_captacao
  FROM `projeto.consolidado_operacional.dados_recursos_humanos` rh
  LEFT JOIN `projeto.consolidado_operacional.dados_biogas` bg 
    ON rh.mes = bg.mes
)
SELECT * FROM monthly_performance
WHERE mes IN ('MAIO', 'JUNHO')
ORDER BY mes;

-- Alertas de performance
SELECT 
  secao,
  mes,
  nome_indicador,
  valor,
  CASE 
    WHEN valor < threshold THEN 'ALERTA'
    ELSE 'OK'
  END as status
FROM performance_indicators
WHERE data_processamento >= CURRENT_DATE() - 30;
```

## 📞 Suporte

Para dúvidas, problemas ou sugestões:

1. **Issues**: Abra uma issue no repositório
2. **Documentação**: Consulte este README
3. **Logs**: Verifique logs das Cloud Functions
4. **Community**: Fórum Google Cloud Platform

---

🔥 **Sistema desenvolvido para automação completa do consolidado operacional!** 

Processamento inteligente • Integração cloud-native • Métricas em tempo real