#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-}"
STACK_NAME="caos-demo-${REGION}"

ROOT_DIR="$(dirname "$(dirname "$0")")"

if [ -z "$REGION" ]; then
  echo "Uso: $0 <region>" >&2
  exit 1
fi

if [ "$REGION" == "us-east-1" ]; then
  TEMPLATE_FILE="$ROOT_DIR/us-east-1-infra.yaml"
  PARAMS=""
else
  TEMPLATE_FILE="$ROOT_DIR/eu-central-1-infra.yaml"

  SOURCE_STACK="caos-demo-us-east-1"
  DB_HOST=$(aws cloudformation describe-stacks \
    --stack-name "$SOURCE_STACK" \
    --region us-east-1 \
    --query "Stacks[0].Outputs[?OutputKey=='DBHost'].OutputValue" \
    --output text)

  DB_SECRET_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$SOURCE_STACK" \
    --region us-east-1 \
    --query "Stacks[0].Outputs[?OutputKey=='DBSecretName'].OutputValue" \
    --output text)

  if [ -z "$DB_HOST" ] || [ -z "$DB_SECRET_NAME" ]; then
    echo "Erro: nao foi possivel localizar DBHost ou DBSecretName na stack $SOURCE_STACK (us-east-1)" >&2
    exit 1
  fi

  PARAMS="DBHost=${DB_HOST} DBSecretName=${DB_SECRET_NAME} DBSecretRegion=us-east-1"
fi

echo "Validating template $TEMPLATE_FILE in $REGION"
aws cloudformation validate-template --template-body file://"$TEMPLATE_FILE" --region "$REGION"

echo "Creating/updating stack $STACK_NAME in $REGION"
if [ -n "$PARAMS" ]; then
  aws cloudformation deploy \
    --template-file "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION" \
    --parameter-overrides $PARAMS
else
  aws cloudformation deploy \
    --template-file "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM \
    --region "$REGION"
fi

echo "Waiting for stack completion"
aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION" || true

echo "Saving outputs to /tmp/outputs-${REGION}.json"
aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
  --query "Stacks[0].Outputs" > "/tmp/outputs-${REGION}.json"

echo "Done"
