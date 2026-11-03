#!/usr/bin/env bash
# Provisiona toda a infraestrutura multi-regiao com Terraform.
# State em S3 (sem lock DynamoDB). O bucket de state deve existir previamente.
#
# Uso:
#   TF_STATE_BUCKET=meu-bucket-tfstate ./iac/scripts/apply.sh
#
# Variaveis opcionais:
#   TF_STATE_KEY     (default: aws-sistemas-distribuidos-ssa/terraform.tfstate)
#   TF_STATE_REGION  (default: us-east-1)
#   TF_IMAGE_TAG     tag da imagem no ECR (default: latest)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/../terraform" && pwd)"
cd "$ROOT_DIR"

: "${TF_STATE_BUCKET:?Defina TF_STATE_BUCKET com o bucket S3 do state}"
TF_STATE_KEY="${TF_STATE_KEY:-aws-sistemas-distribuidos-ssa/terraform.tfstate}"
TF_STATE_REGION="${TF_STATE_REGION:-us-east-1}"

echo "==> terraform init (backend S3: s3://${TF_STATE_BUCKET}/${TF_STATE_KEY})"
terraform init -input=false -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=${TF_STATE_KEY}" \
  -backend-config="region=${TF_STATE_REGION}" \
  -backend-config="encrypt=true"

EXTRA_ARGS=()
if [ -n "${TF_IMAGE_TAG:-}" ]; then
  EXTRA_ARGS+=(-var "image_tag=${TF_IMAGE_TAG}")
fi

echo "==> terraform validate"
terraform validate

echo "==> terraform apply"
terraform apply -input=false -auto-approve "${EXTRA_ARGS[@]}"

echo "==> Outputs:"
terraform output
