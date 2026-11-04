# 06. Destroy e rollback

## Destroy (remover o ambiente)

**O Kiro não dispara o destroy.** O papel dele é garantir que o dev saiba exatamente o que será removido.

### Passos do Kiro

1. Pergunte o motivo (fim da demo? erro? troca de arquitetura?). Se for rollback de um deploy ruim,
   veja a seção de rollback antes de destruir tudo.
2. Liste o que será removido (leia `iac/terraform/outputs.tf` e o state se o dev colar a saída):
   ALB, ASG/instâncias, RDS **e seus dados**, Secret, ECR (**e as imagens**), bucket S3 (**e os objetos**,
   por causa do `force_destroy`), WAF, VPC, dashboard, registros DNS.
3. Avise o que **não** é removido: o bucket de **state**, o usuário IAM do pipeline, a hosted zone.
4. Peça que o dev **digite o `environment_name`** para confirmar que sabe qual ambiente é.
5. Instrua: *Actions → Destroy Infrastructure → Run workflow*. Pergunte se quer exportar dados do RDS
   antes (o kit usa `skip_final_snapshot = true`: **não há snapshot final**).
6. Acompanhe o run (`gh run view`) e, no fim, peça para o dev conferir no console que não sobraram
   ALB, instâncias ou RDS (as maiores fontes de custo).

### Se o destroy falhar

- `AccessDenied` de IAM → `50-iam-e-permissoes.md`.
- Dependências (ENIs, SG em uso) → reexecute o destroy após alguns minutos.
- **Não** apague recursos manualmente no console antes de entender o state: isso cria divergência.

## Rollback de um deploy da aplicação

A imagem é versionada no ECR: `<usuario>-v1.0.<run_number>` e `latest`.

1. Identifique a tag boa anterior (`aws ecr describe-images`, ou os runs do `Deploy Backend API`).
2. **Caminho seguro:** reverter o commit ruim na `main` (PR de revert). O push dispara build + refresh com o
   código anterior.
3. **Caminho rápido:** reaponte `latest` para a tag anterior (o dev executa no terminal dele) e dispare o
   *instance refresh* da região:
   ```bash
   MANIFEST=$(aws ecr batch-get-image --repository-name REPO --image-ids imageTag=TAG_BOA \
     --query 'images[0].imageManifest' --output text --region us-east-1)
   aws ecr put-image --repository-name REPO --image-tag latest --image-manifest "$MANIFEST" --region us-east-1
   ```
   Depois: *Actions → Deploy Backend API → Run workflow* (ou `iac/scripts/refresh-instances.sh <região>`).
4. Valide com `curl` no health check e no fluxo principal.

## Rollback de infraestrutura

Reverta o PR de IaC e rode `Deploy Infrastructure` de novo. Atenção a mudanças que **substituem** recursos de
dados: o revert não recupera dados apagados.
