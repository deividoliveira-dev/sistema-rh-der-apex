--------------------------------------------------------------------------------
-- SISTEMA RH - DER
-- Script 02: Package PKG_RH — regras de negócio e CRUD
-- Isso é o que o APEX vai chamar nos botões "Salvar", "Excluir", etc.
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE pkg_rh AS

    -- ==================== FUNCIONARIOS ====================
    PROCEDURE sp_funcionario_incluir(
        p_matricula        IN VARCHAR2,
        p_nome             IN VARCHAR2,
        p_cpf              IN VARCHAR2,
        p_data_nascimento  IN DATE,
        p_data_admissao    IN DATE,
        p_id_cargo         IN NUMBER,
        p_id_setor         IN NUMBER,
        p_id_funcionario   OUT NUMBER
    );

    PROCEDURE sp_funcionario_atualizar(
        p_id_funcionario   IN NUMBER,
        p_nome             IN VARCHAR2,
        p_cpf              IN VARCHAR2,
        p_data_nascimento  IN DATE,
        p_data_admissao    IN DATE,
        p_id_cargo         IN NUMBER,
        p_id_setor         IN NUMBER,
        p_situacao         IN VARCHAR2
    );

    PROCEDURE sp_funcionario_excluir(p_id_funcionario IN NUMBER);

    -- ==================== FERIAS ====================
    PROCEDURE sp_ferias_incluir(
        p_id_funcionario IN NUMBER,
        p_data_inicio    IN DATE,
        p_data_fim       IN DATE,
        p_observacao     IN VARCHAR2 DEFAULT NULL,
        p_id_ferias      OUT NUMBER
    );

    PROCEDURE sp_ferias_cancelar(p_id_ferias IN NUMBER);

    -- ==================== OCORRENCIAS ====================
    PROCEDURE sp_ocorrencia_incluir(
        p_id_funcionario  IN NUMBER,
        p_tipo_ocorrencia IN VARCHAR2,
        p_descricao       IN VARCHAR2,
        p_registrado_por  IN VARCHAR2,
        p_id_ocorrencia   OUT NUMBER
    );

END pkg_rh;
/

CREATE OR REPLACE PACKAGE BODY pkg_rh AS

    ---------------------------------------------------------------
    PROCEDURE sp_funcionario_incluir(
        p_matricula        IN VARCHAR2,
        p_nome             IN VARCHAR2,
        p_cpf              IN VARCHAR2,
        p_data_nascimento  IN DATE,
        p_data_admissao    IN DATE,
        p_id_cargo         IN NUMBER,
        p_id_setor         IN NUMBER,
        p_id_funcionario   OUT NUMBER
    ) IS
    BEGIN
        -- validação simples de idade mínima (16 anos na admissão, por ex.)
        IF MONTHS_BETWEEN(p_data_admissao, p_data_nascimento) / 12 < 16 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Funcionário deve ter pelo menos 16 anos na data de admissão.');
        END IF;

        INSERT INTO funcionarios (
            matricula, nome, cpf, data_nascimento, data_admissao,
            id_cargo, id_setor
        ) VALUES (
            p_matricula, p_nome, p_cpf, p_data_nascimento, p_data_admissao,
            p_id_cargo, p_id_setor
        )
        RETURNING id_funcionario INTO p_id_funcionario;

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20002, 'Já existe funcionário com essa matrícula ou CPF.');
    END sp_funcionario_incluir;

    ---------------------------------------------------------------
    PROCEDURE sp_funcionario_atualizar(
        p_id_funcionario   IN NUMBER,
        p_nome             IN VARCHAR2,
        p_cpf              IN VARCHAR2,
        p_data_nascimento  IN DATE,
        p_data_admissao    IN DATE,
        p_id_cargo         IN NUMBER,
        p_id_setor         IN NUMBER,
        p_situacao         IN VARCHAR2
    ) IS
    BEGIN
        UPDATE funcionarios
           SET nome            = p_nome,
               cpf             = p_cpf,
               data_nascimento = p_data_nascimento,
               data_admissao   = p_data_admissao,
               id_cargo        = p_id_cargo,
               id_setor        = p_id_setor,
               situacao        = p_situacao,
               data_atualizacao = SYSDATE
         WHERE id_funcionario = p_id_funcionario;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Funcionário não encontrado para atualização.');
        END IF;
    END sp_funcionario_atualizar;

    ---------------------------------------------------------------
    PROCEDURE sp_funcionario_excluir(p_id_funcionario IN NUMBER) IS
    BEGIN
        DELETE FROM funcionarios WHERE id_funcionario = p_id_funcionario;
    END sp_funcionario_excluir;

    ---------------------------------------------------------------
    PROCEDURE sp_ferias_incluir(
        p_id_funcionario IN NUMBER,
        p_data_inicio    IN DATE,
        p_data_fim       IN DATE,
        p_observacao     IN VARCHAR2 DEFAULT NULL,
        p_id_ferias      OUT NUMBER
    ) IS
        v_conflitos NUMBER;
    BEGIN
        -- não deixa cadastrar férias sobrepondo período já existente do mesmo funcionário
        SELECT COUNT(*) INTO v_conflitos
          FROM ferias
         WHERE id_funcionario = p_id_funcionario
           AND situacao IN ('AGENDADA','EM_ANDAMENTO')
           AND p_data_inicio <= data_fim
           AND p_data_fim >= data_inicio;

        IF v_conflitos > 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Já existe período de férias sobreposto para esse funcionário.');
        END IF;

        INSERT INTO ferias (id_funcionario, data_inicio, data_fim, observacao)
        VALUES (p_id_funcionario, p_data_inicio, p_data_fim, p_observacao)
        RETURNING id_ferias INTO p_id_ferias;
    END sp_ferias_incluir;

    ---------------------------------------------------------------
    PROCEDURE sp_ferias_cancelar(p_id_ferias IN NUMBER) IS
    BEGIN
        UPDATE ferias SET situacao = 'CANCELADA' WHERE id_ferias = p_id_ferias;
    END sp_ferias_cancelar;

    ---------------------------------------------------------------
    PROCEDURE sp_ocorrencia_incluir(
        p_id_funcionario  IN NUMBER,
        p_tipo_ocorrencia IN VARCHAR2,
        p_descricao       IN VARCHAR2,
        p_registrado_por  IN VARCHAR2,
        p_id_ocorrencia   OUT NUMBER
    ) IS
    BEGIN
        INSERT INTO ocorrencias (id_funcionario, tipo_ocorrencia, descricao, registrado_por)
        VALUES (p_id_funcionario, p_tipo_ocorrencia, p_descricao, p_registrado_por)
        RETURNING id_ocorrencia INTO p_id_ocorrencia;
    END sp_ocorrencia_incluir;

END pkg_rh;
/
