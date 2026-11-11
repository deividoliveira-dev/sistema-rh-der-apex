--------------------------------------------------------------------------------
-- SISTEMA RH - DER
-- Script 04 (v2): Carga em massa a partir da planilha (Excel/CSV)
-- Atualizado com RG, CATEGORIA e UA
--------------------------------------------------------------------------------

-- PASSO 1: tabela de staging (bate com as colunas da sua planilha)
CREATE TABLE stg_funcionarios (
    matricula           VARCHAR2(20 CHAR),
    nome                VARCHAR2(120 CHAR),
    rg                  VARCHAR2(15 CHAR),
    cpf                 VARCHAR2(14 CHAR),   -- aceita com ou sem pontuação por enquanto
    data_nascimento     VARCHAR2(20 CHAR),   -- string mesmo: formato de data da planilha varia
    categoria           VARCHAR2(60 CHAR),
    cargo               VARCHAR2(60 CHAR),
    ua                  VARCHAR2(80 CHAR),
    setor               VARCHAR2(60 CHAR),
    data_admissao       VARCHAR2(20 CHAR)
);

--------------------------------------------------------------------------------
-- PASSO 2: colocar os dados da planilha dentro de stg_funcionarios
--
-- No SQL Developer: botão direito em STG_FUNCIONARIOS (na árvore, dentro de
-- Tabelas) > Import Data > selecione o CSV > mapeie cada coluna do arquivo
-- para a coluna correspondente aqui em cima > Finish.
--
-- Se sua planilha ainda estiver em .xlsx, salve como CSV antes
-- (Excel: Arquivo > Salvar Como > CSV UTF-8).
--------------------------------------------------------------------------------

-- PASSO 3: conferir se cargo / setor / categoria / UA da planilha batem com o que já existe
-- (se aparecer algo aqui, ou ajusta a planilha ou cadastra o que falta antes de seguir)
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

SELECT DISTINCT s.categoria
  FROM stg_funcionarios s
 WHERE s.categoria IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM categorias ct WHERE UPPER(TRIM(ct.nome_categoria)) = UPPER(TRIM(s.categoria))
       );

SELECT DISTINCT s.ua
  FROM stg_funcionarios s
 WHERE s.ua IS NOT NULL
   AND NOT EXISTS (
        SELECT 1 FROM unidades_administrativas u WHERE UPPER(TRIM(u.nome_ua)) = UPPER(TRIM(s.ua))
       );

-- Se aparecer algo novo na planilha que ainda não existe na tabela oficial, cadastra, ex.:
-- INSERT INTO cargos (nome_cargo) VALUES ('Fiscal de Obras');
-- INSERT INTO setores (nome_setor) VALUES ('Almoxarifado');
-- INSERT INTO categorias (nome_categoria) VALUES ('Contratado');
-- INSERT INTO unidades_administrativas (nome_ua) VALUES ('Diretoria Financeira');
-- COMMIT;

--------------------------------------------------------------------------------
-- PASSO 4: inserir de fato em FUNCIONARIOS, já resolvendo os IDs
-- Ajuste a máscara de data (TO_DATE) conforme o formato da sua planilha.
-- Ex.: se vier "25/06/1990" use 'DD/MM/YYYY'.
-- CATEGORIA e UA usam LEFT JOIN (opcionais); CARGO e SETOR usam JOIN normal (obrigatórios).
--------------------------------------------------------------------------------
INSERT INTO funcionarios (
    matricula, nome, rg, cpf, data_nascimento, data_admissao,
    id_categoria, id_cargo, id_ua, id_setor
)
SELECT
    s.matricula,
    s.nome,
    s.rg,
    REGEXP_REPLACE(s.cpf, '[^0-9]', ''),                 -- tira ponto/traço do CPF
    TO_DATE(s.data_nascimento, 'DD/MM/YYYY'),
    TO_DATE(s.data_admissao,   'DD/MM/YYYY'),
    ct.id_categoria,
    c.id_cargo,
    ua.id_ua,
    st.id_setor
  FROM stg_funcionarios s
  JOIN  cargos  c   ON UPPER(TRIM(c.nome_cargo))   = UPPER(TRIM(s.cargo))
  JOIN  setores st  ON UPPER(TRIM(st.nome_setor))  = UPPER(TRIM(s.setor))
  LEFT JOIN categorias ct ON UPPER(TRIM(ct.nome_categoria)) = UPPER(TRIM(s.categoria))
  LEFT JOIN unidades_administrativas ua ON UPPER(TRIM(ua.nome_ua)) = UPPER(TRIM(s.ua));

COMMIT;

--------------------------------------------------------------------------------
-- PASSO 5: conferir o resultado final
--------------------------------------------------------------------------------
SELECT * FROM vw_funcionarios;

-- PASSO 6 (opcional): depois de conferir que deu tudo certo, pode limpar a staging
-- TRUNCATE TABLE stg_funcionarios;
-- ou até: DROP TABLE stg_funcionarios PURGE;
