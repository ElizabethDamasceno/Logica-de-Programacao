"""
Google Cloud Function para Processamento Automático do Consolidado Operacional

Esta função é executada automaticamente quando há atualizações na planilha
armazenada no Google Cloud Storage, processando os dados e gerando o consolidado.
"""

import functions_framework
from google.cloud import storage
from google.cloud import bigquery
import pandas as pd
import json
from datetime import datetime
import logging
import os
from consolidado_automatico import ConsolidadorOperacional

# Configuração de logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configurações do GCP
PROJECT_ID = os.environ.get('GCP_PROJECT_ID', 'seu-projeto-gcp')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'dados-operacionais')
DATASET_ID = os.environ.get('DATASET_ID', 'consolidado_operacional')
TABLE_PREFIX = os.environ.get('TABLE_PREFIX', 'dados_')

class ProcessadorGCP:
    """
    Classe para processar dados no ambiente GCP
    """
    
    def __init__(self):
        self.storage_client = storage.Client()
        self.bq_client = bigquery.Client()
        self.bucket = self.storage_client.bucket(BUCKET_NAME)
        
    def baixar_planilha_do_gcs(self, nome_arquivo: str) -> str:
        """
        Baixa a planilha do Google Cloud Storage
        
        Args:
            nome_arquivo: Nome do arquivo no GCS
            
        Returns:
            Caminho local do arquivo baixado
        """
        try:
            blob = self.bucket.blob(nome_arquivo)
            caminho_local = f"/tmp/{nome_arquivo}"
            blob.download_to_filename(caminho_local)
            logger.info(f"Planilha baixada: {caminho_local}")
            return caminho_local
        except Exception as e:
            logger.error(f"Erro ao baixar planilha: {e}")
            raise
            
    def criar_dataset_se_nao_existe(self):
        """
        Cria o dataset no BigQuery se não existir
        """
        try:
            dataset_ref = self.bq_client.dataset(DATASET_ID)
            try:
                self.bq_client.get_dataset(dataset_ref)
                logger.info(f"Dataset {DATASET_ID} já existe")
            except:
                dataset = bigquery.Dataset(dataset_ref)
                dataset.location = "US"  # ou sua região preferida
                dataset = self.bq_client.create_dataset(dataset)
                logger.info(f"Dataset {DATASET_ID} criado")
        except Exception as e:
            logger.error(f"Erro ao criar dataset: {e}")
            raise
            
    def carregar_dados_no_bigquery(self, dados_consolidados: dict):
        """
        Carrega os dados consolidados no BigQuery
        
        Args:
            dados_consolidados: Dados processados para carregar
        """
        try:
            self.criar_dataset_se_nao_existe()
            
            # Processa cada seção
            for secao, dados_secao in dados_consolidados.get('dados_por_secao', {}).items():
                if 'dados_mensais' in dados_secao and dados_secao['dados_mensais']:
                    
                    # Prepara DataFrame
                    df = pd.DataFrame(dados_secao['dados_mensais'])
                    
                    # Adiciona metadados
                    df['data_processamento'] = datetime.now()
                    df['versao_dados'] = dados_consolidados['metadados']['versao']
                    df['fonte_arquivo'] = dados_consolidados['metadados']['fonte']
                    
                    # Define nome da tabela
                    nome_tabela = f"{TABLE_PREFIX}{secao.lower()}"
                    table_ref = self.bq_client.dataset(DATASET_ID).table(nome_tabela)
                    
                    # Configuração do job de carregamento
                    job_config = bigquery.LoadJobConfig(
                        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,  # Substitui dados
                        autodetect=True
                    )
                    
                    # Carrega dados
                    job = self.bq_client.load_table_from_dataframe(
                        df, table_ref, job_config=job_config
                    )
                    job.result()  # Aguarda conclusão
                    
                    logger.info(f"Dados da seção {secao} carregados na tabela {nome_tabela}")
                    
            # Cria tabela de métricas consolidadas
            self._criar_tabela_metricas(dados_consolidados['metricas_consolidadas'])
            
        except Exception as e:
            logger.error(f"Erro ao carregar dados no BigQuery: {e}")
            raise
            
    def _criar_tabela_metricas(self, metricas: dict):
        """
        Cria tabela específica para métricas consolidadas
        
        Args:
            metricas: Dicionário com métricas calculadas
        """
        try:
            # Prepara dados das métricas
            dados_metricas = []
            
            # Métricas por mês
            for mes, dados_mes in metricas.get('resumo_mensal', {}).items():
                registro = {
                    'mes': mes,
                    'tipo_metrica': 'resumo_mensal',
                    'data_processamento': datetime.now()
                }
                registro.update(dados_mes)
                dados_metricas.append(registro)
                
            # Indicadores chave
            for indicador, valor in metricas.get('indicadores_chave', {}).items():
                dados_metricas.append({
                    'mes': 'CONSOLIDADO',
                    'tipo_metrica': 'indicador_chave',
                    'nome_indicador': indicador,
                    'valor': valor,
                    'data_processamento': datetime.now()
                })
                
            if dados_metricas:
                df_metricas = pd.DataFrame(dados_metricas)
                table_ref = self.bq_client.dataset(DATASET_ID).table(f"{TABLE_PREFIX}metricas")
                
                job_config = bigquery.LoadJobConfig(
                    write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
                    autodetect=True
                )
                
                job = self.bq_client.load_table_from_dataframe(
                    df_metricas, table_ref, job_config=job_config
                )
                job.result()
                
                logger.info("Tabela de métricas criada com sucesso")
                
        except Exception as e:
            logger.error(f"Erro ao criar tabela de métricas: {e}")
            
    def salvar_resultado_no_gcs(self, dados_consolidados: dict, nome_arquivo: str):
        """
        Salva o resultado processado de volta no GCS
        
        Args:
            dados_consolidados: Dados processados
            nome_arquivo: Nome do arquivo de saída
        """
        try:
            # Converte para JSON
            json_data = json.dumps(dados_consolidados, indent=2, ensure_ascii=False, default=str)
            
            # Upload para GCS
            blob = self.bucket.blob(f"consolidados/{nome_arquivo}")
            blob.upload_from_string(json_data, content_type='application/json')
            
            logger.info(f"Resultado salvo no GCS: gs://{BUCKET_NAME}/consolidados/{nome_arquivo}")
            
        except Exception as e:
            logger.error(f"Erro ao salvar no GCS: {e}")


@functions_framework.cloud_event
def processar_planilha_trigger(cloud_event):
    """
    Função principal acionada por eventos do Cloud Storage
    
    Args:
        cloud_event: Evento do Cloud Storage
    """
    try:
        # Extrai informações do evento
        data = cloud_event.data
        bucket_name = data['bucket']
        file_name = data['name']
        
        logger.info(f"Processando arquivo: gs://{bucket_name}/{file_name}")
        
        # Verifica se é um arquivo Excel
        if not file_name.endswith(('.xlsx', '.xls')):
            logger.info("Arquivo não é Excel, ignorando...")
            return
            
        # Inicializa processador GCP
        processador = ProcessadorGCP()
        
        # Baixa a planilha
        caminho_local = processador.baixar_planilha_do_gcs(file_name)
        
        # Processa dados
        consolidador = ConsolidadorOperacional(caminho_local)
        dados_consolidados = consolidador.processar_consolidado()
        
        # Carrega no BigQuery
        processador.carregar_dados_no_bigquery(dados_consolidados)
        
        # Salva resultado processado
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        arquivo_resultado = f"consolidado_{timestamp}.json"
        processador.salvar_resultado_no_gcs(dados_consolidados, arquivo_resultado)
        
        logger.info("✅ Processamento concluído com sucesso!")
        
        return {
            'status': 'sucesso',
            'arquivo_processado': file_name,
            'timestamp': datetime.now().isoformat(),
            'secoes_processadas': list(dados_consolidados['dados_por_secao'].keys()),
            'arquivo_resultado': f"gs://{BUCKET_NAME}/consolidados/{arquivo_resultado}"
        }
        
    except Exception as e:
        logger.error(f"❌ Erro durante o processamento: {e}")
        return {
            'status': 'erro',
            'erro': str(e),
            'timestamp': datetime.now().isoformat()
        }


@functions_framework.http
def processar_planilha_manual(request):
    """
    Endpoint HTTP para processamento manual
    
    Args:
        request: Requisição HTTP
        
    Returns:
        Resposta JSON com resultado do processamento
    """
    try:
        # Extrai parâmetros da requisição
        if request.method == 'POST':
            request_json = request.get_json(silent=True)
            nome_arquivo = request_json.get('arquivo') if request_json else None
        else:
            nome_arquivo = request.args.get('arquivo')
            
        if not nome_arquivo:
            return {
                'erro': 'Parâmetro "arquivo" é obrigatório',
                'exemplo': '{"arquivo": "planilha_operacional.xlsx"}'
            }, 400
            
        # Inicializa processador
        processador = ProcessadorGCP()
        
        # Baixa e processa
        caminho_local = processador.baixar_planilha_do_gcs(nome_arquivo)
        consolidador = ConsolidadorOperacional(caminho_local)
        dados_consolidados = consolidador.processar_consolidado()
        
        # Carrega no BigQuery
        processador.carregar_dados_no_bigquery(dados_consolidados)
        
        # Salva resultado
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        arquivo_resultado = f"consolidado_manual_{timestamp}.json"
        processador.salvar_resultado_no_gcs(dados_consolidados, arquivo_resultado)
        
        return {
            'status': 'sucesso',
            'mensagem': 'Planilha processada com sucesso',
            'secoes_processadas': list(dados_consolidados['dados_por_secao'].keys()),
            'arquivo_resultado': f"gs://{BUCKET_NAME}/consolidados/{arquivo_resultado}",
            'timestamp': datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Erro no processamento manual: {e}")
        return {
            'status': 'erro',
            'erro': str(e),
            'timestamp': datetime.now().isoformat()
        }, 500


if __name__ == "__main__":
    # Para testes locais
    print("Cloud Function para processamento de consolidado operacional")
    print("Deploy no GCP usando: gcloud functions deploy")