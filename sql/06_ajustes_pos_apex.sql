--------------------------------------------------------------------------------
-- SISTEMA RH - DER
-- Script 06: Ajustes feitos durante a construção das telas no APEX
-- Rode depois do 05. Se for executar no SQL Commands do APEX, rode um comando por vez.
--------------------------------------------------------------------------------

-- Número do processo administrativo (ex.: 139.00089924/2026-92)
ALTER TABLE ferias      ADD (numero_processo VARCHAR2(30 CHAR));
ALTER TABLE ocorrencias ADD (numero_processo VARCHAR2(30 CHAR));

-- Novo tipo de ocorrência: LICENCA
ALTER TABLE ocorrencias DROP CONSTRAINT ck_ocor_tipo;

ALTER TABLE ocorrencias ADD CONSTRAINT ck_ocor_tipo
  CHECK (tipo_ocorrencia IN
    ('ANOTACAO','FALTA','ATRASO','ADVERTENCIA','ATESTADO','ELOGIO','OUTRO','LICENCA'));

-- CPF, RG e UA aceitam qualquer formato (com ou sem pontuação): sem regra de 11 números
ALTER TABLE funcionarios DROP CONSTRAINT ck_func_cpf_formato;
ALTER TABLE funcionarios MODIFY (cpf VARCHAR2(30 CHAR));
ALTER TABLE funcionarios MODIFY (rg VARCHAR2(30 CHAR), ua_codigo VARCHAR2(30 CHAR));

-- Férias que começam no mês seguinte ao atual (tabela do dashboard)
CREATE OR REPLACE VIEW vw_ferias_proximo_mes AS
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
   AND fr.data_inicio >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 1)
   AND fr.data_inicio <  ADD_MONTHS(TRUNC(SYSDATE, 'MM'), 2);

-- Consulta da região de cards da Home (3 indicadores em uma região só, com ícone Font APEX):
-- SELECT valor, titulo, icone
--   FROM (
--         SELECT 1 AS ordem, COUNT(*) AS valor, 'Funcionários' AS titulo, 'fa fa-users' AS icone
--           FROM funcionarios
--         UNION ALL
--         SELECT 2, COUNT(*), 'Férias no próximo mês', 'fa fa-calendar'
--           FROM vw_ferias_proximo_mes
--         UNION ALL
--         SELECT 3, COUNT(*), 'Ocorrências no mês', 'fa fa-exclamation-triangle'
--           FROM ocorrencias
--          WHERE data_ocorrencia >= TRUNC(SYSDATE, 'MM')
--        )
--  ORDER BY ordem
