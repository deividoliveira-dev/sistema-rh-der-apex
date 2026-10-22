--------------------------------------------------------------------------------
-- SISTEMA RH - DER
-- Consultas usadas nas regiões das páginas do APEX (referência, não é para executar)
-- Cada bloco indica a página e a região onde a consulta é colada no Page Designer.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Página 1 (Home) - região "Indicadores" (Cards)
-- Os links usam o caminho do app: ajuste /ords/r/<workspace>/<app>/ se exportar para outro lugar.
--------------------------------------------------------------------------------
SELECT valor, titulo, icone, link
  FROM (
        SELECT 1 AS ordem, COUNT(*) AS valor, 'Funcionários' AS titulo,
               'fa fa-users' AS icone,
               '/ords/r/projetosdeivid/sistema-rh-der/funcionários1?session=' || :APP_SESSION AS link
          FROM funcionarios
        UNION ALL
        SELECT 2, COUNT(*),
               'Férias em ' || INITCAP(TO_CHAR(ADD_MONTHS(SYSDATE, 1), 'FMMonth', 'NLS_DATE_LANGUAGE=PORTUGUESE')),
               'fa fa-calendar',
               '/ords/r/projetosdeivid/sistema-rh-der/férias?session=' || :APP_SESSION
          FROM vw_ferias_proximo_mes
        UNION ALL
        SELECT 3, COUNT(*), 'Ocorrências no mês',
               'fa fa-exclamation-triangle',
               '/ords/r/projetosdeivid/sistema-rh-der/ocorrências?session=' || :APP_SESSION
          FROM ocorrencias
         WHERE data_ocorrencia >= TRUNC(SYSDATE, 'MM')
       )
 ORDER BY ordem;

--------------------------------------------------------------------------------
-- Página 1 (Home) - item P1_MES_PROXIMO (computação Before Header)
-- Usado no título da região de férias: "Férias - &P1_MES_PROXIMO."
--------------------------------------------------------------------------------
SELECT INITCAP(TO_CHAR(ADD_MONTHS(SYSDATE, 1), 'FMMonth', 'NLS_DATE_LANGUAGE=PORTUGUESE')) FROM dual;

--------------------------------------------------------------------------------
-- Página 4 (Férias) - região do relatório (Interactive Report)
-- A coluna RECENTE alimenta o filtro padrão "Recente = Sim".
--------------------------------------------------------------------------------
SELECT fr.id_ferias,
       f.nome AS funcionario,
       f.matricula,
       fr.numero_processo,
       CASE fr.periodo
         WHEN 1 THEN '1º Período'
         WHEN 2 THEN '2º Período'
         WHEN 3 THEN '3º Período'
         WHEN 4 THEN '4º Período'
       END AS periodo,
       fr.data_inicio,
       fr.data_fim,
       fr.dias,
       fr.situacao,
       fr.observacao,
       CASE WHEN fr.data_fim >= TRUNC(SYSDATE, 'MM') THEN 'Sim' ELSE 'Não' END AS recente
  FROM ferias fr
  JOIN funcionarios f ON f.id_funcionario = fr.id_funcionario;

--------------------------------------------------------------------------------
-- Página 6 (Ocorrências) - região do relatório (Interactive Report)
--------------------------------------------------------------------------------
SELECT o.id_ocorrencia,
       f.nome AS funcionario,
       f.matricula,
       o.numero_processo,
       o.data_ocorrencia,
       o.tipo_ocorrencia,
       o.descricao,
       o.registrado_por
  FROM ocorrencias o
  JOIN funcionarios f ON f.id_funcionario = o.id_funcionario;

--------------------------------------------------------------------------------
-- Página 8 (Histórico - Funcionário) - lista de férias e ocorrências do funcionário
-- escolhido em P8_FUNCIONARIO, de 12 meses atrás até 12 meses à frente (Classic Report).
--------------------------------------------------------------------------------
SELECT data_evento,
       tipo,
       detalhe,
       processo,
       situacao
  FROM (
        SELECT fr.data_inicio AS data_evento,
               'Férias' AS tipo,
               'De ' || TO_CHAR(fr.data_inicio, 'DD/MM/YYYY') || ' a '
                     || TO_CHAR(fr.data_fim, 'DD/MM/YYYY')
                     || ' (' || fr.dias || ' dias)'
                     || CASE WHEN fr.observacao IS NOT NULL
                             THEN ' · ' || fr.observacao END AS detalhe,
               fr.numero_processo AS processo,
               INITCAP(REPLACE(fr.situacao, '_', ' ')) AS situacao
          FROM ferias fr
         WHERE fr.id_funcionario = :P8_FUNCIONARIO
           AND fr.data_fim    >= ADD_MONTHS(TRUNC(SYSDATE), -12)
           AND fr.data_inicio <= ADD_MONTHS(TRUNC(SYSDATE),  12)
        UNION ALL
        SELECT o.data_ocorrencia,
               CASE o.tipo_ocorrencia
                 WHEN 'ANOTACAO'    THEN 'Anotação'
                 WHEN 'ADVERTENCIA' THEN 'Advertência'
                 WHEN 'LICENCA'     THEN 'Licença'
                 ELSE INITCAP(o.tipo_ocorrencia)
               END,
               o.descricao,
               o.numero_processo,
               'Registrada'
          FROM ocorrencias o
         WHERE o.id_funcionario = :P8_FUNCIONARIO
           AND o.data_ocorrencia BETWEEN ADD_MONTHS(TRUNC(SYSDATE), -12)
                                     AND ADD_MONTHS(TRUNC(SYSDATE),  12)
       )
 ORDER BY data_evento DESC;

--------------------------------------------------------------------------------
-- Página 8 - item P8_FUNCIONARIO (Popup LOV) e página 5/7: busca de funcionário por nome
--------------------------------------------------------------------------------
SELECT nome || ' — Matrícula: ' || matricula AS d,
       id_funcionario AS r
  FROM funcionarios
 ORDER BY nome;
