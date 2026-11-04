# Deploy de APIs REST na AWS com Kiro

Kit para um dev publicar **qualquer API REST simples já pronta (com Dockerfile)** em um ambiente
resiliente na AWS, com o **Kiro guiando cada passo** e **guardrails** que impedem o agente de fazer
o que não deve.

## Em uma frase

O dev conversa com o Kiro; o Kiro pergunta, valida, adapta a IaC (Terraform), abre o PR e acompanha o
pipeline. **Quem aplica a infraestrutura é o GitHub Actions, por decisão humana.** O Kiro nunca vê
credenciais AWS.

## Mapa do kit

```
.kiro/
├── steering/                    # Regras e contexto que o Kiro lê
│   ├── 00-contexto-e-contrato   #   (sempre)   o que é o kit e qual o papel do Kiro
│   ├── 10-guardrails            #   (sempre)   regras inegociáveis e gates G1-G5
│   ├── 20-terraform             #   (arquivos .tf)  padrões de IaC
│   ├── 30-github-actions        #   (workflows)     padrões de pipeline
│   ├── 40-contrato-da-api       #   (auto)     o que a API precisa cumprir
│   └── 50-iam-e-permissoes      #   (auto)     lições de IAM/AccessDenied
├── skills/deploy-rest-api/      # O roteiro guiado (8 fases) + referências + templates
├── agents/deploy-guide.md       # Agente com permissões restritas
├── hooks/                       # Bloqueios automáticos (IDE e CLI)
└── settings/mcp.json            # Documentação oficial da AWS (somente leitura)

.github/
├── workflows/terraform-ci.yml   # fmt + validate + guarda de segredos (em todo PR)
├── workflows/terraform-plan.yml # plano manual, sem aplicar
├── pull_request_template.md
└── CODEOWNERS

iac/terraform/                   # IaC de referência (módulo por região)
docs/kiro-deploy/                # Esta documentação
```

## Leia nesta ordem

1. [`01-preparacao.md`](01-preparacao.md): GitHub, Kiro e AWS (uma vez só)
2. [`02-fluxo-guiado.md`](02-fluxo-guiado.md): como usar, com prompts prontos
3. [`03-guardrails.md`](03-guardrails.md): o que é imposto, onde, e o que **não** é
4. [`04-nova-api.md`](04-nova-api.md): usar o kit com outra API
5. [`05-roteiro-palestra.md`](05-roteiro-palestra.md): estrutura sugerida para a apresentação

## Início rápido

No Kiro, com este repositório (ou um fork/cópia com a sua API) aberto:

```
/deploy-rest-api
```

O Kiro mostra o mapa de fases e começa a entrevista.
