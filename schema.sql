-- ============================================================================
-- PROJETO: AUTORELACIONAMENTO, ENTIDADE FRACA E AGREGACAO EM POSTGRESQL
-- Alunos: Giovanna Secundo Penso, Carlos Vitor Camara Gomes,
--         Adam Lucas Smith de Carvalho, Vinicius De Oliveira Mateus
-- ============================================================================

-- Tabela de Funcionarios com Autorelacionamento (Hierarquia)
CREATE TABLE funcionario (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    supervisor_id INTEGER REFERENCES funcionario(id)
);

-- Dependentes (Entidade Fraca) - existem apenas vinculados a um funcionario
CREATE TABLE dependente (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    funcionario_id INTEGER NOT NULL,
    CONSTRAINT fk_funcionario
        FOREIGN KEY (funcionario_id)
        REFERENCES funcionario(id)
        ON DELETE CASCADE
);

-- Tabela de Projetos
CREATE TABLE projeto (
    id SERIAL PRIMARY KEY,
    nome_projeto VARCHAR(100) NOT NULL
);

-- Agregacao: Alocacao de Equipamentos em Projetos por Funcionario
CREATE TABLE alocacao_equipamento (
    id SERIAL PRIMARY KEY,
    funcionario_id INTEGER NOT NULL,
    projeto_id INTEGER NOT NULL,
    nome_equipamento VARCHAR(100) NOT NULL,
    data_alocacao DATE DEFAULT CURRENT_DATE,
    FOREIGN KEY (funcionario_id) REFERENCES funcionario(id) ON DELETE CASCADE,
    FOREIGN KEY (projeto_id) REFERENCES projeto(id) ON DELETE CASCADE,
    CONSTRAINT uk_alocacao UNIQUE (funcionario_id, projeto_id, nome_equipamento)
);

-- ============================================================================
-- DADOS DE TESTE
-- ============================================================================

INSERT INTO funcionario (nome, supervisor_id) VALUES
('Ana Silva', NULL),
('Carlos Santos', 1),
('Maria Oliveira', 1),
('Joao Pereira', 2),
('Fernanda Costa', 2);

INSERT INTO dependente (nome, funcionario_id) VALUES
('Filho - Ana', 1),
('Filha - Ana', 1),
('Esposa - Carlos', 2),
('Filho - Maria', 3),
('Filho - Joao', 4);

INSERT INTO projeto (nome_projeto) VALUES
('Sistema Web 2024'),
('App Mobile'),
('Infraestrutura Cloud'),
('BI Analytics');

INSERT INTO alocacao_equipamento (funcionario_id, projeto_id, nome_equipamento) VALUES
(1, 1, 'Laptop Dell XPS'),
(1, 2, 'Monitor 4K LG'),
(2, 1, 'Laptop Lenovo'),
(2, 3, 'Servidor Linux'),
(3, 2, 'iPhone 15 Pro'),
(4, 1, 'Mouse Logitech'),
(4, 3, 'Webcam Full HD'),
(5, 4, 'Tablet Samsung'),
(5, 1, 'Teclado Mecanico');

-- ============================================================================
-- QUERIES PARA DEMONSTRACAO
-- ============================================================================

-- QUERY 1: AUTORELACIONAMENTO
-- Mostra cada funcionario ao lado do seu supervisor (LEFT JOIN na mesma tabela)
SELECT
    f.nome AS "Funcionario",
    COALESCE(s.nome, 'CEO') AS "Supervisor"
FROM funcionario f
LEFT JOIN funcionario s ON f.supervisor_id = s.id
ORDER BY f.id;

-- QUERY 2: ENTIDADE FRACA
-- Mostra os dependentes de cada funcionario
SELECT
    f.nome AS "Funcionario",
    COUNT(d.id) AS "Qtd Dependentes",
    STRING_AGG(d.nome, ', ') AS "Dependentes"
FROM funcionario f
LEFT JOIN dependente d ON f.id = d.funcionario_id
GROUP BY f.id, f.nome
ORDER BY f.nome;

-- QUERY 3: AGREGACAO
-- Mostra os equipamentos alocados por (Funcionario + Projeto)
SELECT
    f.nome AS "Funcionario",
    p.nome_projeto AS "Projeto",
    STRING_AGG(ae.nome_equipamento, ', ') AS "Equipamentos",
    COUNT(ae.id) AS "Qtd"
FROM alocacao_equipamento ae
JOIN funcionario f ON ae.funcionario_id = f.id
JOIN projeto p ON ae.projeto_id = p.id
GROUP BY ae.funcionario_id, ae.projeto_id, f.nome, p.nome_projeto
ORDER BY f.nome, p.nome_projeto;

-- QUERY 4: ORGANOGRAMA (CTE RECURSIVA - BONUS)
-- Mostra a hierarquia completa em formato de arvore
WITH RECURSIVE organograma AS (
    SELECT id, nome, supervisor_id, 1 AS nivel
    FROM funcionario
    WHERE supervisor_id IS NULL
    UNION ALL
    SELECT f.id, f.nome, f.supervisor_id, o.nivel + 1
    FROM funcionario f
    INNER JOIN organograma o ON f.supervisor_id = o.id
)
SELECT REPEAT('  ', nivel - 1) || 'L- ' || nome AS "Organograma"
FROM organograma
ORDER BY nivel, nome;

-- ============================================================================
-- TESTE ON DELETE CASCADE
-- Execute linha por linha para demonstrar na apresentacao:
-- ============================================================================

-- Passo 1: Ver dependentes ANTES de deletar
-- SELECT * FROM dependente;

-- Passo 2: Deletar o funcionario Carlos (id=2)
-- DELETE FROM funcionario WHERE id = 2;

-- Passo 3: Ver dependentes DEPOIS - "Esposa - Carlos" deve sumir!
-- SELECT * FROM dependente;
