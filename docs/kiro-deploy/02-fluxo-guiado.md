# 02. Fluxo guiado

Você conversa; o Kiro conduz. Em **cinco pontos** ele para e espera o seu "ok" (os *gates*).

```
Fase 0  Entrevista ──► Fase 1  Preflight ──► G1
                                              │
Fase 2  GitHub + AWS (você faz) ─────────────► G2
                                              │
Fase 3  Adaptar IaC ─────────────────────────► G3
                                              │
Fase 4  PR + CI ──► (você faz o merge)
                                              │
Fase 5  Plan ──► "pode aplicar" ─────────────► G4 ──► Deploy
                                              │
Fase 6  Validação ──► Fase 7  Entrega ───────► G5
```

## Prompts prontos

Copie e cole no chat do Kiro.

**Começar do zero**
```
/deploy-rest-api
Quero publicar minha API na AWS. Ela já tem Dockerfile.
```

**Retomar de uma fase**
```
/deploy-rest-api
Já fiz a preparação (bucket, IAM e secrets). Pode seguir da fase 3.
```

**Só avaliar se a API está pronta**
```
Faça apenas o preflight da minha API (fase 1) e me diga o que precisa ajustar. Não altere nada.
```

**Entender um erro de pipeline**
```
O workflow falhou. Leia o log do último run, explique a causa em português e proponha a correção.
```

**Ver o plano antes de aplicar**
```
Rode o Terraform Plan e me resuma o que será criado, alterado e destruído.
```

**Autorizar o deploy** (só diga isso quando tiver revisado o plano)
```
Revisei o plano. Pode aplicar.
```

**Destruir o ambiente** (o Kiro explica; **você** dispara o workflow)
```
Quero destruir o ambiente de teste. Me diga exatamente o que será removido e como executar.
```

## O que o Kiro faz e o que ele NÃO faz

| O Kiro faz | O Kiro **não** faz |
|---|---|
| Ler o código e avaliar a API | Pedir ou ver credenciais AWS |
| Preencher `deploy-config.yaml` perguntando | Rodar `terraform apply` / `destroy` |
| Gerar o JSON da policy IAM | Criar usuários, chaves ou policies na AWS |
| Editar IaC e workflows em branch | Fazer push na `main` ou `--force` |
| Abrir PR e ler logs de CI | Cadastrar secrets no GitHub |
| Disparar o deploy **depois do seu "pode aplicar"** | Disparar o **destroy** |
| Validar com `curl` e relatar evidências | Declarar sucesso sem verificar |

## Quanto tempo leva

| Etapa | Tempo típico |
|---|---|
| Entrevista + preflight | 5–10 min |
| Preparação AWS/GitHub (fase 2) | 15–20 min |
| Adaptar IaC + PR | 10–20 min |
| `terraform apply` (o RDS domina) | ~10–15 min |
| Validação e entrega | 5 min |

## Custos

ALB, EC2, RDS e WAF cobram enquanto existirem. Se o ambiente for temporário, **destrua ao final**.
O Kiro lembra disso na fase 7.
