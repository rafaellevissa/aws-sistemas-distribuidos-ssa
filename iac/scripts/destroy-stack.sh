#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-}"

if [ -z "$REGION" ]; then
  echo "Uso: $0 <region|dashboard>" >&2
  echo "Exemplos: $0 us-east-1" >&2
  echo "          $0 eu-central-1" >&2
  echo "          $0 dashboard" >&2
  exit 1
fi

STACK_NAME="caos-demo-${REGION}"

if [ "$REGION" == "dashboard" ]; then
  REGION="us-east-1"
fi

echo "Iniciando remoção da stack ${STACK_NAME} na região ${REGION}"

aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$REGION" || true

echo "Aguardando exclusão da stack..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$REGION" || true

echo "Remoção da stack ${STACK_NAME} solicitada com sucesso."