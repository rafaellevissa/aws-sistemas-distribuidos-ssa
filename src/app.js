require('dotenv').config();
const express = require('express');
const cors = require('cors');

const usuariosRoutes = require('./routes/usuarios.routes');
const uploadRoutes = require('./routes/upload.routes');
const requestLogger = require('./middlewares/request-logger');

const app = express();

app.use(cors());
app.use(express.json());
app.use(requestLogger());

// Rota de teste / health check
app.get('/', (req, res) => {
  res.json({ mensagem: 'API funcionando!' });
});

app.use('/usuarios', usuariosRoutes);
app.use('/upload', uploadRoutes);

// Middleware de erro (ex: erro do Multer - tipo/tamanho de arquivo invalido)
app.use((err, req, res, next) => {
  console.error(err);
  res.status(400).json({ mensagem: err.message || 'Erro na requisicao' });
});

module.exports = app;
