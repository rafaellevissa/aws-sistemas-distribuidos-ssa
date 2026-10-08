-- Execute este script no seu MySQL (RDS) para criar a tabela usada pela API.
CREATE DATABASE IF NOT EXISTS aula_pratica_db;
USE aula_pratica_db;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  foto_url VARCHAR(500) NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
