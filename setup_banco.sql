-- ☕ Café Conecta — Script SQL completo
-- Execute no DBeaver (banco cafe_conecta) ou no console do Neon

-- 1. USUÁRIOS
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    tipo VARCHAR(30) NOT NULL,
    empresa VARCHAR(150),
    telefone VARCHAR(20),
    regiao VARCHAR(100),
    plano VARCHAR(20) DEFAULT 'gratuito',
    verificado BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMP DEFAULT NOW()
);

-- 2. CAFÉS / LOTES
CREATE TABLE IF NOT EXISTS cafes (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo VARCHAR(50) NOT NULL,
    classificacao VARCHAR(50) NOT NULL,
    quantidade INTEGER NOT NULL,
    bebida VARCHAR(50),
    peneira VARCHAR(20),
    safra VARCHAR(20),
    regiao VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    fazenda VARCHAR(150),
    preco_saca DECIMAL(10,2),
    score_qualidade INTEGER,
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT NOW()
);

-- 3. PROPOSTAS
CREATE TABLE IF NOT EXISTS propostas (
    id SERIAL PRIMARY KEY,
    cafe_id INTEGER REFERENCES cafes(id) ON DELETE CASCADE,
    de_usuario_id INTEGER REFERENCES usuarios(id),
    para_usuario_id INTEGER REFERENCES usuarios(id),
    preco_ofertado DECIMAL(10,2),
    quantidade INTEGER,
    condicao_pagamento VARCHAR(50),
    mensagem TEXT,
    status VARCHAR(20) DEFAULT 'aguardando',
    criado_em TIMESTAMP DEFAULT NOW()
);

-- 4. MENSAGENS
CREATE TABLE IF NOT EXISTS mensagens (
    id SERIAL PRIMARY KEY,
    de_usuario_id INTEGER REFERENCES usuarios(id),
    para_usuario_id INTEGER REFERENCES usuarios(id),
    texto TEXT NOT NULL,
    lida BOOLEAN DEFAULT FALSE,
    criado_em TIMESTAMP DEFAULT NOW()
);

-- 5. AVALIAÇÕES
CREATE TABLE IF NOT EXISTS avaliacoes (
    id SERIAL PRIMARY KEY,
    proposta_id INTEGER REFERENCES propostas(id),
    avaliador_id INTEGER REFERENCES usuarios(id),
    avaliado_id INTEGER REFERENCES usuarios(id),
    nota INTEGER CHECK (nota BETWEEN 1 AND 5),
    comentario TEXT,
    criado_em TIMESTAMP DEFAULT NOW()
);

-- 6. ALERTAS
CREATE TABLE IF NOT EXISTS alertas (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
    tipo_cafe VARCHAR(50),
    regiao VARCHAR(100),
    preco_maximo DECIMAL(10,2),
    score_minimo INTEGER,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT NOW()
);

-- 7. FAVORITOS
CREATE TABLE IF NOT EXISTS favoritos (
    id SERIAL PRIMARY KEY,
    usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
    cafe_id INTEGER REFERENCES cafes(id) ON DELETE CASCADE,
    criado_em TIMESTAMP DEFAULT NOW()
);

-- ──────────────────────────────────
-- DADOS DE TESTE
-- ──────────────────────────────────

INSERT INTO usuarios (nome, email, senha, tipo, empresa, plano, verificado) VALUES
('João Pedro Silva', 'joao@cafesuldeminas.com.br', '123456', 'corretor', 'Café Sul de Minas', 'profissional', TRUE),
('Cooperativa Cerrado', 'cooperativa@cerrado.com.br', '123456', 'corretor', 'Coop. Cerrado Mineiro', 'premium', TRUE),
('Maria Fazenda', 'maria@fazenda.com.br', '123456', 'produtor', 'Fazenda Santa Maria', 'basico', FALSE),
('Ana Torrefação', 'ana@torrefacao.com.br', '123456', 'comprador', 'Torrefação Aroma', 'gratuito', FALSE)
ON CONFLICT (email) DO NOTHING;

INSERT INTO cafes (usuario_id, tipo, classificacao, quantidade, bebida, peneira, safra, regiao, cidade, fazenda, preco_saca, score_qualidade, latitude, longitude)
SELECT u.id, 'Arábica', 'Tipo 6', 1250, 'Mole', '16/18', '2024/2025', 'Sul de Minas', 'Patrocínio', 'Fazenda Boa Vista', 980.00, 84, -18.9402, -46.9936
FROM usuarios u WHERE u.email = 'joao@cafesuldeminas.com.br'
ON CONFLICT DO NOTHING;

INSERT INTO cafes (usuario_id, tipo, classificacao, quantidade, bebida, peneira, safra, regiao, cidade, fazenda, preco_saca, score_qualidade, latitude, longitude)
SELECT u.id, 'Arábica', 'Especial', 300, 'Estritamente Mole', '18 acima', '2024/2025', 'Cerrado Mineiro', 'Monte Carmelo', 'Sítio Harmonia', 1800.00, 91, -18.7258, -47.4999
FROM usuarios u WHERE u.email = 'cooperativa@cerrado.com.br'
ON CONFLICT DO NOTHING;

-- Verifica se tudo foi criado
SELECT 'usuarios' as tabela, COUNT(*) as registros FROM usuarios
UNION ALL SELECT 'cafes', COUNT(*) FROM cafes
UNION ALL SELECT 'propostas', COUNT(*) FROM propostas
UNION ALL SELECT 'mensagens', COUNT(*) FROM mensagens
UNION ALL SELECT 'avaliacoes', COUNT(*) FROM avaliacoes
UNION ALL SELECT 'alertas', COUNT(*) FROM alertas
UNION ALL SELECT 'favoritos', COUNT(*) FROM favoritos;
