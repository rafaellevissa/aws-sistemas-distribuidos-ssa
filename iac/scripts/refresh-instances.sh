#!/usr/bin/env bash
set -euo pipefail

REGION="${1:-}"
if [ -z "$REGION" ]; then
  echo "Usage: $0 <region>" >&2
  exit 1
fi

STACK_NAME="caos-demo-${REGION}"
ASG_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='AutoScalingGroupName'].OutputValue" \
  --output text)

if [ -z "$ASG_NAME" ] || [ "$ASG_NAME" == "None" ]; then
  echo "AutoScalingGroupName was not found in $STACK_NAME ($REGION)" >&2
  exit 1
fi

REFRESH_ID=$(aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --region "$REGION" \
  --strategy Rolling \
  --preferences '{"MinHealthyPercentage":100,"MaxHealthyPercentage":150,"InstanceWarmup":180,"SkipMatching":false}' \
  --query InstanceRefreshId \
  --output text)

echo "Started instance refresh $REFRESH_ID for $ASG_NAME ($REGION)"
echo "Monitor completion with: aws autoscaling describe-instance-refreshes --auto-scaling-group-name $ASG_NAME --instance-refresh-ids $REFRESH_ID --region $REGION"