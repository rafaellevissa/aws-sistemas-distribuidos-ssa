#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-}"
STACK_NAME="caos-demo-${REGION}"

ROOT_DIR="$(dirname "$(dirname "$0")")"

if [ -z "$REGION" ]; then
  echo "Uso: $0 <region|dashboard>" >&2
  exit 1
fi

get_output() {
  local stack="$1" region="$2" key="$3"
  aws cloudformation describe-stacks \
    --stack-name "$stack" \
    --region "$region" \
    --query "Stacks[0].Outputs[?OutputKey=='${key}'].OutputValue" \
    --output text
}

if [ "$REGION" == "dashboard" ]; then
  # Painel unico (multi-regiao) hospedado em us-east-1
  REGION="us-east-1"
  STACK_NAME="caos-demo-dashboard"
  TEMPLATE_FILE="$ROOT_DIR/dashboard.yaml"
  PARAMS=""

  for SRC_REGION in us-east-1 eu-central-1; do
    PREFIX=$([ "$SRC_REGION" == "us-east-1" ] && echo "UsEast1" || echo "EuCentral1")
    for KEY in LoadBalancerFullName TargetGroupFullName AutoScalingGroupName; do
      VALUE=$(get_output "caos-demo-${SRC_REGION}" "$SRC_REGION" "$KEY")
      if [ -z "$VALUE" ] || [ "$VALUE" == "None" ]; then
        echo "Erro: output $KEY nao encontrado na stack caos-demo-${SRC_REGION} ($SRC_REGION)" >&2
        exit 1
      fi
      PARAMS="$PARAMS ${PREFIX}${KEY}=${VALUE}"
    done
  done
elif [ "$REGION" == "us-east-1" ]; then
  TEMPLATE_FILE="$ROOT_DIR/us-east-1-infra.yaml"
  PARAMS=""
else
  TEMPLATE_FILE="$ROOT_DIR/eu-central-1-infra.yaml"

  SOURCE_STACK="caos-demo-us-east-1"
  DB_HOST=$(get_output "$SOURCE_STACK" us-east-1 DBHost)

  DB_SECRET_NAME=$(get_output "$SOURCE_STACK" us-east-1 DBSecretName)

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
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --region "$REGION" \
    --parameter-overrides $PARAMS
else
  aws cloudformation deploy \
    --template-file "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --region "$REGION"
fi

echo "Waiting for stack completion"
aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION" || true

echo "Saving outputs to /tmp/outputs-${STACK_NAME}.json"
aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
  --query "Stacks[0].Outputs" > "/tmp/outputs-${STACK_NAME}.json"

echo "Done"
