#!/bin/bash

# Script de Deploy para Google Cloud Platform
# Consolidado Operacional Automático

echo "🚀 Iniciando deploy do Consolidado Operacional no GCP..."

# Configurações do projeto
PROJECT_ID="seu-projeto-gcp"  # ALTERE AQUI
REGION="us-central1"  # ALTERE SE NECESSÁRIO
BUCKET_NAME="dados-operacionais"  # ALTERE AQUI
FUNCTION_NAME="consolidado-operacional"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para printar mensagens coloridas
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verifica se gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI não está instalado. Instale em: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Configura projeto
print_status "Configurando projeto GCP..."
gcloud config set project $PROJECT_ID

# Habilita APIs necessárias
print_status "Habilitando APIs necessárias..."
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable storage.googleapis.com  
gcloud services enable bigquery.googleapis.com
gcloud services enable eventarc.googleapis.com

# Cria bucket se não existir
print_status "Verificando/criando bucket de armazenamento..."
if ! gsutil ls gs://$BUCKET_NAME &> /dev/null; then
    gsutil mb gs://$BUCKET_NAME
    print_status "Bucket gs://$BUCKET_NAME criado"
else
    print_warning "Bucket gs://$BUCKET_NAME já existe"
fi

# Cria dataset no BigQuery se não existir
print_status "Verificando/criando dataset no BigQuery..."
if ! bq ls -d consolidado_operacional &> /dev/null; then
    bq mk --dataset $PROJECT_ID:consolidado_operacional
    print_status "Dataset consolidado_operacional criado"
else
    print_warning "Dataset consolidado_operacional já existe"
fi

# Deploy da Cloud Function (trigger por upload no Storage)
print_status "Fazendo deploy da Cloud Function (trigger automático)..."
gcloud functions deploy $FUNCTION_NAME-trigger \
    --runtime python311 \
    --source . \
    --entry-point processar_planilha_trigger \
    --trigger-bucket $BUCKET_NAME \
    --region $REGION \
    --memory 1024MB \
    --timeout 540s \
    --set-env-vars "GCP_PROJECT_ID=$PROJECT_ID,BUCKET_NAME=$BUCKET_NAME,DATASET_ID=consolidado_operacional,TABLE_PREFIX=dados_"

# Deploy da Cloud Function (HTTP para processamento manual)
print_status "Fazendo deploy da Cloud Function (endpoint HTTP)..."
gcloud functions deploy $FUNCTION_NAME-manual \
    --runtime python311 \
    --source . \
    --entry-point processar_planilha_manual \
    --trigger-http \
    --allow-unauthenticated \
    --region $REGION \
    --memory 1024MB \
    --timeout 540s \
    --set-env-vars "GCP_PROJECT_ID=$PROJECT_ID,BUCKET_NAME=$BUCKET_NAME,DATASET_ID=consolidado_operacional,TABLE_PREFIX=dados_"

# Obtém URL da função HTTP
FUNCTION_URL=$(gcloud functions describe $FUNCTION_NAME-manual --region=$REGION --format="value(httpsTrigger.url)")

print_status "Deploy concluído com sucesso! 🎉"
echo ""
echo "📋 Resumo da configuração:"
echo "   • Projeto: $PROJECT_ID"
echo "   • Bucket: gs://$BUCKET_NAME"
echo "   • Dataset BigQuery: consolidado_operacional"
echo "   • Região: $REGION"
echo ""
echo "🔧 Funções deployadas:"
echo "   • Trigger automático: $FUNCTION_NAME-trigger (ativada por upload no bucket)"
echo "   • Processamento manual: $FUNCTION_NAME-manual"
echo "   • URL manual: $FUNCTION_URL"
echo ""
echo "📖 Como usar:"
echo "   1. Upload automático: Faça upload da planilha para gs://$BUCKET_NAME"
echo "      gsutil cp planilha_operacional.xlsx gs://$BUCKET_NAME/"
echo ""
echo "   2. Processamento manual via HTTP:"
echo "      curl -X POST $FUNCTION_URL \\"
echo "           -H \"Content-Type: application/json\" \\"
echo "           -d '{\"arquivo\": \"planilha_operacional.xlsx\"}'"
echo ""
echo "📊 Verificar resultados no BigQuery:"
echo "   • Dataset: $PROJECT_ID.consolidado_operacional"
echo "   • Tabelas: dados_recursos_humanos, dados_biogas, dados_metricas"
echo ""
print_status "Setup completo! 🚀"