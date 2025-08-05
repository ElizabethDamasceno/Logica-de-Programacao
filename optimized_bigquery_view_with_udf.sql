-- Versão Super Otimizada da VIEW BigQuery com UDF JavaScript
-- Esta versão utiliza função personalizada para melhor performance e manutenibilidade

-- Primeiro, criar a função UDF (User Defined Function)
CREATE OR REPLACE FUNCTION `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(input_string STRING)
RETURNS FLOAT64
LANGUAGE js AS r"""
  if (!input_string || input_string === null || input_string === undefined) {
    return 0;
  }
  
  // Remove espaços, vírgulas, hífens, percentuais e converte vírgula para ponto
  var cleaned = input_string.toString()
    .trim()
    .replace(/[,]/g, '.')
    .replace(/[-]/g, '0')
    .replace(/[%\s]/g, '')
    .replace(/[^0-9.]/g, '')
    .replace(/\.+/g, '.');
  
  // Remove pontos extras no início e fim
  cleaned = cleaned.replace(/^\.+|\.+$/g, '');
  
  var result = parseFloat(cleaned);
  return isNaN(result) ? 0 : result;
""";

-- Agora criar a VIEW otimizada
CREATE OR REPLACE VIEW `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.00003_067_ve_brusque_indicadores_consolidado` AS

WITH 
-- Mapeamento de meses otimizado usando ARRAY e STRUCT
month_data AS (
  SELECT 
    mes_nome,
    mes_date
  FROM UNNEST([
    STRUCT('JANEIRO' AS mes_nome, DATE '2024-01-01' AS mes_date),
    ('FEVEREIRO', DATE '2024-02-01'),
    ('MARÇO', DATE '2024-03-01'),
    ('ABRIL', DATE '2024-04-01'),
    ('MAIO', DATE '2024-05-01'),
    ('JUNHO', DATE '2024-06-01'),
    ('JULHO', DATE '2024-07-01'),
    ('AGOSTO', DATE '2024-08-01'),
    ('SETEMBRO', DATE '2024-09-01'),
    ('OUTUBRO', DATE '2024-10-01'),
    ('NOVEMBRO', DATE '2024-11-01'),
    ('DEZEMBRO', DATE '2024-12-01')
  ])
),

-- Dados base com limpeza prévia
base_data AS (
  SELECT 
    *,
    UPPER(TRIM(COALESCE(SESMT_MES, ''))) AS mes_clean
  FROM `br-ist-ve-hubgrade.00002_hubgrade_tabelas_operacionais.00002_067_ve_brusque_indicadores_consolidado`
)

SELECT
  -- Mapeamento de mês usando LEFT JOIN para melhor performance
  COALESCE(md.mes_date, DATE '2024-01-01') AS MES,
  
  -- Aplicação da UDF para todos os campos numéricos
  -- SESMT Fields
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_META_A_M) AS SESMT_META_A_M,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_VISITAS_DE_SEGURANCA) AS SESMT_VISITAS_DE_SEGURANCA,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_VISITADOS) AS SESMT_VISITADOS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_SESMT) AS SESMT_SESMT,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_RH) AS SESMT_RH,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_BIOGAS) AS SESMT_BIOGAS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_MANUTENCAO) AS SESMT_MANUTENCAO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_ETE) AS SESMT_ETE,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_OPA) AS SESMT_OPA,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_ADM) AS SESMT_ADM,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_UTM) AS SESMT_UTM,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_BALANCA) AS SESMT_BALANCA,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_TRANSBORDO) AS SESMT_TRANSBORDO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_CTRSS) AS SESMT_CTRSS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_TOTAL) AS SESMT_TOTAL,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(SESMT_META_MENSAL) AS SESMT_META_MENSAL,
  
  -- RH Fields
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_ADMISSAO) AS RH_ADMISSAO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_ATIVOS) AS RH_ATIVOS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_TEMPORARIO) AS RH_TEMPORARIO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_AFASTADOS) AS RH_AFASTADOS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_ATESTADOS) AS RH_ATESTADOS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_HORAS_EXTRAS) AS RH_HORAS_EXTRAS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_ABSENTEISMO) AS RH_ABSENTEISMO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_DEMISSOES) AS RH_DEMISSOES,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_ENTREVISTAS) AS RH_ENTREVISTAS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_VAGAS) AS RH_VAGAS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(RH_TURNOVER) AS RH_TURNOVER,
  
  -- BIOGAS Fields  
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_BIOGAS_MEDIA_LATAM_NM3_H) AS BIOGAS_MEDIA_LATAM_NM3_H,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_BIOGAS_CAPTADO) AS BIOGAS_CAPTADO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_METANO_MEDIA_LATAM_NM3_H) AS METANO_MEDIA_LATAM_NM3_H,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_METANO_CAPTADO) AS METANO_CAPTADO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_METANO_MEDIA_LATAM_PERC) AS METANO_MEDIA_LATAM_PERC,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_METANO_MEDIA_REALIZADO_PERC) AS METANO_MEDIA_REALIZADO_PERC,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_PLANTA_VALOR_REAL_PERC) AS PLANTA_VALOR_REAL_PERC,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_PLANTA_VALOR_META_PERC) AS PLANTA_VALOR_META_PERC,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_BIOGAS_RESIDUO_RECEBIDO) AS BIOGAS_RESIDUO_RECEBIDO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_METANO_RESIDUO_RECEBIDO) AS METANO_RESIDUO_RECEBIDO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_POCOS_CONECTADOS_ATIVOS) AS POCOS_CONECTADOS_ATIVOS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_POCOS_DESCONECTADOS) AS POCOS_DESCONECTADOS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_NOVOS_POCOS) AS NOVOS_POCOS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_BIOGAS_TOTAL_NM3_ACUMULADO) AS BIOGAS_TOTAL_NM3_ACUMULADO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(BIOGAS_METANO_TOTAL_NM3_ACUMULADO) AS METANO_TOTAL_NM3_ACUMULADO,
  
  -- AUTOCLAVE Fields
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_META) AS AUTOCLAVE_META,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_RECEBIDO) AS AUTOCLAVE_RECEBIDO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_TRATADO) AS AUTOCLAVE_TRATADO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_TRATADO_PERC) AS AUTOCLAVE_TRATADO_PERC,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_DIESEL) AS AUTOCLAVE_DIESEL,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_AGUA) AS AUTOCLAVE_AGUA,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_CICLOS) AS AUTOCLAVE_CICLOS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_ENERGIA_ELETRICA) AS AUTOCLAVE_ENERGIA_ELETRICA,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_TEMPO_H) AS AUTOCLAVE_TEMPO_H,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_MEDIA_CICLOS) AS AUTOCLAVE_MEDIA_CICLOS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_UMIDADE) AS AUTOCLAVE_UMIDADE,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_RESIDUO_CICLO_KG) AS AUTOCLAVE_RESIDUO_CICLO_KG,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_META_RESIDUO_CICLO_KG) AS AUTOCLAVE_META_RESIDUO_CICLO_KG,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_MONITORAMENTO_BIOLOGICO) AS AUTOCLAVE_MONITORAMENTO_BIOLOGICO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(AUTOCLAVE_TESTE_CONFORMIDADE) AS AUTOCLAVE_TESTE_CONFORMIDADE,
  
  -- ATERRO Fields
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_META_TON) AS ATERRO_META_TON,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_RECEBIDO_TON) AS ATERRO_RECEBIDO_TON,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_SOLO_COBERTURA_TON) AS ATERRO_SOLO_COBERTURA_TON,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_BRITAS) AS ATERRO_BRITAS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_DIESEL) AS ATERRO_DIESEL,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_HORAS_TOTAL) AS ATERRO_HORAS_TOTAL,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_MAQUINAS_AMARELAS) AS ATERRO_MAQUINAS_AMARELAS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_META_AREA_EXPOSTA) AS ATERRO_META_AREA_EXPOSTA,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_AREA_EXPOSTA_M3) AS ATERRO_AREA_EXPOSTA_M3,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_SOLO_TON) AS ATERRO_SOLO_TON,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_META_SOLO_TON) AS ATERRO_META_SOLO_TON,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_BRITAS_TON) AS ATERRO_BRITAS_TON,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_DIESEL_TON) AS ATERRO_DIESEL_TON,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_HORAS_H) AS ATERRO_HORAS_H,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_AMARELAS_TON) AS ATERRO_AMARELAS_TON,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_DENSIDADE) AS ATERRO_DENSIDADE,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_META_DENSIDADE) AS ATERRO_META_DENSIDADE,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_FATOR_SEGURANCA_MACICO) AS ATERRO_FATOR_SEGURANCA_MACICO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ATERRO_META_FATOR_SEGURANCA_MACICO) AS ATERRO_META_FATOR_SEGURANCA_MACICO,
  
  -- MANUTENCAO Fields
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(MANUTENCAO_PREVENTIVA_PROJETADAS) AS MANUTENCAO_PREVENTIVA_PROJETADAS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(MANUTENCAO_PREVENTIVA_REALIZADAS) AS MANUTENCAO_PREVENTIVA_REALIZADAS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(MANUTENCAO_PREVENTIVA_CUSTO) AS MANUTENCAO_PREVENTIVA_CUSTO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(MANUTENCAO_PREVENTIVA_TEMPO_H) AS MANUTENCAO_PREVENTIVA_TEMPO_H,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(MANUTENCAO_CORRETIVAS_REALIZADAS) AS MANUTENCAO_CORRETIVAS_REALIZADAS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(MANUTENCAO_CORRETIVAS_CUSTO) AS MANUTENCAO_CORRETIVAS_CUSTO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(MANUTENCAO_CORRETIVAS_TEMPO_H) AS MANUTENCAO_CORRETIVAS_TEMPO_H,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(MANUTENCAO_ORDENS_GERADAS_EXECUTADAS) AS MANUTENCAO_ORDENS_GERADAS_EXECUTADAS,
  
  -- TRANSBORDO Fields
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(TRANSBORDO_BLUMENAU_RESIDUO_RECEBIDO) AS TRANSBORDO_BLUMENAU_RESIDUO_RECEBIDO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(TRANSBORDO_BLUMENAU_VIAGENS) AS TRANSBORDO_BLUMENAU_VIAGENS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(TRANSBORDO_BLUMENAU_MEDIA_VIAGENS) AS TRANSBORDO_BLUMENAU_MEDIA_VIAGENS,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(TRANSBORDO_BLUMENAU_INCIDENTES_CARGA_TORTA) AS TRANSBORDO_BLUMENAU_INCIDENTES_CARGA_TORTA,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(TRANSBORDO_BLUMENAU_TEMPO_MEDIO_DESCARGA) AS TRANSBORDO_BLUMENAU_TEMPO_MEDIO_DESCARGA,
  
  -- ESTACAO_TRATAMENTO Fields
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_VOLUME_TRATADO) AS ESTACAO_TRATAMENTO_VOLUME_TRATADO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_META_LIXIVIADO) AS ESTACAO_TRATAMENTO_META_LIXIVIADO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_LIXIVIADO_M3M) AS ESTACAO_TRATAMENTO_LIXIVIADO_M3M,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_RECEBIDO_EXT_M3M) AS ESTACAO_TRATAMENTO_RECEBIDO_EXT_M3M,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_TOTAL_REC_GERADO) AS ESTACAO_TRATAMENTO_TOTAL_REC_GERADO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_PLUVIOMETRIA_MM) AS ESTACAO_TRATAMENTO_PLUVIOMETRIA_MM,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_PLUVILIXIVIADO) AS ESTACAO_TRATAMENTO_PLUVILIXIVIADO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_REC_LIXIVIADO_M3T) AS ESTACAO_TRATAMENTO_REC_LIXIVIADO_M3T,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_AREA_EXPOSTA) AS ESTACAO_TRATAMENTO_AREA_EXPOSTA,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_ENERGIA_ELETRICA_KHW) AS ESTACAO_TRATAMENTO_ENERGIA_ELETRICA_KHW,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_AGUA_M3) AS ESTACAO_TRATAMENTO_AGUA_M3,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_MEDIA_DIARIA_M3D) AS ESTACAO_TRATAMENTO_MEDIA_DIARIA_M3D,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_VOLUME_LAGOA_M3) AS ESTACAO_TRATAMENTO_VOLUME_LAGOA_M3,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_META_VOLUME_LAGOA_M3) AS ESTACAO_TRATAMENTO_META_VOLUME_LAGOA_M3,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(ESTACAO_TRATAMENTO_VAZAO_HORA_M3H) AS ESTACAO_TRATAMENTO_VAZAO_HORA_M3H,
  
  -- CUSTOS_TRATAMENTO Fields
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_VOLUME_TRATADO) AS CUSTOS_TRATAMENTO_VOLUME_TRATADO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_TOTAL_CONSUMIDO_KGM) AS CUSTOS_TRATAMENTO_TOTAL_CONSUMIDO_KGM,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_SODA_CAUSTICA_KG) AS CUSTOS_TRATAMENTO_SODA_CAUSTICA_KG,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_PRECO_KG) AS CUSTOS_TRATAMENTO_PRECO_KG,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_CUSTO_TOTAL_SODA) AS CUSTOS_TRATAMENTO_CUSTO_TOTAL_SODA,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_SULFATO_ALUMINIO) AS CUSTOS_TRATAMENTO_SULFATO_ALUMINIO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_PRECO_KG_SULFATO) AS CUSTOS_TRATAMENTO_PRECO_KG_SULFATO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_CUSTO_SULFATO) AS CUSTOS_TRATAMENTO_CUSTO_SULFATO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_ANTI_ESPUMANTE) AS CUSTOS_TRATAMENTO_ANTI_ESPUMANTE,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_PRECO_KG_ANTI_ESPUMANTE) AS CUSTOS_TRATAMENTO_PRECO_KG_ANTI_ESPUMANTE,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_CUSTO_TOTAL_ANTI_ESPUMANTE) AS CUSTOS_TRATAMENTO_CUSTO_TOTAL_ANTI_ESPUMANTE,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_POLIMERO) AS CUSTOS_TRATAMENTO_POLIMERO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_PRECO_KG_POLIMERO) AS CUSTOS_TRATAMENTO_PRECO_KG_POLIMERO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_CUSTO_TOTAL_POLIMERO) AS CUSTOS_TRATAMENTO_CUSTO_TOTAL_POLIMERO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_M3_SODA) AS CUSTOS_TRATAMENTO_M3_SODA,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_M3_SULFATO) AS CUSTOS_TRATAMENTO_M3_SULFATO,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_M3_ESPUMANTE) AS CUSTOS_TRATAMENTO_M3_ESPUMANTE,
  `br-ist-ve-hubgrade.00003_hubgrade_views_operacionais.CLEAN_NUMERIC_STRING`(CUSTOS_TRATAMENTO_M3_POLIMERO) AS CUSTOS_TRATAMENTO_M3_POLIMERO

FROM base_data bd
LEFT JOIN month_data md ON bd.mes_clean = md.mes_nome;