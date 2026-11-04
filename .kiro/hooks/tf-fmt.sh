#!/usr/bin/env bash
# Hook PostFileSave (arquivos .tf). Formata a IaC. Nunca bloqueia: se o terraform nao
# estiver instalado, apenas avisa e segue.

if command -v terraform >/dev/null 2>&1; then
  terraform fmt -recursive iac/ >/dev/null 2>&1 && echo "terraform fmt aplicado em iac/"
else
  echo "terraform nao instalado; pulei o fmt (o workflow Terraform CI valida no PR)."
fi
exit 0
