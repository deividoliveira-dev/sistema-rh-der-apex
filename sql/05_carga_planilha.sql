--------------------------------------------------------------------------------
-- SISTEMA RH - DER
-- Script 04 (FINAL): Carga da planilha CADASTRO_FUNCIONARIOS_DR4
-- Rode depois do Script 05.
--------------------------------------------------------------------------------

-- PASSO 1: tabela de staging
CREATE TABLE stg_funcionarios (
    matricula           VARCHAR2(20 CHAR),
    nome                VARCHAR2(120 CHAR),
    rg                  VARCHAR2(20 CHAR),
    cpf                 VARCHAR2(20 CHAR),
    data_nascimento     VARCHAR2(20 CHAR),   -- formato brasileiro DD/MM/YYYY
    categoria           VARCHAR2(60 CHAR),
    cargo               VARCHAR2(80 CHAR),
    ua                  VARCHAR2(20 CHAR),
    setor               VARCHAR2(120 CHAR)
);

--------------------------------------------------------------------------------
-- PASSO 2: importar o CSV
-- SQL Workshop > Utilities > Data Workshop > Load Data > selecione o CSV
-- e mapeie cada coluna do arquivo para a coluna correspondente de STG_FUNCIONARIOS.
--------------------------------------------------------------------------------

-- PASSO 3: cadastrar cargos e setores novos de uma vez (evita fazer um por um)
INSERT INTO cargos (nome_cargo)
SELECT DISTINCT TRIM(s.cargo)
  FROM stg_funcionarios s
 WHERE s.cargo IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM cargos c WHERE UPPER(TRIM(c.nome_cargo)) = UPPER(TRIM(s.cargo))
       );

INSERT INTO setores (nome_setor)
SELECT DISTINCT TRIM(s.setor)
  FROM stg_funcionarios s
 WHERE s.setor IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM setores st WHERE UPPER(TRIM(st.nome_setor)) = UPPER(TRIM(s.setor))
       );

COMMIT;

--------------------------------------------------------------------------------
-- PASSO 4: inserir em FUNCIONARIOS, já com as correções conhecidas
--------------------------------------------------------------------------------
INSERT INTO funcionarios (
    matricula, nome, rg, cpf, data_nascimento,
    id_categoria, id_cargo, ua_codigo, id_setor
)
SELECT
    REPLACE(s.matricula, '.', ''),
    TRIM(s.nome),
    s.rg,
    REGEXP_REPLACE(s.cpf, '[^0-9]', ''),
    CASE WHEN s.data_nascimento IS NOT NULL
         THEN TO_DATE(s.data_nascimento, 'DD/MM/YYYY') END,
    ct.id_categoria,
    c.id_cargo,
    s.ua,
    st.id_setor
  FROM stg_funcionarios s
  JOIN cargos  c  ON UPPER(TRIM(c.nome_cargo))  =
                      NVL(UPPER(TRIM(s.cargo)), 'A DEFINIR')
  JOIN setores st ON UPPER(TRIM(st.nome_setor)) =
                      NVL(UPPER(TRIM(s.setor)), 'A DEFINIR')
  LEFT JOIN categorias ct
         ON UPPER(TRIM(ct.nome_categoria)) =
            CASE UPPER(TRIM(NVL(s.categoria, 'A DEFINIR')))
                 WHEN 'EFETIVA' THEN 'EFETIVO'
                 ELSE UPPER(TRIM(NVL(s.categoria, 'A DEFINIR')))
            END;

COMMIT;

--------------------------------------------------------------------------------
-- PASSO 5: conferir
--------------------------------------------------------------------------------
SELECT COUNT(*) FROM funcionarios;   -- esperado: 84
SELECT * FROM vw_funcionarios ORDER BY nome;
