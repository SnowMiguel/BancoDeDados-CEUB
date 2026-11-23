-- ============================================================================
-- PROJETO AVALIATIVO: DESAFIO PRÁTICO - A ÚLTIMA VAGA (POSTGRESQL)
-- Arquivo: sql/03_permissoes.sql
-- Objetivo: Desafio A2 - Controle de acesso, perfis (roles) e validação
-- ============================================================================

SET search_path TO lab_inscricoes, public;

-- ----------------------------------------------------------------------------
-- 1. LIMPEZA SEGURA DOS PERFIS (PERMITE REEXECUTAR O SCRIPT DO ZERO)
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'administrador') THEN
        REVOKE ALL PRIVILEGES ON DATABASE bd_semana_tec FROM administrador;
        DROP OWNED BY administrador;
        DROP ROLE administrador;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'operador') THEN
        REVOKE ALL PRIVILEGES ON DATABASE bd_semana_tec FROM operador;
        DROP OWNED BY operador;
        DROP ROLE operador;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'consulta') THEN
        REVOKE ALL PRIVILEGES ON DATABASE bd_semana_tec FROM consulta;
        DROP OWNED BY consulta;
        DROP ROLE consulta;
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 2. CRIAÇÃO DOS TRÊS PERFIS EXIGIDOS (CREATE ROLE)
-- ----------------------------------------------------------------------------
CREATE ROLE administrador LOGIN PASSWORD 'adm12345678';
CREATE ROLE operador      LOGIN PASSWORD 'opera123456';
CREATE ROLE consulta      LOGIN PASSWORD 'consult1234';

-- ----------------------------------------------------------------------------
-- 3. REVOGAÇÃO PREVENTIVA DE PRIVILÉGIOS PÚBLICOS (MENOR PRIVILÉGIO)
-- ----------------------------------------------------------------------------
REVOKE ALL ON DATABASE bd_semana_tec FROM PUBLIC;
REVOKE ALL ON SCHEMA lab_inscricoes FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA lab_inscricoes FROM PUBLIC;

-- ----------------------------------------------------------------------------
-- 4. CONCESSÃO DE ACESSO AO BANCO (CONNECT) E AO ESQUEMA (USAGE)
-- ----------------------------------------------------------------------------
GRANT CONNECT ON DATABASE bd_semana_tec TO administrador, operador, consulta;
GRANT USAGE   ON SCHEMA lab_inscricoes  TO administrador, operador, consulta;

-- ----------------------------------------------------------------------------
-- 5. DEFINIÇÃO DE PRIVILÉGIOS POR PERFIL (GRANT / REVOKE)
-- ----------------------------------------------------------------------------

-- 5.1 Perfil ADMINISTRADOR: controle total sobre o esquema lab_inscricoes e objetos
GRANT ALL PRIVILEGES ON SCHEMA lab_inscricoes TO administrador;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA lab_inscricoes TO administrador;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA lab_inscricoes TO administrador;

-- 5.2 Perfil OPERADOR:
--   - Consulta estudantes e atividades (e inscrições)
--   - Insere e altera inscrições (inclui uso da sequence de id_inscricao)
--   - SEM permissão para excluir (DELETE) atividades/estudantes/inscrições
--   - SEM permissão para alterar estruturas (DDL)
GRANT SELECT ON TABLE lab_inscricoes.estudantes TO operador;
GRANT SELECT ON TABLE lab_inscricoes.atividades TO operador;
GRANT SELECT, INSERT, UPDATE ON TABLE lab_inscricoes.inscricoes TO operador;
GRANT USAGE, SELECT ON SEQUENCE lab_inscricoes.inscricoes_id_inscricao_seq TO operador;

REVOKE DELETE, TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA lab_inscricoes FROM operador;
REVOKE CREATE ON SCHEMA lab_inscricoes FROM operador;

-- 5.3 Perfil CONSULTA: apenas leitura (SELECT) nas tabelas do esquema
GRANT SELECT ON ALL TABLES IN SCHEMA lab_inscricoes TO consulta;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA lab_inscricoes FROM consulta;
REVOKE CREATE ON SCHEMA lab_inscricoes FROM consulta;


-- ============================================================================
-- 6. BATERIA DE TESTES DE OPERAÇÕES PERMITIDAS E NEGADAS (DESAFIO A2)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TESTE 1: PERFIL CONSULTA (Apenas SELECT permitido; INSERT/DELETE negados)
-- ----------------------------------------------------------------------------
SET ROLE consulta;
SELECT current_user, session_user;

-- [PERMITIDO] Leitura nas tabelas do esquema
SELECT id_atividade, titulo, capacidade FROM lab_inscricoes.atividades;

-- [NEGADO - Esperado: ERROR: permission denied for table inscricoes]
INSERT INTO lab_inscricoes.inscricoes (id_estudante, id_atividade, situacao)
VALUES (9, 3, 'ativa');

-- [NEGADO - Esperado: ERROR: permission denied for table estudantes]
DELETE FROM lab_inscricoes.estudantes WHERE id_estudante = 10;

RESET ROLE;


-- ----------------------------------------------------------------------------
-- TESTE 2: PERFIL OPERADOR (SELECT + INSERT/UPDATE em inscricoes; DELETE/DDL negados)
-- ----------------------------------------------------------------------------
SET ROLE operador;
SELECT current_user, session_user;

-- [PERMITIDO] Consultar estudantes e atividades
SELECT id_estudante, nome FROM lab_inscricoes.estudantes LIMIT 3;

-- [PERMITIDO] Inserir nova inscrição na oficina 3 (capacidade 5)
INSERT INTO lab_inscricoes.inscricoes (id_estudante, id_atividade, situacao)
VALUES (9, 3, 'ativa');

-- [PERMITIDO] Alterar inscrição (ex.: cancelar inscrição recém-criada)
UPDATE lab_inscricoes.inscricoes
SET situacao = 'cancelada', data_cancelamento = CURRENT_TIMESTAMP
WHERE id_estudante = 9 AND id_atividade = 3 AND situacao = 'ativa';

-- [NEGADO - Esperado: ERROR: permission denied for table atividades]
DELETE FROM lab_inscricoes.atividades WHERE id_atividade = 3;

-- [NEGADO - Esperado: ERROR: permission denied for table estudantes]
DELETE FROM lab_inscricoes.estudantes WHERE id_estudante = 10;

-- [NEGADO - Esperado: ERROR: must be owner of table atividades (ou permission denied)]
ALTER TABLE lab_inscricoes.atividades ADD COLUMN observacao TEXT;

RESET ROLE;


-- ----------------------------------------------------------------------------
-- TESTE 3: PERFIL ADMINISTRADOR (Controle sobre esquema e objetos)
-- ----------------------------------------------------------------------------
SET ROLE administrador;
SELECT current_user, session_user;

-- [PERMITIDO] Criar e remover objeto temporário dentro do esquema lab_inscricoes
CREATE TABLE lab_inscricoes.auditoria_teste_admin (
    id SERIAL PRIMARY KEY,
    evento VARCHAR(100) NOT NULL
);
DROP TABLE lab_inscricoes.auditoria_teste_admin;

RESET ROLE;