# 04. Pipelines, ordem do deploy e custos

## Workflows

| Workflow | Disparo | O que faz |
|---|---|---|
| `Deploy Infrastructure` | manual | `terraform apply` (toda a infra) **em paralelo** com build/push da imagem |
| `Deploy Backend API` | `push` na `main` e `workflow_call` | build → push no ECR → *rolling instance refresh* por região |
| `Apply Database Schema` | manual | libera o IP do runner no SG do RDS, aplica `schema.sql`, **sempre** fecha o acesso |
| `Destroy Infrastructure` | manual | `terraform destroy` (somente o humano dispara) |
| `Terraform Plan` | manual | `terraform plan` com resumo (criar/alterar/destruir). **Não aplica nada.** Rode antes do deploy |
| `Terraform CI` | Pull Request | `terraform fmt -check` + `validate` + checagem de arquivos sensíveis e chaves AWS |

## Ordem do primeiro deploy

```
Deploy Infrastructure
 ├─ deploy-infrastructure  → terraform apply (cria ECR cedo no grafo; RDS leva ~8 min)
 └─ build-and-push-docker-image → espera ~20s (wait-for-ecr) → docker build → push ECR
```

1. Os dois jobs rodam **em paralelo**; o build espera 20s para o ECR existir.
2. As instâncias do ASG sobem durante o `apply` e tentam `docker pull` (tolerado com `|| true`). Se a
   imagem ainda não estava no ECR, o `refresh-instances` do próximo deploy as substitui.
3. Se o banco é novo, rode `Apply Database Schema` depois que o RDS estiver disponível.
4. Dispare `Deploy Backend API` (ou faça push na `main`) para publicar a imagem e reiniciar as instâncias
   com ela.

> Se o push falhar com *repository does not exist*, o ECR ainda não tinha sido criado: reexecute o job de
> build (não precisa reaplicar a infra). Aumentar o delay é uma opção; trocar por `needs:` muda a decisão
> de projeto e deve ser discutida com o dev.

## Custos (ordem de grandeza; confirme na calculadora da AWS)

Mensagem padrão para o dev antes do deploy. Não cite valores em dólar como se fossem exatos.

| Recurso | Gera custo enquanto existir? |
|---|---|
| ALB (por região) | Sim, contínuo |
| EC2 do ASG (mínimo 2 por região) | Sim, contínuo (t2.micro pode estar no free tier só na 1ª conta/12 meses) |
| RDS | Sim, contínuo (~8 min para criar) |
| WAF | Sim (web ACL + regras + requisições) |
| ECR, S3, logs | Baixo, por volume |
| Segunda região | Dobra ALB + EC2 |

Ambiente temporário → **destruir ao final** (`06-destroy-rollback.md`).

## Acompanhando runs

```bash
gh run list --limit 5
gh run watch <id>
gh run view <id> --log-failed
```

Resuma o resultado para o dev em 2–3 linhas. Se falhar, vá para `05-troubleshooting.md`.
