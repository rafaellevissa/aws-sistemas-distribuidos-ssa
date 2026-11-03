# Infraestrutura (Terraform)

Migração da IaC de **CloudFormation** para **Terraform**. Provisiona a mesma
arquitetura multi-região da palestra "Engenharia do Caos e Escalabilidade":

- **us-east-1** (região primária): VPC, ALB, ASG (multi-AZ), WAF, ECR, **RDS MySQL**,
  **Secrets Manager**, **S3** (bucket global), CloudWatch Log Group.
- **eu-central-1** (região secundária): mesma stack de compute/rede, consumindo o
  banco, o secret e o bucket S3 da região primária.
- **Route53**: registro `A` com *latency routing* apontando para o ALB de cada região.
- **CloudWatch Dashboard**: requests por ALB, CPU por ASG e requests por instância.

Tudo é provisionado por um **único `terraform apply`** (uma raiz com dois providers
AWS por alias de região).

## Estrutura

```
iac/terraform/
├── backend.tf                 # backend S3 (sem lock DynamoDB) + required_providers
├── providers.tf               # providers aws.us_east_1 e aws.eu_central_1
├── main.tf                    # orquestra as 2 regiões + Route53 + dashboard
├── variables.tf               # variáveis da raiz (com defaults = CloudFormation)
├── outputs.tf                 # outputs (DNS, ECR, DB, dashboard, ASGs...)
├── backend.hcl.example        # modelo de config do backend S3
├── terraform.tfvars.example   # modelo de variáveis
└── modules/
    ├── region-stack/          # módulo reutilizável por região (elimina duplicação)
    │   ├── networking.tf      # VPC, subnets multi-AZ, IGW, route table, SGs
    │   ├── data.tf            # RDS + Secret + ECR + S3 (condicionais por flag)
    │   ├── iam.tf             # roles/instance profile + log group
    │   ├── loadbalancer.tf    # ALB + target group + listener
    │   ├── waf.tf             # WAFv2 (Common Rule Set + regra custom /upload)
    │   ├── compute.tf         # launch template + ASG + instance refresh
    │   └── templates/user-data.sh.tftpl
    └── dashboard/             # CloudWatch dashboard multi-região
```

> **Por que o Terraform ficou menor que o CloudFormation?** As duas regiões eram
> arquivos YAML quase idênticos. Aqui as duas regiões reusam o mesmo módulo
> `region-stack`; a diferença é só o valor das flags (`create_database`,
> `create_s3_bucket`) e o provider passado.

## Pré-requisitos

- Terraform >= 1.5 (testado com 1.9.8) e provider AWS >= 6.0.
- Credenciais AWS de **uma única conta** (as duas regiões usam a mesma conta).
- Um **bucket S3 para o state** (criado previamente — o Terraform não cria o
  próprio backend). Sem DynamoDB lock, conforme definido para a palestra.
- A **hosted zone** de `rafaellevi.com.br` já existente no Route53 (é referenciada
  via `data source`; o Terraform cria apenas o subdomínio).

### Criar o bucket de state (uma vez)

```bash
aws s3api create-bucket --bucket SEU-BUCKET-DE-TFSTATE --region us-east-1
aws s3api put-bucket-versioning --bucket SEU-BUCKET-DE-TFSTATE \
  --versioning-configuration Status=Enabled
```

## Uso

Via script (recomendado — faz `init` + `validate` + `apply`):

```bash
export TF_STATE_BUCKET=SEU-BUCKET-DE-TFSTATE
./iac/scripts/apply.sh
```

Ou manualmente:

```bash
cd iac/terraform
cp backend.hcl.example backend.hcl        # ajuste o bucket
cp terraform.tfvars.example terraform.tfvars  # ajuste se quiser
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

### Redeploy da aplicação (nova imagem)

O pipeline builda a imagem, publica no ECR e dispara um *rolling instance refresh*:

```bash
export TF_STATE_BUCKET=SEU-BUCKET-DE-TFSTATE
./iac/scripts/refresh-instances.sh us-east-1
./iac/scripts/refresh-instances.sh eu-central-1
```

### Destruir tudo

```bash
export TF_STATE_BUCKET=SEU-BUCKET-DE-TFSTATE
./iac/scripts/destroy.sh
```

## CI/CD (GitHub Actions)

Os workflows foram adaptados para Terraform. Além dos secrets já existentes
(`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `ECR_REGISTRY`, `ECR_REPOSITORY`),
adicione:

| Secret | Descrição |
|--------|-----------|
| `TF_STATE_BUCKET` | Nome do bucket S3 onde o state é guardado |

### Permissões IAM do usuário/role do pipeline

> **Por que o Terraform precisa de mais permissões IAM que o CloudFormation?**
> O CloudFormation é um serviço gerenciado: ao deletar uma stack, ele inspeciona e
> remove os recursos **com o contexto do próprio serviço**, então o seu usuário só
> precisava de `cloudformation:*`. O Terraform roda **como o seu usuário**, chamando
> as APIs da AWS diretamente — e tanto no `refresh` quanto no `destroy` ele faz
> chamadas de **leitura** para "hidratar" e desmontar os recursos (ex.:
> `iam:ListRolePolicies`, `iam:ListInstanceProfilesForRole`). Por isso o usuário do
> pipeline precisa dessas ações explicitamente.

Além das permissões para EC2/VPC, ELB, RDS, S3, ECR, Secrets Manager, WAFv2,
CloudWatch, Route53, Logs e SSM (leitura do parâmetro da AMI), o usuário precisa
das ações IAM abaixo (recorte específico para esta stack). O JSON completo está em
[`iam-pipeline-policy.json`](iam-pipeline-policy.json):

```
# Ciclo de vida da role, instance profile e policies desta stack:
iam:CreateRole            iam:DeleteRole            iam:GetRole
iam:TagRole               iam:UntagRole             iam:ListRoleTags
iam:PutRolePolicy         iam:DeleteRolePolicy      iam:GetRolePolicy
iam:ListRolePolicies      iam:ListAttachedRolePolicies
iam:AttachRolePolicy      iam:DetachRolePolicy
iam:CreateInstanceProfile iam:DeleteInstanceProfile iam:GetInstanceProfile
iam:AddRoleToInstanceProfile iam:RemoveRoleFromInstanceProfile
iam:ListInstanceProfilesForRole
iam:PassRole              # para o EC2/ASG assumir a instance profile
```

- **Deploy Infrastructure** → `terraform apply` (todas as regiões + dashboard + Route53)
  e **depois** (via `needs`) o build/push da imagem. O job de build só inicia após o
  `apply` concluir — ou seja, com o **ECR já criado** — e ainda aguarda ~20s
  (`wait-for-ecr: true`) como margem para a consistência do repositório recém-criado.
- **Destroy Infrastructure** → `terraform destroy`.
- **Apply Database Schema** → lê `db_host`/`db_secret_name`/`rds_security_group_id`
  dos outputs do Terraform e aplica `src/db/schema.sql`.
- **Deploy Backend API** → build/push da imagem + instance refresh por região.

## Mapeamento CloudFormation → Terraform

| CloudFormation | Terraform |
|----------------|-----------|
| `us-east-1-infra.yaml` + `eu-central-1-infra.yaml` | módulo `region-stack` (flags por região) |
| `dashboard.yaml` | módulo `dashboard` |
| Parâmetro SSM da AMI Ubuntu | `data "aws_ssm_parameter"` |
| `GenerateSecretString` | `random_password` + `aws_secretsmanager_secret_version` |
| Lambda custom resource que esvazia o S3 | `force_destroy = true` no bucket |
| `EmptyOnDelete` no ECR | `force_delete = true` |
| Outputs exportados entre stacks | referências diretas entre módulos (um só state) |
| `scripts/create-stack.sh` / `destroy-stack.sh` | `scripts/apply.sh` / `destroy.sh` |
