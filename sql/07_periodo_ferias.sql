--------------------------------------------------------------------------------
-- SISTEMA RH - DER
-- Script 07: Período das férias (1º ao 4º período)
-- Rode depois do 06. Se for executar no SQL Commands do APEX, rode um comando por vez.
--------------------------------------------------------------------------------

ALTER TABLE ferias ADD (periodo NUMBER(1));

ALTER TABLE ferias ADD CONSTRAINT ck_ferias_periodo CHECK (periodo IN (1, 2, 3, 4));
