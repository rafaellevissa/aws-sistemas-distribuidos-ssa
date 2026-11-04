# 01. Preflight da API

Objetivo: descobrir **antes de criar qualquer recurso** se a API está apta para o deploy.

## Checklist (marque ✅ / ⚠️ / ❌ com arquivo e linha)

### Container
- [ ] `Dockerfile` existe na raiz e termina em `CMD`/`ENTRYPOINT` que inicia o servidor
- [ ] `EXPOSE <porta>` bate com a porta que o código escuta (`PORT`/`listen`)
- [ ] Imagem base compatível com **linux/amd64**
- [ ] `.dockerignore` exclui `node_modules`, `.git`, `.env`
- [ ] `docker build .` funciona (rode localmente se o Docker estiver disponível)

### Comportamento HTTP
- [ ] Existe `GET <health_check_path>` retornando **200** sem autenticação
- [ ] O health check **não** consulta o banco (senão uma queda do banco derruba todas as instâncias do ALB)
- [ ] A API não depende de estado local entre requisições

### Configuração e segredos
- [ ] Toda configuração vem de variáveis de ambiente (liste-as para o `deploy-config.yaml`)
- [ ] Nenhum segredo no repositório (`git grep -nEi "(secret|password|token|api[_-]?key)\s*[:=]"` e revise `.env*`)
- [ ] `.env` está no `.gitignore`

### Dependências
- [ ] Banco: qual? (o kit cria MySQL/RDS). Há schema SQL? Onde?
- [ ] Usa S3? Qual variável guarda o nome do bucket e a região?
- [ ] Chama outros serviços externos? (as instâncias têm saída para a internet)

## Como apresentar

| Requisito | Status | Evidência | Correção |
|---|---|---|---|
| Health check em `/` | ✅ | `src/app.js:17` | |
| Sem segredos versionados | ❌ | `config/prod.js:4` | mover para variável de ambiente |

Termine com: "Posso seguir para a próxima fase?" (**G1**).

## Armadilhas comuns

- Health check em rota que exige login → o ALB marca todas as instâncias como *unhealthy*.
- Servidor escutando em `127.0.0.1` em vez de `0.0.0.0` → o container não recebe tráfego.
- Porta do código diferente do `EXPOSE`/`deploy-config.yaml`.
- A API cria o schema na inicialização com `CREATE DATABASE` e o usuário não tem permissão.
