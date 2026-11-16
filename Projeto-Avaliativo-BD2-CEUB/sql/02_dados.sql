-- ============================================================================
-- PROJETO AVALIATIVO: DESAFIO PRÁTICO - A ÚLTIMA VAGA (POSTGRESQL)
-- Arquivo: sql/02_dados.sql
-- Objetivo: Carga de dados fictícios e consulta de verificação inicial (A1)
-- ============================================================================

SET search_path TO lab_inscricoes, public;

-- Limpa dados anteriores e reinicia sequências para reprodutibilidade
TRUNCATE TABLE
    lab_inscricoes.inscricoes,
    lab_inscricoes.atividades,
    lab_inscricoes.estudantes
RESTART IDENTITY CASCADE;

-- 1. Inserção de 10 estudantes fictícios
INSERT INTO lab_inscricoes.estudantes (nome, email, curso, ativo) VALUES
('Ana Clara Souza',      'ana.souza@lab.edu.br',      'Ciência da Computação', TRUE),
('Bruno Henrique Lima',  'bruno.lima@lab.edu.br',     'Análise e Desenv. de Sistemas', TRUE),
('Carla Mendes Rocha',   'carla.rocha@lab.edu.br',    'Engenharia de Software', TRUE),
('Diego Alves Martins',  'diego.martins@lab.edu.br',  'Ciência da Computação', TRUE),
('Eduarda Silva Costa',  'eduarda.costa@lab.edu.br',  'Sistemas de Informação', TRUE),
('Felipe Oliveira Dias', 'felipe.dias@lab.edu.br',    'Análise e Desenv. de Sistemas', TRUE),
('Gabriela Nunes Pires', 'gabriela.pires@lab.edu.br', 'Ciência da Computação', TRUE),
('Hugo Ferreira Santos', 'hugo.santos@lab.edu.br',    'Engenharia de Software', TRUE),
('Isabela Gomes Castro', 'isabela.castro@lab.edu.br', 'Sistemas de Informação', TRUE),
('João Pedro Teixeira',  'joao.teixeira@lab.edu.br',  'Análise e Desenv. de Sistemas', TRUE);

-- 2. Inserção de 3 atividades (oficinas)
-- ATENÇÃO: id_atividade = 1 possui capacidade = 1 (cenário crítico da última vaga)
INSERT INTO lab_inscricoes.atividades (titulo, instrutor, capacidade, local_sala, data_horario) VALUES
('Oficina Prática: Controle de Concorrência no PostgreSQL', 'Prof. Carlos Nogueira', 1, 'Lab 01 - Bloco B', '2026-11-20 19:00:00'),
('Workshop: Tuning de Consultas e Índices B+',               'Profa. Marina Duarte',  3, 'Lab 02 - Bloco B', '2026-11-21 14:00:00'),
('Minicurso: Administração, Roles e Backup em Produção',     'Prof. Rafael Tavares',  5, 'Lab 03 - Bloco C', '2026-11-21 19:00:00');

-- 3. Inserção de inscrições iniciais apenas nas oficinas 2 e 3
-- A oficina 1 permanece com 0 inscritos (1 vaga disponível para o teste T2)
INSERT INTO lab_inscricoes.inscricoes (id_estudante, id_atividade, situacao, data_inscricao, data_cancelamento) VALUES
(4, 2, 'ativa',     '2026-11-14 10:00:00', NULL),
(5, 2, 'ativa',     '2026-11-14 10:05:00', NULL),
(6, 2, 'cancelada', '2026-11-14 10:10:00', '2026-11-14 11:00:00'),
(7, 3, 'ativa',     '2026-11-14 10:15:00', NULL),
(8, 3, 'ativa',     '2026-11-14 10:20:00', NULL);

-- 4. Consulta de verificação: capacidade x inscrições ativas x vagas disponíveis
SELECT
    a.id_atividade,
    a.titulo,
    a.capacidade,
    COUNT(i.id_inscricao) FILTER (WHERE i.situacao = 'ativa')     AS inscricoes_ativas,
    COUNT(i.id_inscricao) FILTER (WHERE i.situacao = 'cancelada') AS inscricoes_canceladas,
    (a.capacidade - COUNT(i.id_inscricao) FILTER (WHERE i.situacao = 'ativa')) AS vagas_disponiveis
FROM lab_inscricoes.atividades a
LEFT JOIN lab_inscricoes.inscricoes i
    ON a.id_atividade = i.id_atividade
GROUP BY a.id_atividade, a.titulo, a.capacidade
ORDER BY a.id_atividade;