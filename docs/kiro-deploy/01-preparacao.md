# 01. Preparação (uma vez por projeto)

Tempo estimado: 20–30 minutos. Você precisa de uma conta GitHub, uma conta AWS e o Kiro.

## 1. Repositório no GitHub

1. Crie (ou use) o repositório da sua API. Ela precisa ter um `Dockerfile` na raiz.
2. Traga o kit para o repositório. Duas opções:
   - **Template/fork** deste repositório e substitua o código da API pela sua; ou
   - **Copie** `.kiro/`, `.github/`, `iac/` e `docs/kiro-deploy/` para o seu repositório.
3. Em `.github/CODEOWNERS`, troque `@rafaellevissa` pelo seu usuário.

## 2. Conectar o repositório ao Kiro

1. Abra o Kiro e inicie uma sessão apontando para o seu repositório.
2. Autorize o acesso ao GitHub quando solicitado.
3. Confirme que o Kiro enxerga `.kiro/steering/` e `.kiro/skills/deploy-rest-api/`.
   Teste digitando `/deploy-rest-api`: ele deve oferecer a skill.

> O Kiro lê o `.kiro/` **do repositório**. É por isso que as regras viajam junto com o código.

## 3. Conta AWS

O Kiro vai **instruir** você em cada item abaixo na fase 2 do fluxo. Resumo do que será necessário:

| # | Item | Quem faz |
|---|---|---|
| 1 | Bucket S3 para o state do Terraform (com versionamento) | Você |
| 2 | Usuário IAM do pipeline + policy | Você |
| 3 | Access key desse usuário | Você (o Kiro nunca vê) |
| 4 | Secrets no GitHub (5 itens) | Você |
| 5 | (Opcional) Domínio na Route53 | Você |

Detalhes e comandos: [`.kiro/skills/deploy-rest-api/references/02-github-aws-setup.md`](../../.kiro/skills/deploy-rest-api/references/02-github-aws-setup.md).

### Secrets do GitHub

| Secret | Valor |
|---|---|
| `AWS_ACCESS_KEY_ID` | chave do usuário do pipeline |
| `AWS_SECRET_ACCESS_KEY` | chave secreta |
| `TF_STATE_BUCKET` | nome do bucket de state |
| `ECR_REGISTRY` | `<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com` |
| `ECR_REPOSITORY` | nome do repositório ECR (igual ao definido na IaC) |

### A policy IAM precisa ser aplicada manualmente

O arquivo JSON do repositório **não aplica nada**. Ele só vale depois de anexado ao usuário no console
IAM. Esse foi o erro mais caro do projeto original: três rodadas de `AccessDenied`, cada uma depois de
vários minutos de `apply`. O template com `iam:*` escopado está em
`.kiro/skills/deploy-rest-api/assets/iam-pipeline-policy.template.json`.

## 4. Proteções recomendadas no GitHub

- **Branch protection** na `main`: exigir PR e o check `Terraform CI`.
- **Require review from Code Owners** (ativa o `CODEOWNERS`, que protege `.kiro/`, `iac/` e workflows).
- **Environment `production`** com *required reviewers* para aprovar apply/destroy.

## 5. Checklist final

- [ ] A API builda com `docker build .`
- [ ] Bucket de state criado
- [ ] Usuário IAM criado, policy **anexada**, access key guardada
- [ ] 5 secrets cadastrados
- [ ] Kiro conectado e `/deploy-rest-api` aparece
- [ ] Branch protection ativa
