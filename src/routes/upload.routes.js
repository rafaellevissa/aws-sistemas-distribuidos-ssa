const { Router } = require('express');
const multer = require('multer');
const { PutObjectCommand } = require('@aws-sdk/client-s3');
const s3Client = require('../config/s3');
const router = Router();

// Armazena o ficheiro em memória temporariamente antes de enviar ao S3[cite: 1].
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // Limite de 5MB[cite: 1]
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('Apenas ficheiros de imagem são permitidos'));
    }
    cb(null, true);
  },
});

// POST /upload - recebe um ficheiro (campo "imagem") e envia para o S3[cite: 1].
router.post('/', upload.single('imagem'), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ mensagem: 'Nenhum ficheiro enviado.' });
  }

  const file = req.file;
  const fileName = `${Date.now()}_${file.originalname}`;
  
  const params = {
    Bucket: process.env.AWS_S3_BUCKET_NAME,
    Key: fileName,
    Body: file.buffer,
    ContentType: file.mimetype,
  };

  try {
    // Na v3, criamos um comando e enviamos através do cliente S3
    const command = new PutObjectCommand(params);
    await s3Client.send(command);
    
    // A URL pública é montada combinando o nome do bucket, região e nome do ficheiro
    const urlPublica = `https://${process.env.AWS_S3_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileName}`;

    res.status(200).json({
      mensagem: 'Upload realizado com sucesso!',
      url: urlPublica,
      key: fileName,
    });
  } catch (error) {
    console.error('Erro no upload para o S3:', error);
    res.status(500).json({ mensagem: 'Erro interno no servidor', erro: error.message });
  }
});

module.exports = router;