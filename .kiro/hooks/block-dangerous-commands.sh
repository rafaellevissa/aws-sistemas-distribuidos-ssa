#!/usr/bin/env bash
# Hook PreToolUse (matcher: shell). Bloqueia comandos perigosos antes de executarem.
# Recebe o JSON do evento em STDIN. Exit 2 = bloqueia e devolve STDERR ao agente.
# O schema exato do JSON nao e garantido, entao procuramos o padrao no payload inteiro.
# Nao e uma barreira de seguranca completa: reforca as regras do steering e do CI.

input="$(cat)"

block() {
  echo "BLOQUEADO pelo guardrail: $1" >&2
  echo "Alternativa: $2" >&2
  exit 2
}

match() { printf '%s' "$input" | grep -Eiq -- "$1"; }

# 1. Aplicar/destruir infraestrutura fora do pipeline
match 'terraform[[:space:]]+(apply|destroy|import|force-unlock|taint|untaint)' &&
  block "terraform apply/destroy/import nao rodam pelo agente." \
        "Altere a IaC, abra PR e dispare o workflow 'Deploy Infrastructure' (apply) ou deixe o dev disparar o destroy."
match 'terraform[[:space:]]+state[[:space:]]+(rm|mv|push)' &&
  block "alterar o state manualmente." "Peça ao dev; mexer no state exige revisao humana."
match '(^|[^a-z])-auto-approve' &&
  block "uso de -auto-approve." "A aprovacao deve ser humana, via workflow."

# 2. AWS CLI: IAM, configuracao de credenciais e delecoes
match 'aws[[:space:]]+iam[[:space:]]' &&
  block "aws iam pelo agente." "Gere o JSON da policy e peca ao dev para aplicar no console IAM."
match 'aws[[:space:]]+configure' &&
  block "configurar credenciais AWS." "Credenciais ficam so em GitHub Secrets."
match 'aws[[:space:]]+[a-z0-9-]+[[:space:]]+(delete-|terminate-|deregister-|remove-)' &&
  block "remocao de recurso pela AWS CLI." "Remova pelo Terraform/pipeline para manter o state consistente."
match 'aws[[:space:]]+s3[[:space:]]+(rb|rm)' &&
  block "remocao em S3 pela AWS CLI." "Use o pipeline (force_destroy) ou peca ao dev."

# 3. Segredos
match 'gh[[:space:]]+(secret|auth)' &&
  block "manipular secrets/autenticacao do GitHub." "O dev cadastra secrets em Settings > Secrets and variables > Actions."
match '(cat|less|more|head|tail|grep|sed|awk|base64|xxd)[[:space:]][^|;&]*(\.env([[:space:]"\\]|$)|\.pem|\.tfstate|terraform\.tfvars|backend\.hcl|\.aws/credentials)' &&
  block "ler arquivo com possiveis segredos." "Use os arquivos .example; nao exponha valores reais."
match '(printenv|echo|env)[[:space:]][^|;&]*(AWS_SECRET|AWS_ACCESS|PASSWORD|TOKEN|SECRET)' &&
  block "imprimir variavel de ambiente sensivel." "Nao exiba segredos em log ou chat."

# 4. Git
match 'git[[:space:]]+push[^|;&]*(--force|--force-with-lease|[[:space:]]-f([[:space:]]|$))' &&
  block "git push --force." "Faca um novo commit ou PR de correcao."
match 'git[[:space:]]+push[^|;&]*[[:space:]](HEAD:)?(refs/heads/)?(main|master)([[:space:]]|$|["\\])' &&
  block "push direto na main/master." "Trabalhe em branch feat/... e abra PR."
match 'git[[:space:]]+reset[[:space:]]+--hard' &&
  block "git reset --hard." "Use git revert ou pergunte ao dev."

# 5. Workflow de destroy e APIs destrutivas do GitHub
match 'gh[[:space:]]+workflow[[:space:]]+run[^|;&]*destroy' &&
  block "disparar o workflow de destroy." "Somente o humano dispara o destroy (Actions > Destroy Infrastructure)."
match 'gh[[:space:]]+api[^|;&]*(-X|--method)[[:space:]]*DELETE' &&
  block "DELETE na API do GitHub." "Peca ao dev."

# 6. Destrutivo generico
match 'rm[[:space:]]+-[a-z]*r[a-z]*f?[[:space:]]+(/|~|\$HOME|\*|\.\.?)([[:space:]]|$|")' &&
  block "rm -rf em caminho amplo." "Remova arquivos especificos."
match '(curl|wget)[^|;&]*\|[[:space:]]*(sudo[[:space:]]+)?(ba)?sh' &&
  block "executar script baixado diretamente (curl | sh)." "Baixe, revise e so entao execute."
match 'sudo[[:space:]]' &&
  block "uso de sudo." "O agente nao precisa de privilegios elevados."

exit 0
