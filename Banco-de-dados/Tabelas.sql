CREATE DATABASE roadvizor;

USE roadvizor;

CREATE TABLE endereco (
    id_endereco INT PRIMARY KEY,
    cep CHAR(8),
    logradouro VARCHAR(120),
    bairro VARCHAR(60),
    localidade VARCHAR(60),
    uf CHAR(2),
    numero VARCHAR(20),
    complemento VARCHAR(60),
    km VARCHAR(20),
    sentido VARCHAR(30)
);

CREATE TABLE empresa (
    id_empresa INT PRIMARY KEY,
    endereco_id INT,
    cnpj CHAR(14),
    razao_social VARCHAR(120),
    nome_fantasia VARCHAR(120),
    email VARCHAR(255),
    criado_em DATETIME,
    atualizado_em DATETIME,

    FOREIGN KEY (endereco_id)
	REFERENCES endereco(id_endereco)
);

CREATE TABLE usuario (
    id_usuario INT PRIMARY KEY,
    empresa_id INT,
    supervisor_id INT,
    nome VARCHAR(255),
    email VARCHAR(255),
    senha VARCHAR(255),
    nivel_acesso TINYINT,
    criado_em DATETIME,
    atualizado_em DATETIME,

    FOREIGN KEY (empresa_id)
    REFERENCES empresa(id_empresa),

    FOREIGN KEY (supervisor_id)
	REFERENCES usuario(id_usuario)
);


CREATE TABLE componente (
    id_componente INT PRIMARY KEY,
    nome VARCHAR(60),
    unidade_medida VARCHAR(20),
    depende_de VARCHAR(60),
    criado_em DATETIME,
    atualizado_em DATETIME
);


CREATE TABLE servidor (
    id_servidor INT PRIMARY KEY,
    empresa_id INT,
    endereco_id INT,
    endereco_mac CHAR(12),
    apelido VARCHAR(60),
    modelo VARCHAR(60),
    criado_em DATETIME,
    atualizado_em DATETIME,

    FOREIGN KEY (empresa_id)
	REFERENCES empresa(id_empresa),

    FOREIGN KEY (endereco_id)
	REFERENCES endereco(id_endereco)
);


CREATE TABLE servidor_componente (
    servidor_id INT,
    empresa_id INT,
    componente_id INT,
    limite_max DECIMAL(10,3),
    limite_min DECIMAL(10,3),
    capacidade_total DECIMAL(10,3),
    monitorado TINYINT,
    criado_em DATETIME,
    atualizado_em DATETIME,

    PRIMARY KEY (servidor_id, componente_id),

    FOREIGN KEY (servidor_id)
	REFERENCES servidor(id_servidor),

    FOREIGN KEY (empresa_id)
	REFERENCES empresa(id_empresa),

    FOREIGN KEY (componente_id)
	REFERENCES componente(id_componente)
);