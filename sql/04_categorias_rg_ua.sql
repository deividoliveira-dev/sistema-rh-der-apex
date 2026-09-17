--------------------------------------------------------------------------------
-- SISTEMA RH - DER
-- Script 05 (FINAL): RG, CATEGORIA e UA já no formato definitivo
-- Rode depois do 01, 02 e 03.
--------------------------------------------------------------------------------

-- Tabela de domínio: CATEGORIAS
CREATE TABLE categorias (
    id_categoria    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_categoria  VARCHAR2(60 CHAR) NOT NULL,
    ativo           CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT ck_categoria_ativo CHECK (ativo IN ('S','N')),
    CONSTRAINT uk_categoria_nome UNIQUE (nome_categoria)
);

-- Tabela de UAs (fica reservada pra uso futuro, caso um dia você tenha
-- a lista "código -> nome" da unidade administrativa)
CREATE TABLE unidades_administrativas (
    id_ua           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_ua         VARCHAR2(80 CHAR) NOT NULL,
    sigla_ua        VARCHAR2(15 CHAR),
    ativo           CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT ck_ua_ativo CHECK (ativo IN ('S','N')),
    CONSTRAINT uk_ua_nome UNIQUE (nome_ua)
);

-- Novas colunas em FUNCIONARIOS: RG (texto), CATEGORIA (FK), UA (código simples)
ALTER TABLE funcionarios ADD (
    rg              VARCHAR2(20 CHAR),
    id_categoria    NUMBER,
    ua_codigo       VARCHAR2(20 CHAR)
);

ALTER TABLE funcionarios ADD CONSTRAINT fk_func_categoria
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria);

-- Categorias de exemplo + placeholder pros registros incompletos da planilha
INSERT INTO categorias (nome_categoria) VALUES ('EFETIVO');
INSERT INTO categorias (nome_categoria) VALUES ('CELETISTA');
INSERT INTO categorias (nome_categoria) VALUES ('COMISSÃO');
INSERT INTO categorias (nome_categoria) VALUES ('A DEFINIR');

-- Placeholder de cargo/setor pros funcionários com dado incompleto na planilha
INSERT INTO cargos (nome_cargo) VALUES ('A DEFINIR');
INSERT INTO setores (nome_setor) VALUES ('A DEFINIR');

COMMIT;

--------------------------------------------------------------------------------
-- View final: matricula, nome, rg, cpf, data de nascimento, categoria, cargo, UA, setor
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_funcionarios AS
SELECT f.id_funcionario,
       f.matricula,
       f.nome,
       f.rg,
       f.cpf,
       f.data_nascimento,
       ct.nome_categoria,
       c.nome_cargo,
       f.ua_codigo,
       s.nome_setor,
       f.data_admissao,
       f.situacao,
       f.id_categoria,
       f.id_cargo,
       f.id_setor
  FROM funcionarios f
  JOIN cargos      c   ON c.id_cargo     = f.id_cargo
  JOIN setores     s   ON s.id_setor     = f.id_setor
  LEFT JOIN categorias ct ON ct.id_categoria = f.id_categoria;
