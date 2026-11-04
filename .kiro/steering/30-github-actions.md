---
inclusion: fileMatch
fileMatchPattern: [".github/workflows/**", "iac/scripts/**"]
---

# Padrões dos pipelines (GitHub Actions)

Workflows atuais: #[[file:.github/workflows/deploy-infraestructure.yml]]

## Secrets esperados

| Secret | Uso |
|---|---|
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Usuário IAM do pipeline |
| `TF_STATE_BUCKET` | Bucket S3 do state do Terraform |
| `ECR_REGISTRY` / `ECR_REPOSITORY` | Destino do `docker push` |

Você **não cria** secrets. Liste o que falta e peça ao dev para cadastrar em
*Settings → Secrets and variables → Actions*.

## Regras

1. **Workflows de infraestrutura são `workflow_dispatch`** (disparo manual). Não troque por `push`.
2. **Ordem do deploy (decisão do dono do projeto):** `deploy-infrastructure` e `build-and-push-docker-image`
   rodam **em paralelo**. O build espera ~20s (`wait-for-ecr: true`) para o Terraform criar o ECR.
   **Não** transforme isso em `needs:` sem perguntar. Se o build falhar por ECR inexistente, sugira
   aumentar o delay ou reexecutar o job, e explique a corrida.
3. `refresh-instances` depende do build (`needs: build-and-image-push`): ele só reinicia as instâncias
   depois que a imagem nova foi publicada.
4. **Pin de versões**: `hashicorp/setup-terraform` com `terraform_version` fixa (hoje `1.9.8`).
5. **Nunca** imprima segredos. Use `::add-mask::` para valores sensíveis lidos em runtime.
6. Passos que abrem acesso temporário (ex.: liberar o IP do runner no SG do RDS) devem **sempre**
   fechar o acesso em um passo com `if: always()`.
7. Valide o YAML antes do commit (parse com `js-yaml` ou equivalente) e confira que `needs`/`if` fazem
   o que você descreveu no PR.

## Quando algo falhar

Consulte `.kiro/skills/deploy-rest-api/references/05-troubleshooting.md`. Para ler logs de um run:
`gh run list` e `gh run view <id> --log-failed`. Resuma a causa em português e proponha a correção.
