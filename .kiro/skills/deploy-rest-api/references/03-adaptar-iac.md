# 03. Adaptar a IaC para outra API

Estado atual do kit: o módulo `iac/terraform/modules/region-stack/` foi escrito para a API de
referência (CRUD de usuários + upload para S3 + MySQL). Parte dele é genérica; parte é específica.
**Seja transparente com o dev sobre isso** e adapte com o menor diff possível.

## O que é genérico (normalmente não muda)

VPC, subnets em 2 AZs, Internet Gateway, Security Groups, ALB + Target Group + Listener, Launch Template + ASG
com instance refresh, WAF, log group, role/instance profile, ECR, dashboard.

## O que costuma variar por aplicação

| O quê | Onde | Como mudar |
|---|---|---|
| Nome do ECR | `ecr_repository_name` (`variables.tf`) | Variável; manter igual ao secret `ECR_REPOSITORY` |
| Porta do container | `docker run -p 80:3000` em `templates/user-data.sh.tftpl` | Parametrizar `container_port` (variável + `templatefile`) |
| Health check | `health_check { path = "/" }` em `loadbalancer.tf` | Parametrizar `health_check_path` |
| Variáveis de ambiente | bloco `docker run -e ...` em `user-data.sh.tftpl` | Alinhar com `deploy-config.yaml > app.env_vars` |
| Banco (MySQL) | `data.tf` (`create_database`) | Se a API não usa banco: `create_database = false` e remover o trecho de segredos do UserData |
| S3 | `data.tf` (`create_s3_bucket`) | `false` se não houver upload |
| DNS | `main.tf` (`aws_route53_record`) | Tornar condicional (`count`/`for_each` por `dns.enabled`) |
| Regiões | `main.tf` (módulos `us_east_1`, `eu_central_1`) | Para uma região só, remover o módulo secundário, o registro Route53 dele e os widgets do dashboard |
| Tamanho/quantidade | `instance_type`, `asg_min_size`, `asg_max_size` | Variáveis |
| WAF | `waf.tf` | A regra custom libera corpos grandes só em `POST /upload`; ajuste ou remova se a API não tem upload |

## Procedimento

1. **Mapeie** `deploy-config.yaml` → variáveis/flags. Liste o que será parametrizado.
2. **Escolha o caminho:**
   - *Pequeno* (nome, porta, health check, env vars): edite direto.
   - *Grande* (remover região, trocar banco, novo serviço): crie uma **spec** em `.kiro/specs/<feature>/`
     e implemente por tarefas.
3. **Prefira flags a remoção** de código. Assim a mesma base atende a próxima API.
4. **Mantenha os defaults** equivalentes ao comportamento atual (para não quebrar quem já usa o kit).
5. `terraform fmt -recursive` + `terraform init -backend=false` + `terraform validate`.
6. Atualize `iac/terraform/terraform.tfvars.example` e o `README.md` da IaC.
7. Apresente o resumo do diff (**G3**) com: recursos novos/alterados/removidos, itens didáticos, custo.

## Mudanças que destroem dados

Qualquer alteração que force **substituição** do RDS, do Secret ou do bucket (renomear, trocar engine,
mudar identificador) apaga dados. Sinalize em destaque no PR e confirme com o dev.

## Atenção: mudar `user-data` recria instâncias

A UserData faz parte do Launch Template. Mudar o template e aplicar dispara *instance refresh* no ASG
(rolling). É esperado, mas informe o dev que haverá troca de instâncias.
