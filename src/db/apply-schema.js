require('dotenv').config();
const mysql = require('mysql2/promise');
const fs = require('node:fs/promises');
const path = require('node:path');

async function applySchema(environment = process.env, createConnection = mysql.createConnection) {
  for (const name of ['DB_HOST', 'DB_USER', 'DB_PASSWORD', 'DB_NAME']) {
    if (!environment[name]) throw new Error(`Missing required environment variable: ${name}`);
  }

  const sql = await fs.readFile(path.join(__dirname, 'schema.sql'), 'utf8');
  const connection = await createConnection({
    host: environment.DB_HOST,
    user: environment.DB_USER,
    password: environment.DB_PASSWORD,
    database: environment.DB_NAME,
    port: environment.DB_PORT || 3306,
    multipleStatements: true,
  });

  try {
    await connection.query(sql);
  } finally {
    await connection.end();
  }
}

if (require.main === module) {
  applySchema().then(() => {
    console.log('Database schema applied');
  }).catch((error) => {
    console.error('Database schema failed:', error.message);
    process.exitCode = 1;
  });
}

module.exports = { applySchema };