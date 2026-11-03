#!/usr/bin/env bash
# Dispara um instance refresh (rolling) no ASG de uma regiao, para redeployar a
# nova imagem Docker. O nome do ASG vem dos outputs do Terraform.
#
# Uso:
#   TF_STATE_BUCKET=meu-bucket-tfstate ./iac/scripts/refresh-instances.sh <region>
#
# <region> deve ser us-east-1 ou eu-central-1.
set -euo pipefail

REGION="${1:-}"
if [ -z "$REGION" ]; then
  echo "Uso: $0 <us-east-1|eu-central-1>" >&2
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/../terraform" && pwd)"
cd "$ROOT_DIR"

: "${TF_STATE_BUCKET:?Defina TF_STATE_BUCKET com o bucket S3 do state}"
TF_STATE_KEY="${TF_STATE_KEY:-aws-sistemas-distribuidos-ssa/terraform.tfstate}"
TF_STATE_REGION="${TF_STATE_REGION:-us-east-1}"

terraform init -input=false -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="key=${TF_STATE_KEY}" \
  -backend-config="region=${TF_STATE_REGION}" \
  -backend-config="encrypt=true" >/dev/null

case "$REGION" in
  us-east-1)    OUTPUT_KEY="us_east_1_autoscaling_group_name" ;;
  eu-central-1) OUTPUT_KEY="eu_central_1_autoscaling_group_name" ;;
  *) echo "Regiao invalida: $REGION" >&2; exit 1 ;;
esac

ASG_NAME=$(terraform output -raw "$OUTPUT_KEY")
if [ -z "$ASG_NAME" ] || [ "$ASG_NAME" == "None" ]; then
  echo "Nao foi possivel obter o nome do ASG para $REGION ($OUTPUT_KEY)" >&2
  exit 1
fi

REFRESH_ID=$(aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --region "$REGION" \
  --strategy Rolling \
  --preferences '{"MinHealthyPercentage":100,"MaxHealthyPercentage":150,"InstanceWarmup":180,"SkipMatching":false}' \
  --query InstanceRefreshId \
  --output text)

echo "Instance refresh $REFRESH_ID iniciado para $ASG_NAME ($REGION)"
echo "Acompanhe com: aws autoscaling describe-instance-refreshes --auto-scaling-group-name $ASG_NAME --instance-refresh-ids $REFRESH_ID --region $REGION"
