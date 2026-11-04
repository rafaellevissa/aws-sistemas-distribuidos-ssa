---
inclusion: auto
name: iam-e-permissoes
description: Permissões IAM do usuário do pipeline e erros AccessDenied/403 ao rodar Terraform. Use ao configurar credenciais AWS, montar policies ou diagnosticar falhas de permissão no apply/destroy.
---

# IAM e permissões do pipeline (lições aprendidas)

## Por que o Terraform pede mais permissão que o CloudFormation

O **CloudFormation** é um serviço gerenciado: ao criar ou apagar uma stack ele age com o contexto do
próprio serviço, então o usuário só precisa de `cloudformation:*`. O **Terraform roda como o usuário do
pipeline** e chama as APIs diretamente. Por isso, no `refresh`, no `apply` e no `destroy` ele faz leituras
e escritas que o usuário precisa ter **explicitamente**.

Sintomas reais já vistos neste projeto, em ordem:

| Erro (AccessDenied) | Quando aparece | Causa |
|---|---|---|
| `iam:ListRolePolicies` | refresh/destroy | A role tem policy inline; o provider lista para comparar |
| `iam:ListInstanceProfilesForRole` | destroy | O provider desvincula a role dos instance profiles antes de apagar |
| `iam:TagInstanceProfile` | apply | O `default_tags` do provider tagueia o instance profile |

## Estratégia recomendada

Em vez de enumerar ação por ação (e descobrir cada uma depois de 8 minutos de RDS), conceda
**`iam:*` com `Resource` restrito** aos recursos da stack:

```
arn:aws:iam::<ACCOUNT_ID>:role/<environment_name>-ec2-*
arn:aws:iam::<ACCOUNT_ID>:instance-profile/<environment_name>-ec2-*
```

mais `iam:PassRole` com a condição `iam:PassedToService = ec2.amazonaws.com`.
O template pronto está em `.kiro/skills/deploy-rest-api/assets/iam-pipeline-policy.template.json`.

## Como diagnosticar um AccessDenied

1. Leia a mensagem: ela diz **a ação** (`iam:XYZ`) e **o recurso** negado.
2. Compare o `RequestID`/authorization id com o erro anterior. **Se for idêntico, a policy ainda não foi
   aplicada** ao usuário: o arquivo JSON do repositório é só documentação.
3. Se a ação já está na policy aplicada e o erro persiste, suspeite de **SCP da organização** ou
   **permissions boundary**.
4. Corrija a policy **no template/documentação** e peça ao dev para atualizá-la no console IAM.
   Aguardar ~10–20s para propagar.

## Proibido

Você não executa `aws iam ...`. Ver guardrail 3.
