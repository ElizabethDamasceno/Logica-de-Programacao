#!/usr/bin/env python3
"""
Sistema de Consolidado Automático - Planilha Operacional
Autor: Assistant
Data: 2024

Este script processa dados de uma planilha Excel com múltiplas seções 
(SESMET, RH, Autoclave, Biogas) e gera um consolidado automatizado.
"""

import pandas as pd
import numpy as np
from datetime import datetime, date
import logging
from typing import Dict, List, Any, Optional
import json
import os

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class ConsolidadorOperacional:
    """
    Classe principal para consolidação automática de dados operacionais
    """
    
    def __init__(self, arquivo_origem: str):
        """
        Inicializa o consolidador
        
        Args:
            arquivo_origem: Caminho para o arquivo Excel original
        """
        self.arquivo_origem = arquivo_origem
        self.dados_consolidados = {}
        self.metadados = {
            'ultima_atualizacao': datetime.now().isoformat(),
            'versao': '1.0.0',
            'fonte': arquivo_origem
        }
        
    def carregar_dados(self) -> pd.DataFrame:
        """
        Carrega dados da planilha Excel
        
        Returns:
            DataFrame com os dados carregados
        """
        try:
            # Carrega a planilha (assumindo que está na primeira aba)
            df = pd.read_excel(self.arquivo_origem, sheet_name=0, header=None)
            logger.info(f"Dados carregados: {df.shape[0]} linhas, {df.shape[1]} colunas")
            return df
        except Exception as e:
            logger.error(f"Erro ao carregar dados: {e}")
            raise
            
    def identificar_secoes(self, df: pd.DataFrame) -> Dict[str, Dict]:
        """
        Identifica as diferentes seções na planilha
        
        Args:
            df: DataFrame com os dados
            
        Returns:
            Dicionário com informações das seções encontradas
        """
        secoes = {}
        
        # Palavras-chave para identificar seções
        palavras_chave = {
            'SESMET': ['SESMET', 'SEGURANÇA'],
            'RH': ['RECURSOS HUMANOS', 'ADMISSÃO', 'ATIVOS'],
            'BIOGAS': ['BIOGÁS', 'CAPTAÇÃO', 'METANO'],
            'AUTOCLAVE': ['AUTOCLAVE', 'TRATAMENTO'],
            'OPERACAO_ATERRO': ['OPERAÇÃO DO ATERRO', 'ATERRO']
        }
        
        for idx, row in df.iterrows():
            # Converte a linha para string para busca
            linha_texto = ' '.join([str(cell) for cell in row if pd.notna(cell)]).upper()
            
            for secao, keywords in palavras_chave.items():
                if any(keyword in linha_texto for keyword in keywords):
                    secoes[secao] = {
                        'linha_inicio': idx,
                        'identificador': linha_texto[:50],
                        'encontrado_em': datetime.now().isoformat()
                    }
                    logger.info(f"Seção {secao} encontrada na linha {idx}")
                    
        return secoes
        
    def processar_secao_rh(self, df: pd.DataFrame, linha_inicio: int) -> Dict:
        """
        Processa especificamente a seção de Recursos Humanos
        
        Args:
            df: DataFrame com os dados
            linha_inicio: Linha onde começa a seção RH
            
        Returns:
            Dados estruturados da seção RH
        """
        dados_rh = {
            'secao': 'RECURSOS_HUMANOS',
            'dados_mensais': [],
            'totais': {},
            'metricas': {}
        }
        
        # Define as colunas esperadas para RH
        colunas_rh = [
            'MES', 'ADMISSAO', 'ATIVOS', 'TEMPORARIO', 'AFASTADOS', 
            'ATESTADOS', 'HORAS_EXTRAS', 'ABSENTEISMO', 'DEMISSOES', 
            'ENTREVISTAS', 'VAGAS', 'TURN_OVER_ACUM'
        ]
        
        try:
            # Busca dados linha por linha a partir da linha de início
            for i in range(linha_inicio + 2, min(linha_inicio + 15, len(df))):
                linha = df.iloc[i]
                
                # Verifica se é uma linha de dados (tem o nome do mês)
                if pd.notna(linha.iloc[0]) and isinstance(linha.iloc[0], str):
                    mes = linha.iloc[0].strip().upper()
                    
                    # Pula linhas vazias ou totais
                    if mes in ['', 'TOTAL', 'TOTAIS']:
                        continue
                        
                    # Processa dados do mês
                    dados_mes = {'mes': mes}
                    for j, coluna in enumerate(colunas_rh[1:], start=1):
                        if j < len(linha) and pd.notna(linha.iloc[j]):
                            dados_mes[coluna] = linha.iloc[j]
                        else:
                            dados_mes[coluna] = None
                            
                    dados_rh['dados_mensais'].append(dados_mes)
                    
        except Exception as e:
            logger.error(f"Erro ao processar seção RH: {e}")
            
        return dados_rh
        
    def processar_secao_biogas(self, df: pd.DataFrame, linha_inicio: int) -> Dict:
        """
        Processa especificamente a seção de Biogás
        
        Args:
            df: DataFrame com os dados
            linha_inicio: Linha onde começa a seção Biogás
            
        Returns:
            Dados estruturados da seção Biogás
        """
        dados_biogas = {
            'secao': 'BIOGAS',
            'dados_mensais': [],
            'metricas_consolidadas': {}
        }
        
        colunas_biogas = [
            'MES', 'MEDIA_LATAM_NM3_H', 'CAPTADO', 'MEDIA_LATAM_METANO',
            'CAPTADO_METANO', 'MEDIA_LATAM_PERC', 'MEDIA_PERC_REALIZADA',
            'REAL', 'META', 'BIOGAS_RESIDUO_RECEBIDO', 'METANO_RESIDUOS',
            'POCOS_CONECTADOS', 'NOVOS_POCOS', 'BIOGAS_TOTAL_ACUM',
            'CH4_TOTAL_ACUM'
        ]
        
        try:
            for i in range(linha_inicio + 2, min(linha_inicio + 15, len(df))):
                linha = df.iloc[i]
                
                if pd.notna(linha.iloc[0]) and isinstance(linha.iloc[0], str):
                    mes = linha.iloc[0].strip().upper()
                    
                    if mes in ['', 'TOTAL', 'TOTAIS']:
                        continue
                        
                    dados_mes = {'mes': mes}
                    for j, coluna in enumerate(colunas_biogas[1:], start=1):
                        if j < len(linha):
                            valor = linha.iloc[j]
                            # Trata valores especiais
                            if pd.notna(valor) and str(valor) != '#DIV/0!':
                                dados_mes[coluna] = valor
                            else:
                                dados_mes[coluna] = None
                                
                    dados_biogas['dados_mensais'].append(dados_mes)
                    
        except Exception as e:
            logger.error(f"Erro ao processar seção Biogás: {e}")
            
        return dados_biogas
        
    def calcular_metricas_consolidadas(self) -> Dict:
        """
        Calcula métricas consolidadas entre todas as seções
        
        Returns:
            Dicionário com métricas consolidadas
        """
        metricas = {
            'resumo_mensal': {},
            'indicadores_chave': {},
            'alertas': []
        }
        
        # Exemplo de métricas consolidadas
        try:
            # Calcula total de funcionários por mês (se dados RH disponíveis)
            if 'RECURSOS_HUMANOS' in self.dados_consolidados:
                rh_data = self.dados_consolidados['RECURSOS_HUMANOS']
                for dados_mes in rh_data.get('dados_mensais', []):
                    mes = dados_mes['mes']
                    if mes not in metricas['resumo_mensal']:
                        metricas['resumo_mensal'][mes] = {}
                    
                    if dados_mes.get('ATIVOS'):
                        metricas['resumo_mensal'][mes]['funcionarios_ativos'] = dados_mes['ATIVOS']
                        
            # Calcula produção de biogás (se dados disponíveis)
            if 'BIOGAS' in self.dados_consolidados:
                biogas_data = self.dados_consolidados['BIOGAS']
                total_biogas = 0
                for dados_mes in biogas_data.get('dados_mensais', []):
                    if dados_mes.get('BIOGAS_TOTAL_ACUM'):
                        total_biogas = max(total_biogas, dados_mes['BIOGAS_TOTAL_ACUM'] or 0)
                        
                metricas['indicadores_chave']['total_biogas_acumulado'] = total_biogas
                
        except Exception as e:
            logger.error(f"Erro ao calcular métricas: {e}")
            
        return metricas
        
    def processar_consolidado(self) -> Dict:
        """
        Processa todo o consolidado automaticamente
        
        Returns:
            Dados consolidados estruturados
        """
        logger.info("Iniciando processamento do consolidado...")
        
        # Carrega dados
        df = self.carregar_dados()
        
        # Identifica seções
        secoes = self.identificar_secoes(df)
        logger.info(f"Seções identificadas: {list(secoes.keys())}")
        
        # Processa cada seção
        if 'RH' in secoes:
            self.dados_consolidados['RECURSOS_HUMANOS'] = self.processar_secao_rh(
                df, secoes['RH']['linha_inicio']
            )
            
        if 'BIOGAS' in secoes:
            self.dados_consolidados['BIOGAS'] = self.processar_secao_biogas(
                df, secoes['BIOGAS']['linha_inicio']
            )
            
        # Calcula métricas consolidadas
        metricas = self.calcular_metricas_consolidadas()
        
        # Monta resultado final
        resultado = {
            'metadados': self.metadados,
            'secoes_identificadas': secoes,
            'dados_por_secao': self.dados_consolidados,
            'metricas_consolidadas': metricas,
            'status': 'sucesso',
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info("Processamento concluído com sucesso!")
        return resultado
        
    def exportar_json(self, dados: Dict, arquivo_saida: str):
        """
        Exporta dados consolidados para JSON
        
        Args:
            dados: Dados consolidados
            arquivo_saida: Caminho do arquivo de saída
        """
        try:
            with open(arquivo_saida, 'w', encoding='utf-8') as f:
                json.dump(dados, f, indent=2, ensure_ascii=False, default=str)
            logger.info(f"Dados exportados para: {arquivo_saida}")
        except Exception as e:
            logger.error(f"Erro ao exportar JSON: {e}")
            
    def exportar_csv_por_secao(self, dados: Dict, pasta_saida: str):
        """
        Exporta cada seção como um arquivo CSV separado
        
        Args:
            dados: Dados consolidados
            pasta_saida: Pasta onde salvar os CSVs
        """
        try:
            os.makedirs(pasta_saida, exist_ok=True)
            
            for secao, dados_secao in dados.get('dados_por_secao', {}).items():
                if 'dados_mensais' in dados_secao:
                    df_secao = pd.DataFrame(dados_secao['dados_mensais'])
                    arquivo_csv = os.path.join(pasta_saida, f"{secao.lower()}.csv")
                    df_secao.to_csv(arquivo_csv, index=False, encoding='utf-8')
                    logger.info(f"CSV da seção {secao} salvo em: {arquivo_csv}")
                    
        except Exception as e:
            logger.error(f"Erro ao exportar CSVs: {e}")


def main():
    """
    Função principal para execução do script
    """
    # Exemplo de uso
    arquivo_excel = "planilha_operacional.xlsx"  # Substitua pelo caminho real
    
    try:
        # Inicializa o consolidador
        consolidador = ConsolidadorOperacional(arquivo_excel)
        
        # Processa dados
        dados_consolidados = consolidador.processar_consolidado()
        
        # Exporta resultados
        consolidador.exportar_json(dados_consolidados, "consolidado_operacional.json")
        consolidador.exportar_csv_por_secao(dados_consolidados, "dados_csv")
        
        print("✅ Consolidado processado com sucesso!")
        print(f"📊 Seções processadas: {list(dados_consolidados['dados_por_secao'].keys())}")
        
    except FileNotFoundError:
        print(f"❌ Arquivo não encontrado: {arquivo_excel}")
        print("💡 Certifique-se de que o arquivo Excel está no caminho correto")
    except Exception as e:
        print(f"❌ Erro durante o processamento: {e}")


if __name__ == "__main__":
    main()