---
inclusion: fileMatch
fileMatchPattern: ["**/*.tf", "**/*.tfvars.example", "iac/**"]
---

# Padrões de Terraform deste kit

Estrutura atual (leia antes de alterar):

- Raiz: #[[file:iac/terraform/main.tf]]
- Variáveis da raiz: #[[file:iac/terraform/variables.tf]]
- Módulo por região: `iac/terraform/modules/region-stack/` (rede, ALB, ASG, WAF, ECR, RDS, S3, IAM)
- Dashboard: `iac/terraform/modules/dashboard/`

## Regras

1. **Reuse o módulo `region-stack`.** Não copie e cole recursos entre regiões. Diferenças entre regiões
   entram como variável ou flag (`create_database`, `create_s3_bucket`).
2. **Toda variável** tem `type` e `description`. Valores com default seguro; nada de segredo em default.
3. **Nomes**: prefixo `var.environment_name` em tudo. Use `name_prefix` onde o recurso é recriado
   (Security Group, Launch Template, Target Group, Role) com `lifecycle { create_before_destroy = true }`.
4. **Tags**: todo recurso recebe `local.common_tags`.
5. **Segredos**: senha de banco com `random_password` + `aws_secretsmanager_secret_version`.
   A instância lê o segredo em runtime (UserData), nunca recebe senha no código.
6. **Provider AWS `>= 6.0`**: use `data.aws_region.current.region` (o atributo `.name` está deprecado).
7. **State**: backend S3 configurado por `-backend-config` (bucket vem de `TF_STATE_BUCKET`).
   Nunca versione `backend.hcl`, `*.tfstate` ou `*.tfvars`.
8. **Formato**: rode `terraform fmt -recursive` e `terraform validate`
   (`terraform init -backend=false` antes) a cada alteração. Não commite com erros.
9. **Itens didáticos** (SG `0.0.0.0/0`, RDS público, `force_destroy`, `skip_final_snapshot`) precisam
   de um comentário `# Didatico:` ao lado. Se criar um novo, comente o motivo e o risco.
10. **Recursos opcionais** (RDS, S3, Route53, WAF, dashboard) devem poder ser desligados por variável.
    Ao adaptar o kit para outra API, prefira adicionar uma flag a remover código.

## Ao adaptar para uma nova API

Siga `.kiro/skills/deploy-rest-api/references/03-adaptar-iac.md`. Em resumo, os pontos que variam por
aplicação são: nome do ECR, porta do container, path do health check, variáveis de ambiente no
`templates/user-data.sh.tftpl` e quais recursos opcionais ligar.

## Limites

- Você valida e formata localmente, mas **não aplica**. O `plan`/`apply` rodam no GitHub Actions.
- Alterações que **destroem ou substituem** recursos de dados (RDS, S3, Secret) exigem aviso explícito
  ao dev e menção no corpo do PR.
