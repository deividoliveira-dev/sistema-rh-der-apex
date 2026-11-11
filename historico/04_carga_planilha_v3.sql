--------------------------------------------------------------------------------
-- SISTEMA RH - DER
-- Script 04 (v3): Carga a partir da planilha CADASTRO_FUNCIONARIOS_DR4
-- Rode depois do Script 06.
--------------------------------------------------------------------------------

-- PASSO 1: tabela de staging, com os nomes de coluna EXATOS da sua planilha
CREATE TABLE stg_funcionarios (
    matricula           VARCHAR2(20 CHAR),
    nome                VARCHAR2(120 CHAR),
    rg                  VARCHAR2(20 CHAR),
    cpf                 VARCHAR2(20 CHAR),
    datnasc             VARCHAR2(20 CHAR),   -- formato mm/dd/yyyy na planilha (ver Passo 4)
    categoria           VARCHAR2(60 CHAR),
    cargo_funcao        VARCHAR2(80 CHAR),
    ua                  VARCHAR2(20 CHAR),
    setor_unidade       VARCHAR2(120 CHAR)
);

--------------------------------------------------------------------------------
-- PASSO 2: importar o CSV pra dentro de stg_funcionarios
-- SQL Developer: botão direito em STG_FUNCIONARIOS > Import Data > escolha o
-- CSV exportado da planilha > mapeie cada coluna (o nome já bate quase igual).
--------------------------------------------------------------------------------

-- PASSO 3: conferência antes de inserir de verdade
-- Cargos/setores da planilha que ainda não existem nas tabelas oficiais:
SELECT DISTINCT s.cargo_funcao
  FROM stg_funcionarios s
 WHERE s.cargo_funcao IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM cargos c WHERE UPPER(TRIM(c.nome_cargo)) = UPPER(TRIM(s.cargo_funcao))
       );

SELECT DISTINCT s.setor_unidade
  FROM stg_funcionarios s
 WHERE s.setor_unidade IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM setores st WHERE UPPER(TRIM(st.nome_setor)) = UPPER(TRIM(s.setor_unidade))
       );

-- Se aparecer algo aqui, cadastra antes de seguir, ex.:
-- INSERT INTO cargos (nome_cargo) VALUES ('NOME DO CARGO QUE APARECEU');
-- INSERT INTO setores (nome_setor) VALUES ('NOME DO SETOR QUE APARECEU');
-- COMMIT;

--------------------------------------------------------------------------------
-- PASSO 4: inserir em FUNCIONARIOS, já tratando as inconsistências encontradas:
--   - matricula: remove ponto (ex.: "508.883" -> "508883")
--   - categoria: normaliza EFETIVA -> EFETIVO (mesma categoria, só concordância de gênero)
--   - registros sem categoria/cargo/setor: usam "A DEFINIR"
--   - datnasc: a planilha veio em formato MM/DD/YYYY (confirme olhando alguns
--     registros que você conhece a data de nascimento; se estiver trocado,
--     troque a máscara abaixo para 'DD/MM/YYYY')
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
    CASE WHEN s.datnasc IS NOT NULL THEN TO_DATE(s.datnasc, 'MM/DD/YYYY') END,
    ct.id_categoria,
    c.id_cargo,
    s.ua,
    st.id_setor
  FROM stg_funcionarios s
  JOIN cargos  c  ON UPPER(TRIM(c.nome_cargo))  =
                      NVL(UPPER(TRIM(s.cargo_funcao)), 'A DEFINIR')
  JOIN setores st ON UPPER(TRIM(st.nome_setor)) =
                      NVL(UPPER(TRIM(s.setor_unidade)), 'A DEFINIR')
  LEFT JOIN categorias ct
         ON UPPER(TRIM(ct.nome_categoria)) =
            CASE UPPER(TRIM(NVL(s.categoria, 'A DEFINIR')))
                 WHEN 'EFETIVA' THEN 'EFETIVO'
                 ELSE UPPER(TRIM(NVL(s.categoria, 'A DEFINIR')))
            END;

COMMIT;

--------------------------------------------------------------------------------
-- PASSO 5: conferir resultado
--------------------------------------------------------------------------------
SELECT * FROM vw_funcionarios ORDER BY nome;

-- Confira em especial os que ficaram "A DEFINIR" -- são os 8 incompletos da planilha:
SELECT matricula, nome, nome_cargo, nome_setor
  FROM vw_funcionarios
 WHERE nome_cargo = 'A DEFINIR' OR nome_setor = 'A DEFINIR';

-- PASSO 6 (opcional, depois de conferir tudo): limpar a staging
-- TRUNCATE TABLE stg_funcionarios;
