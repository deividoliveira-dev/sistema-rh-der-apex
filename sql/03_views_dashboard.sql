--------------------------------------------------------------------------------
-- SISTEMA RH - DER
-- Script 03: Views de apoio para o Dashboard do APEX
-- Cada view aqui alimenta direto um "Card" ou uma "Interactive Report"
--------------------------------------------------------------------------------

-- View: lista de funcionários já com nome do cargo e setor (usar na tela "Funcionários")
CREATE OR REPLACE VIEW vw_funcionarios AS
SELECT f.id_funcionario,
       f.matricula,
       f.nome,
       f.cpf,
       f.data_nascimento,
       f.data_admissao,
       c.nome_cargo,
       s.nome_setor,
       f.situacao,
       f.id_cargo,
       f.id_setor
  FROM funcionarios f
  JOIN cargos  c ON c.id_cargo = f.id_cargo
  JOIN setores s ON s.id_setor = f.id_setor;

-- View: férias nos próximos 30 dias (card "FÉRIAS PRÓX. 30 DIAS" + tabela do dashboard)
CREATE OR REPLACE VIEW vw_ferias_proximos_30d AS
SELECT fr.id_ferias,
       f.nome                              AS funcionario,
       f.matricula,
       c.nome_cargo,
       fr.data_inicio,
       fr.data_fim,
       fr.dias,
       TRUNC(fr.data_inicio) - TRUNC(SYSDATE) AS dias_para_iniciar,
       'Inicia em ' || (TRUNC(fr.data_inicio) - TRUNC(SYSDATE)) || ' dias' AS situacao_label
  FROM ferias fr
  JOIN funcionarios f ON f.id_funcionario = fr.id_funcionario
  JOIN cargos c        ON c.id_cargo = f.id_cargo
 WHERE fr.situacao = 'AGENDADA'
   AND fr.data_inicio BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 30
 ORDER BY fr.data_inicio;

-- View: atualizações recentes (últimas ocorrências, pra timeline do dashboard)
CREATE OR REPLACE VIEW vw_atualizacoes_recentes AS
SELECT 'Ocorrência (' || o.tipo_ocorrencia || ') registrada para ' || f.nome AS descricao,
       o.data_cadastro
  FROM ocorrencias o
  JOIN funcionarios f ON f.id_funcionario = o.id_funcionario
 ORDER BY o.data_cadastro DESC
FETCH FIRST 10 ROWS ONLY;

-- Consultas prontas pros 4 "cards" do topo do dashboard (imagem 1 e 2):
--   SELECT COUNT(*) FROM funcionarios;                                   -> Funcionários
--   SELECT COUNT(*) FROM vw_ferias_proximos_30d;                          -> Férias próx. 30 dias
--   SELECT COUNT(*) FROM ocorrencias WHERE data_ocorrencia >= TRUNC(SYSDATE,'MM'); -> Ocorrências no mês
--   SELECT COUNT(*) FROM ocorrencias WHERE tipo_ocorrencia = 'ATESTADO';  -> Atestados ativos
