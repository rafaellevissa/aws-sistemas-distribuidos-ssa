#!/usr/bin/env bash
set -euo pipefail

HOSTED_ZONE_NAME="$1" # example: rafaellevi.com.br
US_EAST_OUTPUTS="/tmp/outputs-us-east-1.json"
EU_OUTPUTS="/tmp/outputs-eu-central-1.json"

if [ ! -f "$US_EAST_OUTPUTS" ] || [ ! -f "$EU_OUTPUTS" ]; then
  echo "Outputs not found. Run create-stack.sh for both regions first."
  exit 1
fi

US_ALB_DNS=$(jq -r '.[] | select(.OutputKey=="ALBDNS") | .OutputValue' "$US_EAST_OUTPUTS" || true)
if [ -z "$US_ALB_DNS" ]; then
  US_ALB_DNS=$(jq -r '.[] | select(.OutputKey=="ALBDNS") | .OutputValue' "$EU_OUTPUTS" || true)
fi

EU_ALB_DNS=$(jq -r '.[] | select(.OutputKey=="ALBDNS") | .OutputValue' "$EU_OUTPUTS")

US_ALB_ZONE=$(jq -r '.[] | select(.OutputKey=="ALBHostedZoneID") | .OutputValue' "$US_EAST_OUTPUTS" || true)
EU_ALB_ZONE=$(jq -r '.[] | select(.OutputKey=="ALBHostedZoneID") | .OutputValue' "$EU_OUTPUTS")

if [ -z "$US_ALB_DNS" ] || [ -z "$EU_ALB_DNS" ] || [ -z "$US_ALB_ZONE" ] || [ -z "$EU_ALB_ZONE" ]; then
  echo "Missing ALB outputs. Check /tmp/outputs-*.json"
  exit 1
fi

SUBDOMAIN_PARAM="${2:-}"
SUBDOMAIN="${SUBDOMAIN_PARAM:-unifan-sistemas-distribuidos2}"
FQDN="${SUBDOMAIN}.${HOSTED_ZONE_NAME}"

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
