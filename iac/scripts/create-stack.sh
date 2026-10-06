#!/usr/bin/env bash
set -euo pipefail

REGION="$1"
STACK_NAME="caos-demo-${REGION}"

ROOT_DIR="$(dirname "$(dirname "$0")")"

if [ "$REGION" == "us-east-1" ]; then
  TEMPLATE_FILE="$ROOT_DIR/us-east-1-infra.yaml"
else
  TEMPLATE_FILE="$ROOT_DIR/eu-central-1-infra.yaml"
fi

echo "Validating template $TEMPLATE_FILE in $REGION"
aws cloudformation validate-template --template-body file://"$TEMPLATE_FILE" --region "$REGION"

echo "Creating/updating stack $STACK_NAME in $REGION"
aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM \
  --region "$REGION"

echo "Waiting for stack completion"
aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$REGION" || true

echo "Saving outputs to /tmp/outputs-${REGION}.json"
aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" \
  --query "Stacks[0].Outputs" > "/tmp/outputs-${REGION}.json"

echo "Done"
