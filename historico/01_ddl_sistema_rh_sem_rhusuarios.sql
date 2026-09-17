--------------------------------------------------------------------------------
-- SISTEMA RH - DER (Departamento de Estrada e Rodagem)
-- Script 01: DDL - Criação das tabelas
-- Oracle 12c+ (usa IDENTITY, então não precisa de sequence + trigger)
--------------------------------------------------------------------------------

-- Se for rodar de novo do zero, descomente para limpar:
-- DROP TABLE ocorrencias PURGE;
-- DROP TABLE ferias PURGE;
-- DROP TABLE funcionarios PURGE;
-- DROP TABLE cargos PURGE;
-- DROP TABLE setores PURGE;
-- DROP TABLE usuarios PURGE;

--------------------------------------------------------------------------------
-- TABELA: SETORES
--------------------------------------------------------------------------------
CREATE TABLE setores (
    id_setor        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_setor      VARCHAR2(60 CHAR) NOT NULL,
    ativo           CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT ck_setor_ativo CHECK (ativo IN ('S','N')),
    CONSTRAINT uk_setor_nome UNIQUE (nome_setor)
);

--------------------------------------------------------------------------------
-- TABELA: CARGOS
--------------------------------------------------------------------------------
CREATE TABLE cargos (
    id_cargo        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_cargo      VARCHAR2(60 CHAR) NOT NULL,
    ativo           CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT ck_cargo_ativo CHECK (ativo IN ('S','N')),
    CONSTRAINT uk_cargo_nome UNIQUE (nome_cargo)
);

--------------------------------------------------------------------------------
-- TABELA: FUNCIONARIOS
--------------------------------------------------------------------------------
CREATE TABLE funcionarios (
    id_funcionario      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    matricula           VARCHAR2(20 CHAR) NOT NULL,
    nome                VARCHAR2(120 CHAR) NOT NULL,
    cpf                 VARCHAR2(11 CHAR) NOT NULL,       -- guardo só números, formato na tela
    data_nascimento     DATE NOT NULL,
    data_admissao       DATE NOT NULL,
    id_cargo            NUMBER NOT NULL,
    id_setor            NUMBER NOT NULL,
    situacao            VARCHAR2(10 CHAR) DEFAULT 'ATIVO' NOT NULL,
    data_cadastro       DATE DEFAULT SYSDATE NOT NULL,
    data_atualizacao    DATE,
    CONSTRAINT uk_func_matricula UNIQUE (matricula),
    CONSTRAINT uk_func_cpf UNIQUE (cpf),
    CONSTRAINT ck_func_situacao CHECK (situacao IN ('ATIVO','INATIVO','AFASTADO','FERIAS')),
    CONSTRAINT ck_func_cpf_formato CHECK (REGEXP_LIKE(cpf, '^[0-9]{11}$')),
    CONSTRAINT ck_func_nascimento CHECK (data_nascimento < data_admissao),
    CONSTRAINT fk_func_cargo FOREIGN KEY (id_cargo) REFERENCES cargos(id_cargo),
    CONSTRAINT fk_func_setor FOREIGN KEY (id_setor) REFERENCES setores(id_setor)
);

CREATE INDEX ix_func_nome ON funcionarios (nome);
CREATE INDEX ix_func_situacao ON funcionarios (situacao);

--------------------------------------------------------------------------------
-- TABELA: OCORRENCIAS (anotações por funcionário, até ~4000 caracteres)
--------------------------------------------------------------------------------
CREATE TABLE ocorrencias (
    id_ocorrencia       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_funcionario      NUMBER NOT NULL,
    data_ocorrencia     DATE DEFAULT SYSDATE NOT NULL,
    tipo_ocorrencia     VARCHAR2(30 CHAR) DEFAULT 'ANOTACAO' NOT NULL,
    descricao           VARCHAR2(4000 CHAR) NOT NULL,   -- cobre os ~2000 caracteres pedidos com folga
    registrado_por      VARCHAR2(60 CHAR),
    data_cadastro       DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_ocor_func FOREIGN KEY (id_funcionario)
        REFERENCES funcionarios(id_funcionario) ON DELETE CASCADE,
    CONSTRAINT ck_ocor_tipo CHECK (tipo_ocorrencia IN
        ('ANOTACAO','FALTA','ATRASO','ADVERTENCIA','ATESTADO','ELOGIO','OUTRO'))
);

CREATE INDEX ix_ocor_func ON ocorrencias (id_funcionario, data_ocorrencia);

--------------------------------------------------------------------------------
-- TABELA: FERIAS
--------------------------------------------------------------------------------
CREATE TABLE ferias (
    id_ferias           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_funcionario       NUMBER NOT NULL,
    data_inicio          DATE NOT NULL,
    data_fim              DATE NOT NULL,
    dias                  NUMBER GENERATED ALWAYS AS (data_fim - data_inicio + 1) VIRTUAL,
    situacao              VARCHAR2(15 CHAR) DEFAULT 'AGENDADA' NOT NULL,
    observacao            VARCHAR2(500 CHAR),
    CONSTRAINT fk_ferias_func FOREIGN KEY (id_funcionario)
        REFERENCES funcionarios(id_funcionario) ON DELETE CASCADE,
    CONSTRAINT ck_ferias_datas CHECK (data_fim >= data_inicio),
    CONSTRAINT ck_ferias_situacao CHECK (situacao IN ('AGENDADA','EM_ANDAMENTO','CONCLUIDA','CANCELADA'))
);

CREATE INDEX ix_ferias_func ON ferias (id_funcionario, data_inicio);

--------------------------------------------------------------------------------
-- TABELA: USUARIOS (quem acessa o sistema)
--------------------------------------------------------------------------------
CREATE TABLE usuarios (
    id_usuario          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    login               VARCHAR2(30 CHAR) NOT NULL,
    nome                VARCHAR2(120 CHAR) NOT NULL,
    perfil              VARCHAR2(20 CHAR) DEFAULT 'RH' NOT NULL,
    ativo               CHAR(1) DEFAULT 'S' NOT NULL,
    CONSTRAINT uk_usuario_login UNIQUE (login),
    CONSTRAINT ck_usuario_perfil CHECK (perfil IN ('ADMIN','RH','CONSULTA')),
    CONSTRAINT ck_usuario_ativo CHECK (ativo IN ('S','N'))
    -- Senha eu não coloco aqui: no APEX, autenticação fica por conta do
    -- esquema de autenticação do próprio APEX (ou LDAP/SSO), não em tabela própria.
);

--------------------------------------------------------------------------------
-- Dados iniciais de exemplo (opcional, ajuda a testar o APEX rapidinho)
--------------------------------------------------------------------------------
INSERT INTO setores (nome_setor) VALUES ('Transporte');
INSERT INTO setores (nome_setor) VALUES ('Administrativo');
INSERT INTO setores (nome_setor) VALUES ('Operacional');
INSERT INTO setores (nome_setor) VALUES ('RH');
INSERT INTO setores (nome_setor) VALUES ('Fiscalização');

INSERT INTO cargos (nome_cargo) VALUES ('Motorista');
INSERT INTO cargos (nome_cargo) VALUES ('Analista Administrativo');
INSERT INTO cargos (nome_cargo) VALUES ('Técnico de Estradas');
INSERT INTO cargos (nome_cargo) VALUES ('Engenheiro');
INSERT INTO cargos (nome_cargo) VALUES ('Operador de Máquinas');

COMMIT;
