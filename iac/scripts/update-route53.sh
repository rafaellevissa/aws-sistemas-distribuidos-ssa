#!/usr/bin/env bash
set -euo pipefail

HOSTED_ZONE_NAME="${1:-${HOSTED_ZONE_NAME:-}}"

if [ -z "$HOSTED_ZONE_NAME" ]; then
  echo "HOSTED_ZONE_NAME is empty. Skipping Route53 update."
  exit 0
fi

get_stack_output() {
  local region="$1"
  local key="$2"
  aws cloudformation describe-stacks \
    --stack-name "caos-demo-${region}" \
    --region "$region" \
    --query "Stacks[0].Outputs[?OutputKey=='${key}'].OutputValue" \
    --output text 2>/dev/null || true
}

get_alb_zone_id() {
  local region="$1"
  local dns_name="$2"
  aws elbv2 describe-load-balancers \
    --region "$region" \
    --query "LoadBalancers[?DNSName=='${dns_name}'].CanonicalHostedZoneId | [0]" \
    --output text 2>/dev/null || true
}

US_ALB_DNS=$(get_stack_output us-east-1 LoadBalancerDNS || true)
if [ -z "$US_ALB_DNS" ]; then
  US_ALB_DNS=$(get_stack_output us-east-1 ALBDNS || true)
fi

EU_ALB_DNS=$(get_stack_output eu-central-1 LoadBalancerDNS || true)
if [ -z "$EU_ALB_DNS" ]; then
  EU_ALB_DNS=$(get_stack_output eu-central-1 ALBDNS || true)
fi

US_ALB_ZONE=$(get_stack_output us-east-1 ALBHostedZoneID || true)
if [ -z "$US_ALB_ZONE" ]; then
  US_ALB_ZONE=$(get_alb_zone_id us-east-1 "$US_ALB_DNS")
fi

EU_ALB_ZONE=$(get_stack_output eu-central-1 ALBHostedZoneID || true)
if [ -z "$EU_ALB_ZONE" ]; then
  EU_ALB_ZONE=$(get_alb_zone_id eu-central-1 "$EU_ALB_DNS")
fi

if [ -z "$US_ALB_DNS" ] || [ -z "$EU_ALB_DNS" ] || [ -z "$US_ALB_ZONE" ] || [ -z "$EU_ALB_ZONE" ]; then
  echo "Missing ALB outputs for Route53. Check the CloudFormation stacks in us-east-1 and eu-central-1."
  exit 1
fi

SUBDOMAIN_PARAM="${2:-}"
SUBDOMAIN="${SUBDOMAIN_PARAM:-unifan-sistemas-distribuidos2}"
FQDN="${SUBDOMAIN}.${HOSTED_ZONE_NAME}."

cat > /tmp/route53-change.json <<EOF
{
  "Comment": "Create latency-based records for application",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${FQDN}",
        "Type": "A",
        "SetIdentifier": "us-east-1",
        "Region": "us-east-1",
        "AliasTarget": {
          "HostedZoneId": "${US_ALB_ZONE}",
          "DNSName": "${US_ALB_DNS}",
          "EvaluateTargetHealth": true
        }
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${FQDN}",
        "Type": "A",
        "SetIdentifier": "eu-central-1",
        "Region": "eu-central-1",
        "AliasTarget": {
          "HostedZoneId": "${EU_ALB_ZONE}",
          "DNSName": "${EU_ALB_DNS}",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
EOF

echo "Applying Route53 change for ${FQDN} in hosted zone ${HOSTED_ZONE_NAME}"
aws route53 change-resource-record-sets --hosted-zone-name "${HOSTED_ZONE_NAME}." --change-batch file:///tmp/route53-change.json

echo "Done"
