
CREATE DATABASE IF NOT EXISTS roadvizor;

USE roadvizor;

-- DROP DATABASE roadvizor;

-- OBS: muitas das decisões tomadas ao criar esta tabela foram motivadas com base na API viaCEP
-- disponível em: https://viacep.com.br.
-- e no entendimento de que ambos os endereços de CCOs e Pedágios poderão ser guardados nesta tabela.

CREATE TABLE IF NOT EXISTS endereco(
    id_endereco INT PRIMARY KEY AUTO_INCREMENT,

    -- campos úteis para o viaCEP
    cep CHAR(8) NOT NULL,
    logradouro VARCHAR(120) NULL,
    bairro VARCHAR(60) NULL,
    localidade VARCHAR(60) NOT NULL,
    uf CHAR(2) NOT NULL,

    -- campos úteis no contexto Empresa/CCO
    numero VARCHAR(20) NULL,
    complemento VARCHAR(60) NULL,

    -- campos úteis no contexto Pórtico/Servidor
    km VARCHAR(20) NULL,
    sentido VARCHAR(30) NULL,

    -- campos utilizados pelo monitoramento climático
    latitude DECIMAL(10,7) NULL,
    longitude DECIMAL(10,7) NULL
);

INSERT INTO endereco (
    cep, logradouro, bairro, localidade, uf, numero, km, sentido
) VALUES (
    '01001000',
    'Praça da Sé',
    'Sé',
    'São Paulo',
    'SP',
    '100',
    'KM 15',
    'Norte'
);

CREATE TABLE IF NOT EXISTS empresa(
    id_empresa INT PRIMARY KEY AUTO_INCREMENT,

    -- endereco_id INT NOT NULL,

    cnpj CHAR(14) NOT NULL UNIQUE,
    razao_social VARCHAR(120) NOT NULL,
    nome_fantasia VARCHAR(120) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,

    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

    -- CONSTRAINT fk_empresa_endereco FOREIGN KEY (endereco_id)
    -- REFERENCES endereco(id_endereco)
);

CREATE TABLE IF NOT EXISTS usuario(
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    empresa_id INT NOT NULL,
    supervisor_id INT NULL,

    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    nivel_acesso TINYINT NOT NULL DEFAULT 2,

    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_usuario_empresa FOREIGN KEY (empresa_id)
        REFERENCES empresa(id_empresa),

    CONSTRAINT fk_usuario_usuario FOREIGN KEY (supervisor_id)
        REFERENCES usuario(id_usuario)
);

CREATE TABLE IF NOT EXISTS servidor(
    id_servidor INT NOT NULL AUTO_INCREMENT,
    empresa_id INT NOT NULL,
    endereco_id INT NOT NULL,

    endereco_mac CHAR(12) NOT NULL UNIQUE,
    apelido VARCHAR(60) NOT NULL,
    modelo VARCHAR(60) NOT NULL,

    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_servidor PRIMARY KEY (id_servidor, empresa_id),

    CONSTRAINT fk_servidor_empresa FOREIGN KEY (empresa_id)
        REFERENCES empresa(id_empresa),

    CONSTRAINT fk_servidor_endereco FOREIGN KEY (endereco_id)
        REFERENCES endereco(id_endereco)
);

CREATE TABLE IF NOT EXISTS componente(
    id_componente INT PRIMARY KEY AUTO_INCREMENT,

    nome VARCHAR(60) NOT NULL,
    unidade_medida VARCHAR(20) NOT NULL,
    depende_de VARCHAR(60) NOT NULL,

    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT chk_componente_nome CHECK(nome IN('cpu', 'ram', 'disco', 'placa_rede')),

    CONSTRAINT chk_componente_unidade_medida CHECK(unidade_medida IN(
        'pct',
        'MiB', 'GiB', 'TiB',
        'bps', 'Mbps', 'Gbps'
    ))
);

CREATE TABLE IF NOT EXISTS servidor_componente(
    servidor_id INT NOT NULL,
    empresa_id INT NOT NULL,
    componente_id INT NOT NULL,

    limite_max DECIMAL(10, 3) NOT NULL,
    limite_min DECIMAL(10, 3) NULL,
    capacidade_total DECIMAL(10, 3) NOT NULL,
    monitorado TINYINT NOT NULL DEFAULT 1,

    criado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_servidor_componente PRIMARY KEY(servidor_id, empresa_id, componente_id),

    CONSTRAINT fk_servidor_componente_servidor FOREIGN KEY (servidor_id, empresa_id)
        REFERENCES servidor(id_servidor, empresa_id),

    CONSTRAINT fk_servidor_componente_componente FOREIGN KEY (componente_id)
        REFERENCES componente(id_componente)
);

CREATE TABLE IF NOT EXISTS relatorio_ocorrencia (
    id_relatorio INT AUTO_INCREMENT PRIMARY KEY,

    servidor_id INT NOT NULL,
    usuario_id INT NOT NULL,

    tipo_ocorrencia VARCHAR(80) NOT NULL,
    recurso_afetado VARCHAR(60) NOT NULL,
    prioridade VARCHAR(20) NOT NULL,

    descricao TEXT,

    status VARCHAR(30) DEFAULT 'Pendente',

    data_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (servidor_id)
        REFERENCES servidor(id_servidor),

    FOREIGN KEY (usuario_id)
        REFERENCES usuario(id_usuario)
);

-- | Monitoramento Climático | --

CREATE TABLE IF NOT EXISTS monitoramento_climatico(
    id_clima INT PRIMARY KEY AUTO_INCREMENT,
    endereco_id INT NOT NULL,

    temperatura DECIMAL(5,2) NULL,
    umidade DECIMAL(5,2) NULL,
    velocidade_vento DECIMAL(6,2) NULL,
    direcao_vento VARCHAR(20) NULL,
    precipitacao DECIMAL(7,2) NULL,
    condicao_climatica VARCHAR(80) NULL,

    fonte_dados VARCHAR(100) NOT NULL DEFAULT 'WeatherAPI',

    coletado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_monitoramento_climatico_endereco FOREIGN KEY (endereco_id)
        REFERENCES endereco(id_endereco)
);

-- | Stored Procedure(s) | --

DELIMITER $$

CREATE PROCEDURE sp_cadastrar_empresa(
    IN in_cnpj CHAR(14),
    IN in_razao_social VARCHAR(120),
    IN in_nome_fantasia VARCHAR(120),
    IN in_email VARCHAR(255),
    IN in_senha VARCHAR(255)
)
BEGIN

    -- Tratamento de Erro na Procedure
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Erro no Cadastro de Empresa.';
    END;

    -- Corpo da Procedure
    START TRANSACTION;

        -- 1. Criar Empresa
        INSERT INTO empresa(cnpj, razao_social, nome_fantasia, email)
            VALUES (in_cnpj, in_razao_social, in_nome_fantasia, in_email);

        -- 2. Criar Usuário ADM da Empresa criada
        INSERT INTO usuario(empresa_id, nome, email, senha, nivel_acesso)
            VALUES (LAST_INSERT_ID(), in_nome_fantasia, in_email, SHA2(in_senha, 256), 1);

    COMMIT;

END$$

DELIMITER ;

-- | Inserts-padrão | --

INSERT INTO componente(nome, unidade_medida, depende_de)
    VALUES
    ('cpu', 'pct', 'psutil.cpu_percent()'),
    ('ram', 'MiB', 'psutil.virtual_memory()'),
    ('disco', 'GiB', 'psutil.disk_usage("/")'),
    ('placa_rede', 'Mbps', 'psutil.net_if_stats()');

-- [!] Rodar scripts abaixo APENAS com o root do BD.

-- CREATE USER 'roadvizor_user' IDENTIFIED BY 'sptech';
-- GRANT INSERT, SELECT, UPDATE, DELETE ON roadvizor.* TO 'roadvizor_user';
-- SHOW GRANTS FOR 'roadvizor_user';
