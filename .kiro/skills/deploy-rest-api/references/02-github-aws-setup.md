# 02. GitHub e AWS: passo a passo para o dev

Quem executa é o **dev**. O Kiro explica, espera a confirmação de cada passo e **não vê credenciais**.
Use `aws`/`gh` apenas para o dev rodar no próprio terminal, nunca para você executar.

## 2.1 Bucket S3 do state do Terraform

O Terraform não cria o próprio backend. Crie **uma vez**:

```bash
aws s3api create-bucket --bucket SEU-BUCKET-TFSTATE --region us-east-1
aws s3api put-bucket-versioning --bucket SEU-BUCKET-TFSTATE \
  --versioning-configuration Status=Enabled
aws s3api put-public-access-block --bucket SEU-BUCKET-TFSTATE \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

O nome do bucket é global na AWS. Se já existir, escolha outro.
(Em regiões diferentes de `us-east-1`, `create-bucket` exige `--create-bucket-configuration LocationConstraint=<região>`.)

## 2.2 Usuário IAM do pipeline

1. Console IAM → *Users → Create user* (sem acesso ao console).
2. Gere a policy a partir de `assets/iam-pipeline-policy.template.json`, trocando
   `ACCOUNT_ID` (12 dígitos) e `ENVIRONMENT_NAME` (= `infra.environment_name`). O Kiro faz a substituição
   e mostra o JSON final para o dev conferir.
3. Anexe como **inline policy** ao usuário.
4. *Security credentials → Create access key* (caso de uso: aplicação rodando fora da AWS). **Guarde** as
   duas chaves; elas só aparecem uma vez.

> ⚠️ O trecho de serviços (`ec2:*`, `rds:*`, ...) é **didático e amplo** (`Resource: "*"`). A parte de IAM
> foi validada em uso real neste projeto; o escopo de serviços é uma base razoável, mas ainda não foi
> auditado ação por ação. Para produção, restrinja por recurso/tag e revise com o time de segurança.
> Lembre: o JSON no repositório **não aplica nada sozinho**. A policy só vale depois de anexada.

Se aparecer `AccessDenied` depois: `.kiro/steering/50-iam-e-permissoes.md`.

## 2.3 Secrets do GitHub

*Repositório → Settings → Secrets and variables → Actions → New repository secret*

| Secret | Valor |
|---|---|
| `AWS_ACCESS_KEY_ID` | chave do usuário do pipeline |
| `AWS_SECRET_ACCESS_KEY` | chave secreta do usuário do pipeline |
| `TF_STATE_BUCKET` | `SEU-BUCKET-TFSTATE` |
| `ECR_REGISTRY` | `<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com` |
| `ECR_REPOSITORY` | nome do repositório ECR (= `ecr_repository_name` do Terraform) |

Confira que `ECR_REPOSITORY` é **exatamente** o nome definido na IaC; divergência faz o `docker push` falhar.

## 2.4 (Opcional) DNS

Se usar domínio: a **hosted zone** precisa já existir no Route53 da mesma conta. O Terraform só cria o
subdomínio (registros com *latency routing* quando há mais de uma região).

## 2.5 (Recomendado) Proteção do deploy

*Settings → Environments → New environment → `production` → Required reviewers.* Depois,
adicione `environment: production` aos jobs de apply/destroy. Isso exige aprovação humana no GitHub
antes de qualquer alteração de infraestrutura, mesmo que alguém dispare o workflow por engano.

Também recomendado: *Settings → Branches → Branch protection* na `main` (PR obrigatório + CI verde).

## 2.6 Conectar o repositório ao Kiro

No Kiro, abra uma sessão com o repositório do dev. O Kiro lê `.kiro/steering`, `.kiro/skills` e
`.kiro/settings/mcp.json` do repositório. Para iniciar o fluxo, o dev digita: `/deploy-rest-api`.

## Confirmação (G2)

Peça ao dev para responder com ✅ em cada item: bucket de state, usuário + policy aplicada, secrets
cadastrados (os 5 nomes), DNS (se aplicável).
