# 05. Roteiro sugerido para a palestra

Título: **Da API à AWS com o Kiro: deploy guiado, com guardrails**.
Duração de referência: 45 min (30 min de demo + 15 min de conceitos e perguntas).

## Mensagem central

> IA acelera infraestrutura, mas **quem decide e quem tem as chaves continua sendo o humano**.
> O truque é dar ao agente **contexto** (steering/skills) e **limites** (permissões, hooks, CI), e não
> dar a ele credenciais.

## Estrutura

| Min | Bloco | Conteúdo | Mostrar |
|---|---|---|---|
| 0–5 | Problema | Deploy resiliente é trabalho repetitivo e cheio de armadilhas | A arquitetura (ALB, ASG multi-AZ, RDS) |
| 5–10 | Kiro em 5 conceitos | Steering, Skills, Agentes, Hooks, Specs/MCP | `.kiro/` aberto |
| 10–15 | Preparação | Repo GitHub → Kiro → conta AWS (IAM + secrets) | `01-preparacao.md` |
| 15–35 | **Demo ao vivo** | `/deploy-rest-api`: entrevista → preflight → IaC → PR → plan → apply → `curl` | Fluxo guiado e gates |
| 35–40 | Guardrails | Tentar `terraform apply` e `cat .env` e ver o bloqueio | Hooks em ação |
| 40–45 | Lições e perguntas | Onde falhou na vida real | Lista abaixo |

## Demo: roteiro minuto a minuto

1. Mostrar a API pronta (CRUD de usuários + Dockerfile).
2. `/deploy-rest-api` → o Kiro mostra o mapa de fases e pergunta.
3. **Preflight (G1):** tabela ✅/⚠️/❌ do contrato da API.
4. **Fase 2 (G2):** mostrar que *você* cria IAM e secrets e o Kiro só instrui. Destaque: "ele nunca vê a chave".
5. **Fase 3–4 (G3):** diff da IaC, PR, `Terraform CI` verde.
6. **Fase 5 (G4):** `Terraform Plan` → resumo → "pode aplicar" → `Deploy Infrastructure`.
   O RDS leva ~8 min: **tenha um ambiente já criado ou um vídeo** para esse trecho.
7. **Fase 6:** `curl` no health check e CRUD completo.
8. **Guardrail ao vivo:** pedir `terraform apply -auto-approve` e `cat .env`, e mostrar o bloqueio.
9. **Destroy:** o Kiro explica; você dispara o workflow.

## Dicas de demo

- Faça uma **rodada completa antes**, para validar IAM e secrets. Os `AccessDenied` aparecem só depois de
  minutos de `apply`.
- Prepare o ambiente com antecedência e use um **segundo ambiente** para o que for ao vivo.
- Se for demonstrar guardrails por hooks, use **Kiro IDE ou CLI**. No Web os hooks não executam.
- Tenha o plano B: prints do `curl` e do dashboard do CloudWatch.

## Lições reais deste projeto (ótimas para a palestra)

1. **CloudFormation → Terraform muda quem chama a API.** O CloudFormation age com o contexto do serviço;
   o Terraform age como o seu usuário. Resultado: `iam:ListRolePolicies`, `iam:ListInstanceProfilesForRole`,
   `iam:TagInstanceProfile`... um `AccessDenied` por vez, cada um depois de um `apply` longo.
2. **O arquivo de policy no repositório não aplica nada.** O mesmo erro, com o mesmo RequestID, era sinal de
   policy não aplicada.
3. **Corrida entre jobs:** o build precisava do ECR, que o Terraform ainda criava. Solução adotada: jobs em
   paralelo com espera de 20s (simples, mas é uma decisão consciente, não garantia).
4. **Escopar em vez de enumerar:** `iam:*` limitado aos ARNs da stack encerrou o ciclo de erros sem abrir
   a conta.
5. **Guardrails em camadas:** instruções ao modelo, permissões, hooks, CI e revisão humana.
   Nenhuma sozinha basta.

## Perguntas que a plateia costuma fazer

- *"O Kiro pode destruir minha conta?"* Não tem credenciais; o apply é do pipeline; o destroy é humano.
- *"E se o modelo ignorar o steering?"* Por isso existem permissões, hooks, CI e CODEOWNERS.
- *"Funciona com outra nuvem/linguagem?"* O fluxo e os guardrails sim; a IaC precisa ser reescrita.
- *"Quanto custa?"* ALB + EC2 + RDS + WAF enquanto existirem. Destrua ao final.
