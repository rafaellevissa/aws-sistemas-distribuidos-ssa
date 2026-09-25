const pool = require('../config/db');

// CRUD simples da tabela `usuarios`.

async function listar(req, res) {
  try {
    const [rows] = await pool.query(
      'SELECT id, nome, email, foto_url, criado_em FROM usuarios ORDER BY id DESC'
    );
    res.json(rows);
  } catch (error) {
    console.error('Erro ao listar usuarios:', error);
    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
}

async function buscarPorId(req, res) {
  try {
    const { id } = req.params;
    const [rows] = await pool.query('SELECT * FROM usuarios WHERE id = ?', [id]);

    if (rows.length === 0) {
      return res.status(404).json({ mensagem: 'Usuario nao encontrado' });
    }

    res.json(rows[0]);
  } catch (error) {
    console.error('Erro ao buscar usuario:', error);
    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
}

async function criar(req, res) {
  try {
    const { nome, email, foto_url } = req.body;

    if (!nome || !email) {
      return res.status(400).json({ mensagem: 'Os campos nome e email sao obrigatorios' });
    }

    const [result] = await pool.query(
      'INSERT INTO usuarios (nome, email, foto_url) VALUES (?, ?, ?)',
      [nome, email, foto_url || null]
    );

    res.status(201).json({ id: result.insertId, nome, email, foto_url: foto_url || null });
  } catch (error) {
    console.error('Erro ao criar usuario:', error);

    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ mensagem: 'Ja existe um usuario com esse email' });
    }

    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
}

async function atualizar(req, res) {
  try {
    const { id } = req.params;
    const { nome, email, foto_url } = req.body;

    const [result] = await pool.query(
      'UPDATE usuarios SET nome = COALESCE(?, nome), email = COALESCE(?, email), foto_url = COALESCE(?, foto_url) WHERE id = ?',
      [nome, email, foto_url, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ mensagem: 'Usuario nao encontrado' });
    }

    res.json({ mensagem: 'Usuario atualizado com sucesso' });
  } catch (error) {
    console.error('Erro ao atualizar usuario:', error);
    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
}

async function remover(req, res) {
  try {
    const { id } = req.params;
    const [result] = await pool.query('DELETE FROM usuarios WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ mensagem: 'Usuario nao encontrado' });
    }

    res.status(204).send();
  } catch (error) {
    console.error('Erro ao remover usuario:', error);
    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
}

module.exports = { listar, buscarPorId, criar, atualizar, remover };
