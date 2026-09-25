const { S3Client } = require('@aws-sdk/client-s3');

// 1. Criamos a configuração base com a região
const config = {
  region: process.env.AWS_REGION,
};

// 2. Verificamos se as chaves existem no ficheiro .env
// Se existirem (no teu computador), adicionamos as credenciais.
// Se não existirem (na EC2), o SDK não recebe credenciais e usa a IAM Role automaticamente.
if (process.env.AWS_ACCESS_KEY_ID && process.env.AWS_SECRET_ACCESS_KEY) {
  config.credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  };
}

// 3. Inicializamos o cliente S3 com a configuração final
const s3Client = new S3Client(config);

module.exports = s3Client;