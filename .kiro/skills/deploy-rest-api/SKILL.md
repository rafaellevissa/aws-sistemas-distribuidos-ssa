---
name: deploy-rest-api
description: Guia passo a passo o deploy de uma API REST pronta (com Dockerfile) em ambiente resiliente na AWS usando Terraform e GitHub Actions. Use quando o dev pedir para fazer deploy, provisionar infraestrutura, publicar a API na AWS, configurar o pipeline ou destruir o ambiente.
---

# Deploy guiado de API REST na AWS

Você conduz o dev por **8 fases**. Em cada fase: explique o objetivo em 1–2 frases, execute o que for seu,
peça ao dev o que for dele e **pare nos gates** (G1–G5, definidos em `10-guardrails.md`).
Responda sempre em português, com linguagem simples.

Antes de começar, leia `.kiro/steering/10-guardrails.md` e `.kiro/steering/40-contrato-da-api.md`.
Mostre ao dev o mapa das fases (tabela abaixo) e pergunte se quer seguir do início ou retomar de uma fase.

| Fase | O quê | Quem faz | Gate |
|---|---|---|---|
| 0 | Entrevista e `deploy-config.yaml` | Kiro + dev | |
| 1 | Preflight da API | Kiro | **G1** |
| 2 | GitHub e AWS (secrets, IAM, bucket de state) | **Dev** (Kiro instrui) | **G2** |
| 3 | Adaptar a IaC | Kiro | **G3** |
| 4 | Revisão: PR + CI | Kiro + dev | |
| 5 | Deploy | Kiro dispara após aprovação | **G4** |
| 6 | Validação | Kiro | |
| 7 | Entrega e custos | Kiro | **G5** |

## Fase 0: Entrevista

Se não existir `deploy-config.yaml` na raiz, crie-o a partir de
`assets/deploy-config.example.yaml` **perguntando um item por vez** (não preencha por conta própria):
nome da app, porta do container, path do health check, variáveis de ambiente, se usa banco, se usa S3,
quantas regiões, domínio (opcional), `environment_name`, account id.
Mostre o arquivo final e peça confirmação. `deploy-config.yaml` **não contém segredos**.

## Fase 1: Preflight da API (G1)

1. Leia `Dockerfile`, `package.json` (ou equivalente) e as rotas.
2. Verifique o contrato em `40-contrato-da-api.md` e apresente a tabela ✅/⚠️/❌.
3. Se possível, rode `docker build` localmente para confirmar que a imagem builda.
4. Confira `.dockerignore` e que não há `.env` ou segredos versionados.

**G1:** o dev confirma o diagnóstico. Resolva os ❌ antes de seguir (ou registre como aceito).
Detalhes: `references/01-preflight.md`.

## Fase 2: GitHub e AWS (G2)

Quem executa é o **dev**. Você dá o passo a passo exato, em ordem, e espera a confirmação de cada item.
Guia completo em `references/02-github-aws-setup.md`. Resumo:

1. Bucket S3 do **state** do Terraform (com versionamento).
2. Usuário IAM do pipeline + policy (gere o JSON a partir do template, preenchendo `ACCOUNT_ID` e o
   prefixo do ambiente).
3. Access key do usuário (o dev guarda; **você nunca vê**).
4. Secrets no GitHub: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `TF_STATE_BUCKET`, `ECR_REGISTRY`,
   `ECR_REPOSITORY`.
5. (Opcional) Hosted zone no Route53 já existente para o domínio.
6. (Recomendado) GitHub Environment `production` com *required reviewers*.

**G2:** o dev confirma que concluiu 1–4 (e 5, se usar domínio). Peça para ele conferir o nome dos secrets
em *Settings → Secrets and variables → Actions*; você não consegue ver os valores.

## Fase 3: Adaptar a IaC (G3)

Siga `references/03-adaptar-iac.md`. Princípios:

- Crie uma branch `feat/deploy-<app>`.
- Para mudanças grandes (nova API, novas regiões, trocar banco), crie uma **spec** (`requirements → design → tasks`).
  Para ajustes pequenos (porta, nome, variáveis), edite direto.
- Rode `terraform fmt -recursive` e `terraform init -backend=false && terraform validate` em `iac/terraform`.
- Valide o YAML dos workflows se tiver alterado algum.

**G3:** mostre o resumo do diff (arquivos, recursos novos/alterados/removidos, itens didáticos presentes e
o que gera custo). Só commite depois do "ok".

## Fase 4: Revisão (PR + CI)

1. Commit com mensagem clara e `git push` na branch.
2. Abra o PR via `gh api repos/{owner}/{repo}/pulls` (use o template `.github/pull_request_template.md`).
3. Aguarde o workflow **Terraform CI** (fmt + validate). Se falhar, leia `gh run view <id> --log-failed`,
   corrija e reenvie.
4. O dev revisa e faz o **merge**.

## Fase 5: Deploy (G4)

1. Confirme que os secrets existem e que o merge foi feito.
2. Rode o workflow **Terraform Plan** (`gh workflow run terraform-plan.yml`, ou o dev clica em *Run workflow*).
   Ele **não aplica nada**. Leia o resumo (`gh run view <id>`) e destaque o que será **criado, alterado e
   destruído/substituído**. Qualquer destruição de RDS, S3 ou Secret precisa de aviso em destaque.
3. Apresente o resumo do plano e o custo aproximado (ver `references/04-ci-cd.md`).
4. **G4:** só continue quando o dev disser explicitamente "pode aplicar".
5. Dispare o workflow `Deploy Infrastructure`:
   `gh workflow run deploy-infraestructure.yml` (se falhar, instrua o dev a clicar em *Run workflow*).
6. Acompanhe com `gh run list` e `gh run watch`/`gh run view`. O RDS leva ~8 min. Avise o dev para não
   cancelar o run.
7. Se houver falha, consulte `references/05-troubleshooting.md`. Não tente `terraform` local para "consertar".
8. Se o banco é novo, oriente a rodar o workflow `Apply Database Schema`.

## Fase 6: Validação

Valide com evidências, não com suposição:

- Pegue o DNS do ALB (output `us_east_1_load_balancer_dns`) ou o domínio configurado.
- `curl -i http://<dns>/` deve retornar 200. Se o ALB acabou de subir, aguarde os health checks (~1–2 min).
- Faça um fluxo mínimo de CRUD (criar, listar, atualizar, apagar) e mostre as respostas.
- Se o domínio foi configurado, valide também o DNS.

Se algo falhar, diga **o que viu** e a hipótese; não declare sucesso.

## Fase 7: Entrega (G5)

Entregue um resumo com: URL, regiões, recursos criados, custo contínuo estimado, itens "didáticos" que
precisam ser endurecidos para produção e **como destruir tudo**
(`references/06-destroy-rollback.md`). Pergunte se o ambiente é temporário e lembre do destroy.

## Se o dev pedir para destruir

Siga `references/06-destroy-rollback.md`. Você **não** dispara o destroy: explique o que será removido,
peça confirmação por escrito do nome do ambiente e instrua o dev a rodar o workflow `Destroy Infrastructure`.

## Referências

- `references/01-preflight.md`: checklist de preflight
- `references/02-github-aws-setup.md`: passo a passo de GitHub e AWS
- `references/03-adaptar-iac.md`: o que muda por aplicação
- `references/04-ci-cd.md`: pipelines, ordem do deploy, custos
- `references/05-troubleshooting.md`: erros conhecidos e correções
- `references/06-destroy-rollback.md`: destroy e rollback
- `assets/deploy-config.example.yaml`: contrato de deploy
- `assets/iam-pipeline-policy.template.json`: policy do pipeline
