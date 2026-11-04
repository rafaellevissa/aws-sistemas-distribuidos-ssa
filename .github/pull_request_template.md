## O que muda

<!-- Resuma em 2-3 linhas: qual API/infra, por que. -->

## Tipo de mudança

- [ ] IaC (Terraform)
- [ ] Pipeline (GitHub Actions)
- [ ] Kit do Kiro (`.kiro/`, `docs/`)
- [ ] Aplicação

## Impacto na infraestrutura

- Recursos **novos**:
- Recursos **alterados**:
- Recursos **destruídos ou substituídos** (RDS, S3, Secret perdem dados):
- [ ] Rodei o workflow **Terraform Plan** e revisei o resumo
- [ ] Alterações na UserData/Launch Template (haverá *instance refresh*)

## Segurança

- [ ] Sem segredos, `.env`, `.tfstate` ou `.tfvars` no diff
- [ ] Policies IAM com escopo de recurso (sem `Resource: "*"` novo sem justificativa)
- [ ] Itens "didáticos" novos estão comentados (`# Didatico:`) e listados abaixo

## Custo

<!-- O que passa a gerar custo contínuo? É ambiente temporário? Como destruir? -->

## Verificação

- [ ] `Terraform CI` verde (fmt + validate)
- [ ] Health check validado após o deploy (`curl -i http://<dns>/`)

## Guardrails do Kiro

Se este PR foi gerado com o Kiro: confirmo que **apliquei/aprovei manualmente** o deploy (o Kiro não aplica
infraestrutura) e que não foram alterados `.kiro/hooks/`, `.kiro/agents/` ou os steering `00-`/`10-`
sem revisão.
