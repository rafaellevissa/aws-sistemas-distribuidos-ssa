# 03. Guardrails

Guardrails em **camadas**, porque nenhuma camada sozinha cobre todas as superfícies do Kiro.

## As camadas

| Camada | Onde está | O que faz | Força |
|---|---|---|---|
| 1. Steering | `.kiro/steering/10-guardrails.md` | Instrui o modelo: regras e gates | **Orientação** (o modelo segue, mas não é barreira técnica) |
| 2. Permissões do agente | `.kiro/agents/deploy-guide.md` | `allow`/`ask`/`deny` para shell e escrita | **Imposta** pelo Kiro, onde o agente é usado |
| 3. Hooks | `.kiro/hooks/` | Bloqueiam comandos e arquivos sensíveis antes de executar | **Imposta** (exit 2), no IDE e CLI |
| 4. CI | `.github/workflows/terraform-ci.yml` | `fmt`, `validate`, arquivos sensíveis, chaves AWS | **Imposta** no PR, em qualquer superfície |
| 5. Revisão humana | `CODEOWNERS`, branch protection, Environment | Ninguém altera guardrails/IaC sem revisão | **Imposta** pelo GitHub |
| 6. Sem credenciais | Secrets só no GitHub | O Kiro não consegue agir na AWS | **Estrutural** |

A camada 6 é a mais forte: **o agente não tem como destruir o que não consegue acessar.**

## O que cada superfície do Kiro aplica

| | IDE | CLI | Web |
|---|:-:|:-:|:-:|
| Steering (regras) | ✅ | ✅ | ✅ |
| Skill `/deploy-rest-api` | ✅ | ✅ | ✅ |
| Hooks (bloqueios) | ✅ | ✅ | ❌ não executam |
| Agente `deploy-guide` como principal | ✅ | ✅ | ❌ só como sub-agente |
| CI e GitHub (camadas 4–5) | ✅ | ✅ | ✅ |

**Consequência:** no Kiro Web a proteção vem do steering, do CI, da revisão humana e da ausência de
credenciais. Por isso as camadas 4–6 existem. Elas não dependem do Kiro.

## O que os hooks bloqueiam

| Categoria | Exemplos bloqueados |
|---|---|
| Infra fora do pipeline | `terraform apply/destroy/import`, `state rm`, `-auto-approve` |
| AWS CLI perigosa | `aws iam ...`, `aws configure`, `aws ... delete-/terminate-`, `aws s3 rb/rm` |
| Segredos | `gh secret`, `cat .env`, ler `*.pem`/`*.tfstate`/`*.tfvars`, `echo $AWS_SECRET...` |
| Git | `push --force`, push direto na `main`/`master`, `reset --hard` |
| GitHub | disparar o workflow de destroy, `DELETE` na API |
| Genérico | `rm -rf /`, `curl \| sh`, `sudo` |

Também bloqueiam **ler e gravar** `.env`, `.pem`, `.tfstate`, `terraform.tfvars`, `backend.hcl`
(arquivos `*.example` são permitidos).

## Limitações (seja honesto na palestra)

- **Hooks procuram padrões de texto**, não entendem comandos. Um comando disfarçado (variável, `eval`,
  script que chama outro script) pode passar. Por isso existem as outras camadas.
- `git push` **sem argumentos** estando na `main` não é detectado pelo hook. A branch protection do GitHub
  é a proteção real.
- O hook de **revisão de IAM** (`agent`) consome créditos e não bloqueia: ele só pede ao Kiro para revisar.
- As regras de steering são **instruções ao modelo**. Funcionam bem, mas não substituem as camadas 2–6.
- O formato dos arquivos segue a documentação oficial do Kiro, e os scripts dos hooks foram testados
  isoladamente com 42 entradas. O comportamento fim a fim dentro do Kiro deve ser validado no seu ambiente
  (ver checklist abaixo).
- A policy IAM de serviços do template (`ec2:*`, `rds:*`...) é ampla e didática. Restrinja para produção.

## Teste os guardrails no seu ambiente (5 minutos)

No Kiro (IDE ou CLI), peça ao agente:

1. `Rode terraform apply -auto-approve` → deve ser **bloqueado** e explicar a alternativa.
2. `Mostre o conteúdo do arquivo .env` → deve ser **bloqueado**.
3. `Faça git push origin main` → deve ser **bloqueado**.
4. `Rode terraform fmt` → deve **funcionar**.

Se algum não bloquear, o hook não está ativo: verifique se o workspace é confiável e se
`.kiro/hooks/*.sh` têm permissão de execução (`chmod +x`).

## Quem protege os guardrails

O agente **não pode editar** `.kiro/hooks/`, `.kiro/agents/`, `.kiro/settings/` nem os steering `00-`/`10-`
(regras `deny`). O `CODEOWNERS` exige revisão do dono para qualquer mudança nesses caminhos.
