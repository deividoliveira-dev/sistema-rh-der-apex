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
