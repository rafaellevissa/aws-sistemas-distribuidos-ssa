# 05. Troubleshooting (erros reais já vistos)

Regra: leia o erro, **cite a linha relevante**, explique a causa em português e proponha a correção.
Não "teste" correções rodando `terraform` localmente com credenciais: o fluxo é editar → PR → CI.

| Sintoma | Causa provável | Correção |
|---|---|---|
| `AccessDenied ... iam:ListRolePolicies` (refresh/destroy) | Falta `iam:ListRolePolicies` ao usuário do pipeline | Aplicar a policy `iam:*` escopada (50-iam-e-permissoes.md) |
| `AccessDenied ... iam:ListInstanceProfilesForRole` (destroy) | Idem | Idem |
| `AccessDenied ... iam:TagInstanceProfile` (apply) | `default_tags` tagueia o instance profile | Idem |
| Mesmo erro, **mesmo RequestID** depois de "corrigir" | A policy não foi aplicada no usuário | O JSON do repo é documentação: anexar no console IAM; aguardar ~20s |
| AccessDenied persiste com a ação já permitida | SCP da organização ou permissions boundary | Verificar com o admin da conta |
| `docker push`: *repository does not exist* | O ECR ainda não existia quando o build rodou | Reexecutar o job de build; considerar aumentar o delay |
| `no basic auth credentials` / `denied` no push | `ECR_REGISTRY`/`ECR_REPOSITORY` errados ou sem permissão `ecr:*` | Conferir secrets e policy |
| Targets *unhealthy* no ALB | Health check devolve ≠ 200, porta errada, container não subiu, SG | Ver `/` local; conferir porta (`container_port`); ver logs do container no CloudWatch (log group `/unifan/...`) |
| Instâncias sobem mas `docker pull` falha | Imagem ainda não está no ECR / role sem `ECR ReadOnly` | Publicar a imagem; rodar `Deploy Backend API` (refresh) |
| API sobe e cai com erro de conexão ao banco | Schema não aplicado, SG do RDS, segredo errado | Rodar `Apply Database Schema`; conferir `DB_*` e o secret |
| `Error: Invalid provider configuration` / `Unsupported argument` | Versão do provider (precisa `>= 6.0`) | `terraform init -upgrade`; revisar `required_providers` |
| `BucketAlreadyExists` | Nome de bucket é global | Definir `s3_bucket_name` único |
| `Error acquiring the state lock` | Execução paralela ou run cancelado | Aguardar; o state em S3 deste kit **não usa lock DynamoDB**, evite dois applies simultâneos |
| Run cancelado no meio do apply | Recursos parcialmente criados | Rodar o apply de novo (idempotente) ou o destroy. Não apague recursos à mão |
| `Hosted zone not found` | Domínio não está no Route53 desta conta | Criar/trazer a zona, ou desligar `dns` |
| Gráfico "requests por instância" vazio | Logs da API não têm `type: "request"` | Ver `40-contrato-da-api.md` (logs em JSON) |

## Quando escalar para o dev

- Qualquer ação que exija **console AWS** (IAM, SCP, domínio).
- Qualquer coisa que envolva **credenciais**.
- Custos inesperados ou recursos órfãos fora do state.

## Registro

Ao resolver um erro novo, proponha adicionar a linha na tabela acima (via PR). O kit melhora a cada uso.
