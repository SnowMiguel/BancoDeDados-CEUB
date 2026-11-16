-- ============================================================================
-- PROJETO AVALIATIVO: DESAFIO PRÁTICO - A ÚLTIMA VAGA (POSTGRESQL)
-- Arquivo: sql/01_estrutura.sql
-- Objetivo: Criação do esquema isolado e das tabelas base (Desafio A1)
-- ============================================================================

-- Garante reprodutibilidade limpa ao reiniciar o laboratório
DROP SCHEMA IF EXISTS lab_inscricoes CASCADE;
CREATE SCHEMA lab_inscricoes;

SET search_path TO lab_inscricoes, public;

-- 1. Tabela de Estudantes
CREATE TABLE lab_inscricoes.estudantes (
    id_estudante SERIAL PRIMARY KEY,
    nome         VARCHAR(120) NOT NULL,
    email        VARCHAR(150) NOT NULL UNIQUE,
    curso        VARCHAR(80)  NOT NULL,
    ativo        BOOLEAN      NOT NULL DEFAULT TRUE,
    criado_em    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tabela de Atividades (Oficinas da Semana de Tecnologia)
CREATE TABLE lab_inscricoes.atividades (
    id_atividade SERIAL PRIMARY KEY,
    titulo       VARCHAR(150) NOT NULL,
    instrutor    VARCHAR(120) NOT NULL,
    capacidade   INTEGER      NOT NULL,
    local_sala   VARCHAR(60)  NOT NULL,
    data_horario TIMESTAMP    NOT NULL,
    CONSTRAINT ck_atividades_capacidade_positiva CHECK (capacidade > 0)
);

-- 3. Tabela de Inscrições
CREATE TABLE lab_inscricoes.inscricoes (
    id_inscricao   SERIAL PRIMARY KEY,
    id_estudante   INTEGER     NOT NULL,
    id_atividade   INTEGER     NOT NULL,
    situacao       VARCHAR(15) NOT NULL DEFAULT 'ativa',
    data_inscricao TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_cancelamento TIMESTAMP NULL,

    CONSTRAINT fk_inscricoes_estudante
        FOREIGN KEY (id_estudante)
        REFERENCES lab_inscricoes.estudantes (id_estudante)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_inscricoes_atividade
        FOREIGN KEY (id_atividade)
        REFERENCES lab_inscricoes.atividades (id_atividade)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT ck_inscricoes_situacao
        CHECK (situacao IN ('ativa', 'cancelada')),

    CONSTRAINT ck_inscricoes_cancelamento_coerente
        CHECK (
            (situacao = 'ativa' AND data_cancelamento IS NULL)
            OR
            (situacao = 'cancelada' AND data_cancelamento IS NOT NULL)
        )
);

-- Índices para chaves estrangeiras (PostgreSQL não indexa FKs automaticamente)
CREATE INDEX idx_inscricoes_id_atividade
    ON lab_inscricoes.inscricoes (id_atividade);

CREATE INDEX idx_inscricoes_id_estudante
    ON lab_inscricoes.inscricoes (id_estudante);

-- Índice único parcial: impede duas inscrições ATIVAS do mesmo estudante
-- na mesma oficina, mas permite histórico de inscrições canceladas.
CREATE UNIQUE INDEX uq_inscricao_ativa_estudante_atividade
    ON lab_inscricoes.inscricoes (id_estudante, id_atividade)
    WHERE situacao = 'ativa';
