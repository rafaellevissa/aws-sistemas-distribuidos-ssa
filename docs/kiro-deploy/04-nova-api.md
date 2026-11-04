# 04. Usando o kit com outra API

## O que a sua API precisa

Resumo do contrato (completo em `.kiro/steering/40-contrato-da-api.md`):

1. `Dockerfile` na raiz que inicia o servidor, com `EXPOSE <porta>`.
2. `GET /` (ou outro path) respondendo **200**, sem autenticação e **sem consultar o banco**.
3. Configuração 100% por **variáveis de ambiente**; nenhum segredo na imagem.
4. **Stateless** (haverá 2+ réplicas atrás do ALB).
5. Imagem **linux/amd64**.
6. Recomendado: logs JSON em stdout com `type: "request"` e `userAgent` (alimenta o dashboard).

## Como informar ao Kiro

O Kiro cria o `deploy-config.yaml` perguntando. Se preferir, copie
`.kiro/skills/deploy-rest-api/assets/deploy-config.example.yaml` para a raiz e preencha. O arquivo
**não contém segredos**.

## O que o kit já resolve

Rede em 2 AZs, ALB, Auto Scaling Group, WAF, ECR, RDS MySQL, Secrets Manager, S3 opcional,
logs e dashboard no CloudWatch, DNS opcional, e os pipelines de infra, build e redeploy.

## O que costuma mudar por API

| Item | Onde |
|---|---|
| Nome do ECR | `ecr_repository_name` |
| Porta do container | `docker run -p 80:<porta>` em `user-data.sh.tftpl` |
| Path do health check | `loadbalancer.tf` |
| Variáveis de ambiente | bloco `docker run -e` em `user-data.sh.tftpl` |
| Banco / S3 / DNS / regiões | flags e módulos em `main.tf` |

Procedimento completo: `.kiro/skills/deploy-rest-api/references/03-adaptar-iac.md`.

## Limitações atuais do kit (transparência)

O módulo `region-stack` foi construído a partir de uma API específica. Hoje:

- A **porta (3000)**, o **health check (`/`)** e as **variáveis de ambiente** do container estão fixos no
  módulo; adaptar para outra API significa **parametrizá-los** (o Kiro faz isso na fase 3, via PR).
- O banco suportado é **MySQL/RDS**. Outro banco exige alterar o módulo.
- O schema do banco é aplicado por workflow separado, apontando para `src/db/schema.sql`.
- A topologia de referência é multi-região. Uma região só é possível, mas exige remover o módulo secundário,
  o registro DNS e os widgets do dashboard.

Uma evolução natural, e boa candidata a spec do Kiro, é transformar essas variações em **variáveis do
módulo** (`container_port`, `health_check_path`, `app_env`, regiões opcionais) para que a próxima API não
exija editar o módulo.

## Mais de uma API no mesmo repositório?

O kit assume **uma API por repositório**. Para várias, use um repositório (e um state) por API ou
evolua o módulo para suportar múltiplos serviços.
