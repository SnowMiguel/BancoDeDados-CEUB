-- ============================================================================
-- PROJETO AVALIATIVO: DESAFIO PRÁTICO - A ÚLTIMA VAGA (POSTGRESQL)
-- Arquivo: sql/04_transacoes.sql
-- Objetivo:
--   - Desafio T1: Confirmação (COMMIT) e Cancelamento (ROLLBACK)
--   - Desafio T2: Disputa pela última vaga em READ COMMITTED (Sessões A e B)
-- ============================================================================

SET search_path TO lab_inscricoes, public;

-- ============================================================================
-- PARTE 1: DESAFIO T1 — CONFIRMAÇÃO E CANCELAMENTO (ATOMICIDADE E DURABILIDADE)
-- Executar sequencialmente em uma única sessão.
-- ============================================================================

-- 1.1 Estado inicial da atividade 3 antes dos testes
SELECT id_atividade, titulo, capacidade, local_sala
FROM lab_inscricoes.atividades
WHERE id_atividade = 3;

-- 1.2 Teste de ROLLBACK (Atomicidade: desfaz a alteração por inteiro)
BEGIN;

UPDATE lab_inscricoes.atividades
SET local_sala = 'Auditório Principal (Teste Rollback)'
WHERE id_atividade = 3;

-- Dentro da própria transação, a alteração pendente já é visível:
SELECT id_atividade, titulo, local_sala
FROM lab_inscricoes.atividades
WHERE id_atividade = 3;

ROLLBACK;

-- Após o ROLLBACK, o registro retorna exatamente ao estado anterior:
SELECT id_atividade, titulo, local_sala
FROM lab_inscricoes.atividades
WHERE id_atividade = 3;

-- 1.3 Teste de COMMIT (Durabilidade: efetiva e persiste a alteração)
BEGIN;

UPDATE lab_inscricoes.atividades
SET local_sala = 'Lab 03 - Bloco C (Confirmado)'
WHERE id_atividade = 3;

COMMIT;

-- Após o COMMIT, a alteração torna-se permanente e visível a todas as sessões:
SELECT id_atividade, titulo, local_sala
FROM lab_inscricoes.atividades
WHERE id_atividade = 3;


-- ============================================================================
-- PARTE 2: DESAFIO T2 — DISPUTA PELA ÚLTIMA VAGA (ISOLAMENTO READ COMMITTED)
-- ATENÇÃO: NÃO execute este bloco inteiro de uma vez!
-- Abra DUAS conexões independentes (Sessão A e Sessão B) e intercale os passos.
-- ============================================================================

/*
-------------------------------------------------------------------------------
MOMENTO 1 — [SESSÃO A]
Inicia transação, confirma nível READ COMMITTED e consulta vagas da oficina 1.
Resultado esperado: capacidade = 1, inscricoes_ativas = 0 (1 vaga livre).
-------------------------------------------------------------------------------
*/
-- [EXECUTAR NA SESSÃO A]:
BEGIN;
SHOW transaction_isolation;

SELECT
    a.id_atividade,
    a.titulo,
    a.capacidade,
    COUNT(i.id_inscricao) FILTER (WHERE i.situacao = 'ativa') AS inscricoes_ativas
FROM lab_inscricoes.atividades a
LEFT JOIN lab_inscricoes.inscricoes i
    ON a.id_atividade = i.id_atividade
WHERE a.id_atividade = 1
GROUP BY a.id_atividade, a.titulo, a.capacidade;


/*
-------------------------------------------------------------------------------
MOMENTO 2 — [SESSÃO B] (Antes de a Sessão A dar COMMIT!)
Inicia transação simultânea e consulta vagas da mesma oficina 1.
Resultado esperado: como A ainda não deu COMMIT, B também lê inscricoes_ativas = 0!
-------------------------------------------------------------------------------
*/
-- [EXECUTAR NA SESSÃO B]:
BEGIN;
SHOW transaction_isolation;

SELECT
    a.id_atividade,
    a.titulo,
    a.capacidade,
    COUNT(i.id_inscricao) FILTER (WHERE i.situacao = 'ativa') AS inscricoes_ativas
FROM lab_inscricoes.atividades a
LEFT JOIN lab_inscricoes.inscricoes i
    ON a.id_atividade = i.id_atividade
WHERE a.id_atividade = 1
GROUP BY a.id_atividade, a.titulo, a.capacidade;


/*
-------------------------------------------------------------------------------
MOMENTO 3 — [SESSÃO A]
Com base na leitura anterior (0 < 1), insere a inscrição da estudante 1 (Ana).
-------------------------------------------------------------------------------
*/
-- [EXECUTAR NA SESSÃO A]:
INSERT INTO lab_inscricoes.inscricoes (id_estudante, id_atividade, situacao)
VALUES (1, 1, 'ativa');


/*
-------------------------------------------------------------------------------
MOMENTO 4 — [SESSÃO B] (Ainda antes do COMMIT de A!)
Com base na própria leitura anterior (0 < 1), insere a inscrição do estudante 2 (Bruno).
Observação importante: o PostgreSQL NÃO bloqueia B, pois são tuplas novas
diferentes (id_estudante = 1 vs id_estudante = 2).
-------------------------------------------------------------------------------
*/
-- [EXECUTAR NA SESSÃO B]:
INSERT INTO lab_inscricoes.inscricoes (id_estudante, id_atividade, situacao)
VALUES (2, 1, 'ativa');


/*
-------------------------------------------------------------------------------
MOMENTO 5 — [SESSÃO A]
Confirma a transação de A.
-------------------------------------------------------------------------------
*/
-- [EXECUTAR NA SESSÃO A]:
COMMIT;


/*
-------------------------------------------------------------------------------
MOMENTO 6 — [SESSÃO B]
Confirma a transação de B.
-------------------------------------------------------------------------------
*/
-- [EXECUTAR NA SESSÃO B]:
COMMIT;


/*
-------------------------------------------------------------------------------
MOMENTO 7 — [AUDITORIA EM QUALQUER SESSÃO]
Verifica o estado final da oficina 1 após ambas as confirmações.
Resultado observado: capacidade = 1, mas inscricoes_ativas = 2 (vagas = -1)!
-------------------------------------------------------------------------------
*/
-- [EXECUTAR PARA VERIFICAÇÃO FINAL]:
SELECT
    a.id_atividade,
    a.titulo,
    a.capacidade,
    COUNT(i.id_inscricao) FILTER (WHERE i.situacao = 'ativa') AS inscricoes_ativas,
    (a.capacidade - COUNT(i.id_inscricao) FILTER (WHERE i.situacao = 'ativa')) AS vagas_disponiveis
FROM lab_inscricoes.atividades a
LEFT JOIN lab_inscricoes.inscricoes i
    ON a.id_atividade = i.id_atividade
WHERE a.id_atividade = 1
GROUP BY a.id_atividade, a.titulo, a.capacidade;

SELECT
    i.id_inscricao,
    e.id_estudante,
    e.nome AS estudante,
    i.situacao,
    i.data_inscricao
FROM lab_inscricoes.inscricoes i
JOIN lab_inscricoes.estudantes e
    ON e.id_estudante = i.id_estudante
WHERE i.id_atividade = 1
ORDER BY i.id_inscricao;

-- Comando auxiliar caso deseje resetar apenas a atividade 1 para repetir T2:
-- DELETE FROM lab_inscricoes.inscricoes WHERE id_atividade = 1;