#!/usr/bin/env bash
# Destroi toda a infraestrutura multi-regiao provisionada pelo Terraform.
#
# Uso:
#   TF_STATE_BUCKET=meu-bucket-tfstate ./iac/scripts/destroy.sh
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

echo "==> terraform destroy"
terraform destroy -input=false -auto-approve
