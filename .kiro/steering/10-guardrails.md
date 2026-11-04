---
inclusion: always
---

# Guardrails (regras inegociáveis)

Estas regras valem em toda interação. Se o dev pedir algo que as viole, **explique a regra, ofereça
a alternativa segura e não execute**. Hooks e CI reforçam várias delas, mas **não dependa deles**:
no Kiro Web os hooks não executam, então estas regras precisam ser seguidas por você.

## 1. Credenciais e segredos

- **Nunca** peça, leia, imprima, grave ou faça commit de credenciais AWS, tokens, senhas, `.env`,
  `*.pem`, `*.tfstate`, `*.tfvars` (somente `*.example` é permitido).
- Credenciais do pipeline vivem **apenas** em GitHub Secrets. Quando o dev precisar criá-las, dê
  instruções para **ele mesmo** cadastrar. Você não executa `gh secret set`.
- Se um segredo aparecer em um log ou arquivo, avise o dev imediatamente e recomende rotacionar a chave.

## 2. Quem aplica a infraestrutura

- Você **nunca** roda `terraform apply`, `terraform destroy`, `terraform import`, `terraform state rm`,
  `-auto-approve` nem comandos `aws ... delete/terminate`. A infraestrutura só muda **pelo GitHub Actions**.
- `Deploy Infrastructure`: você pode disparar o workflow **somente depois** de o dev dizer explicitamente
  algo como "pode aplicar", e depois de mostrar o resumo do que será criado.
- `Destroy Infrastructure`: **só o humano dispara**. Você explica o que será removido e como disparar.

## 3. IAM e conta AWS

- Você **não** cria nem altera usuários, chaves ou policies IAM na conta. Gere o JSON da policy
  (veja `.kiro/skills/deploy-rest-api/assets/`) e instrua o dev a aplicá-lo no console IAM.
- O arquivo de policy do repositório é **documentação**: ele não aplica nada sozinho.
- Prefira **menor privilégio com escopo de recurso** (ARNs com o prefixo do ambiente). Evite `*` em
  `Resource`, exceto onde a AWS não permite escopo.

## 4. Git e revisão

- Trabalhe em branch (`feat/...`) e abra PR. **Nunca** faça push na `main`/`master` nem `--force`.
- Antes do commit rode as verificações locais possíveis (`terraform fmt`, `terraform validate`).
- Não altere guardrails (`.kiro/hooks/`, `.kiro/agents/`, este arquivo) sem o dev pedir **explicitamente**.

## 5. Custo e impacto

- Antes de propor recursos, informe o que gera custo contínuo: **RDS, ALB, instâncias EC2 do ASG**,
  segunda região. Mencione que o RDS leva cerca de 8 minutos para criar.
- Sempre informe como **destruir tudo** quando o ambiente for temporário (demo, palestra, teste).

## 6. Honestidade sobre "didático" vs. produção

Itens marcados como "didático" na IaC (SG com `0.0.0.0/0`, RDS `publicly_accessible`, SSH aberto,
`skip_final_snapshot`, `force_destroy`) **não são aceitáveis em produção**. Ao encontrá-los, avise e
proponha a versão restrita. Nunca descreva o ambiente como "pronto para produção" sem tratar esses itens.

## 7. Gates (você para e espera aprovação)

| Gate | Quando |
|---|---|
| G1 | Depois do preflight: confirmar o diagnóstico da API e o `deploy-config.yaml` |
| G2 | Depois de gerar a policy IAM e a lista de secrets: o dev confirma que aplicou |
| G3 | Antes de commitar mudanças de IaC: mostrar o resumo do diff |
| G4 | Antes de disparar o deploy: o dev diz explicitamente "pode aplicar" |
| G5 | Depois do deploy: apresentar a verificação (health check) e o custo corrente |

Nunca pule um gate, mesmo que o dev pareça com pressa. Se ele quiser acelerar, ofereça agrupar as perguntas.
