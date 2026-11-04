---
inclusion: auto
name: contrato-da-api
description: Requisitos para uma API REST ser implantável por este kit (Dockerfile, porta, health check, variáveis de ambiente, logs). Use ao avaliar, preparar ou diagnosticar uma API antes do deploy.
---

# Contrato da API para o deploy

Uma API só entra no kit se cumprir os itens abaixo. No preflight, **verifique cada um lendo o código**
(`Dockerfile`, `package.json` ou equivalente, rotas) e reporte ✅ / ⚠️ / ❌ com o arquivo e a linha.

## Obrigatórios

| # | Requisito | Por quê |
|---|---|---|
| 1 | `Dockerfile` na raiz que builda e inicia o servidor | O pipeline faz `docker build` e `push` para o ECR |
| 2 | Escuta em **uma porta única** e a expõe (`EXPOSE`) | O container é publicado `80 → porta` na EC2 |
| 3 | `GET /` (ou path configurável) responde **HTTP 200** sem autenticação e sem depender do banco | O Target Group do ALB usa como health check (intervalo 10s, 2 falhas = fora) |
| 4 | **Toda configuração via variáveis de ambiente** | A UserData injeta `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `AWS_REGION`... |
| 5 | **Sem segredos na imagem nem no repositório** | A imagem vai para um registry; segredos vêm do Secrets Manager |
| 6 | **Stateless** (sem estado em memória ou disco local) | O ASG mata e recria instâncias; há 2+ réplicas atrás do ALB |
| 7 | Imagem **linux/amd64** | Instâncias `t2.micro` são x86_64 |

## Recomendados

- Logs em **stdout**, um JSON por linha. O dashboard do kit consulta logs com `type = 'request'` e `userAgent`.
  Sem isso, o gráfico "requests por instância" fica vazio (o resto continua funcionando).
- Encerramento limpo em `SIGTERM` (o ASG usa rolling refresh).
- Pool de conexões com limites (várias réplicas dividem o mesmo banco).
- `.dockerignore` com `node_modules`, `.env`, `.git`.
- Limite de tamanho de upload coerente com o WAF (o kit só libera corpos grandes em `POST /upload`).

## Banco de dados

- O kit cria **MySQL no RDS**. Outros bancos exigem mudar o módulo: avise e pergunte antes.
- O **schema não é aplicado pelo Terraform**: use o workflow `Apply Database Schema`
  (que lê `src/db/schema.sql`). Para outra API, aponte para o schema dela.

## Como reportar

Apresente uma tabela curta com o resultado de cada requisito e, para cada ❌/⚠️, a correção sugerida
em **uma frase**. Só prossiga para a fase de IaC (gate G1) quando os ❌ estiverem resolvidos ou aceitos
pelo dev.
