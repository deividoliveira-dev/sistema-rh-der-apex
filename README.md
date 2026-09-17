# Sistema RH - DER (Oracle APEX)

Sistema de gestão de RH desenvolvido em **PL/SQL** com interface em **Oracle APEX**, para um Departamento de Estradas e Rodagem (DER). Cobre cadastro de funcionários, cargos, setores, categorias, unidades administrativas, férias e ocorrências, além de um dashboard com indicadores.

## Estrutura do banco

- **setores** — setores/departamentos da empresa
- **cargos** — cargos disponíveis
- **categorias** — categoria funcional do servidor (efetivo, celetista, comissão, etc.)
- **unidades_administrativas** — unidades administrativas (UA)
- **funcionarios** — cadastro principal, com FK para cargo, setor e categoria
- **ferias** — períodos de férias por funcionário, com controle de sobreposição
- **ocorrencias** — anotações/ocorrências do funcionário (falta, atestado, advertência, elogio, etc.)
- **rh_usuarios** — usuários com acesso ao sistema (autenticação fica a cargo do APEX)

Regras de negócio (validações, inclusão/atualização/exclusão) ficam centralizadas na package `PKG_RH`, chamada pelos processos do APEX.

## Estrutura de pastas

```
sql/
  01_ddl_sistema_rh.sql       -- criação das tabelas (setores, cargos, funcionarios, ferias, ocorrencias, rh_usuarios)
  02_pkg_rh.sql                -- package PKG_RH com as regras de negócio (CRUD)
  03_views_dashboard.sql       -- views de apoio para os cards/relatórios do dashboard
  04_categorias_rg_ua.sql      -- tabelas categorias/UA + colunas rg/categoria/ua em funcionarios
  05_carga_planilha.sql        -- carga em massa de funcionários a partir de planilha (staging + insert)

historico/
  01_ddl_sistema_rh_sem_rhusuarios.sql  -- versão inicial da DDL (antes de renomear USUARIOS -> RH_USUARIOS)
  04_carga_planilha_v1.sql              -- primeiras versões do script de carga, mantidas como referência
  04_carga_planilha_v2.sql
  04_carga_planilha_v3.sql
```

## Ordem de execução

Rodar os scripts da pasta `sql/` **em ordem numérica** (01 a 05). O script 05 (carga da planilha) depende das tabelas criadas no 04.

Requisitos: Oracle 12c ou superior (usa colunas `GENERATED ALWAYS AS IDENTITY`) e uma instância do Oracle APEX para a camada de interface (não incluída neste repositório).

## Observações

- Os dados de exemplo inseridos nos scripts (setores, cargos, categorias) são fictícios, usados apenas para testar o APEX rapidamente.
- Autenticação de usuários é feita pelo esquema de autenticação do próprio APEX (ou LDAP/SSO), não por senha armazenada em tabela.
- Este repositório contém apenas os scripts de banco de dados (DDL/PL-SQL). O app do APEX (páginas, processos, relatórios) deve ser exportado separadamente do Application Builder, se for versionado também.
