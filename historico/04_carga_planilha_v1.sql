--------------------------------------------------------------------------------
-- SISTEMA RH - DER
-- Script 04: Carga em massa a partir da planilha (Excel/CSV)
--
-- IDEIA: sua planilha não bate 100% com a estrutura normalizada
-- (ela provavelmente tem "Cargo" e "Setor" como texto, não como ID).
-- Então a gente carrega tudo "cru" numa tabela de staging e depois
-- resolve os IDs com um INSERT ... SELECT.
--------------------------------------------------------------------------------

-- PASSO 1: tabela de staging (bate com as colunas da sua planilha)
CREATE TABLE stg_funcionarios (
    matricula           VARCHAR2(20 CHAR),
    nome                VARCHAR2(120 CHAR),
    cpf                 VARCHAR2(14 CHAR),   -- aceita com ou sem pontuação por enquanto
    data_nascimento     VARCHAR2(20 CHAR),   -- string mesmo: formato de data da planilha varia
    data_admissao       VARCHAR2(20 CHAR),
    cargo               VARCHAR2(60 CHAR),
    setor               VARCHAR2(60 CHAR)
);

--------------------------------------------------------------------------------
-- PASSO 2: colocar os dados da planilha dentro de stg_funcionarios
-- Escolha UMA das opções abaixo (não precisa fazer as três):
--
-- OPÇÃO A - APEX (mais fácil, sem instalar nada):
--   1. Exporte sua planilha como .csv (Excel: Salvar Como > CSV UTF-8)
--   2. No APEX: App Builder > seu App > "SQL Workshop" > "Utilities" > "Data Workshop"
--      > "Load Data" > escolha o arquivo CSV
--   3. No mapeamento de colunas, selecione a tabela STG_FUNCIONARIOS
--      e associe cada coluna do CSV à coluna correspondente da staging
--   4. Rode a carga. Depois disso, vá pro PASSO 3 abaixo.
--
-- OPÇÃO B - SQL Developer (se estiver usando o cliente desktop):
--   Botão direito na tabela STG_FUNCIONARIOS > Import Data > selecione o CSV
--   > mapeie as colunas > Finish.
--
-- OPÇÃO C - SQL*Loader (linha de comando, mais "raiz"):
--   sqlldr usuario/senha@banco control=stg_funcionarios.ctl log=carga.log
--   (te mando o .ctl se quiser seguir por esse caminho)
--------------------------------------------------------------------------------

-- PASSO 3: conferir se cargo/setor da planilha batem com o que já existe
-- (se aparecer algo aqui, ou ajusta a planilha ou cadastra o cargo/setor que falta)
SELECT DISTINCT s.cargo
  FROM stg_funcionarios s
 WHERE NOT EXISTS (
        SELECT 1 FROM cargos c WHERE UPPER(TRIM(c.nome_cargo)) = UPPER(TRIM(s.cargo))
       );

SELECT DISTINCT s.setor
  FROM stg_funcionarios s
 WHERE NOT EXISTS (
        SELECT 1 FROM setores st WHERE UPPER(TRIM(st.nome_setor)) = UPPER(TRIM(s.setor))
       );

-- Se aparecer cargo/setor novo na planilha que ainda não existe na tabela oficial,
-- cadastra rapidinho, por exemplo:
-- INSERT INTO cargos (nome_cargo) VALUES ('Fiscal de Obras');
-- INSERT INTO setores (nome_setor) VALUES ('Almoxarifado');
-- COMMIT;

--------------------------------------------------------------------------------
-- PASSO 4: inserir de fato em FUNCIONARIOS, já resolvendo os IDs
-- Ajuste as máscaras de data (TO_DATE) conforme o formato que vier na sua planilha.
-- Ex.: se a planilha tem "25/06/1990" use 'DD/MM/YYYY'.
--------------------------------------------------------------------------------
INSERT INTO funcionarios (
    matricula, nome, cpf, data_nascimento, data_admissao, id_cargo, id_setor
)
SELECT
    s.matricula,
    s.nome,
    REGEXP_REPLACE(s.cpf, '[^0-9]', ''),                 -- tira ponto/traço do CPF
    TO_DATE(s.data_nascimento, 'DD/MM/YYYY'),
    TO_DATE(s.data_admissao,   'DD/MM/YYYY'),
    c.id_cargo,
    st.id_setor
  FROM stg_funcionarios s
  JOIN cargos  c  ON UPPER(TRIM(c.nome_cargo))  = UPPER(TRIM(s.cargo))
  JOIN setores st ON UPPER(TRIM(st.nome_setor)) = UPPER(TRIM(s.setor));

COMMIT;

-- PASSO 5 (opcional): depois de conferir que deu tudo certo, pode limpar a staging
-- TRUNCATE TABLE stg_funcionarios;
-- ou até: DROP TABLE stg_funcionarios PURGE;
