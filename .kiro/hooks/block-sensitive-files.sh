#!/usr/bin/env bash
# Hook PreToolUse (matchers: read e write). Impede ler/gravar arquivos com segredos.
# Arquivos *.example sao permitidos. Exit 2 = bloqueia e devolve STDERR ao agente.

input="$(cat)"

# O caminho aparece no JSON como "...nome-do-arquivo" (termina em aspas).
if printf '%s' "$input" | grep -Eiq '(\.env|\.env\.(local|prod|production|dev|development|staging)|\.pem|\.tfstate|\.tfstate\.backup|[^a-z]terraform\.tfvars|\.auto\.tfvars|backend\.hcl|\.aws/credentials)\\?"'; then
  echo "BLOQUEADO pelo guardrail: arquivo potencialmente sensivel (.env, .pem, .tfstate, .tfvars, backend.hcl, credentials)." >&2
  echo "Alternativa: use os arquivos *.example e mantenha valores reais em GitHub Secrets." >&2
  exit 2
fi

exit 0
