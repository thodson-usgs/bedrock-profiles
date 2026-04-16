#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# create-bedrock-profiles.sh
#
# Creates tagged Bedrock application inference profiles for Claude Code models.
# Run once per project (or re-run when models are added/updated — existing
# profiles are skipped).
#
# Prerequisites:
#   - AWS CLI v2 with credentials configured (SSO, env vars, instance role, etc.)
#   - jq
#
# Usage:
#   ./create-bedrock-profiles.sh \
#       --project-id  uncertainty_ts \
#       --app-id      claude \
#       --contact     thodson@usgs.gov
###############################################################################

# Edit this list when new Claude models are released or old ones are retired.
# Each entry is a Bedrock system inference profile ID (us.anthropic.claude-*).
MODELS=(
  us.anthropic.claude-opus-4-6-v1
  us.anthropic.claude-sonnet-4-6
  us.anthropic.claude-haiku-4-5-20251001-v1:0
)

AWS_REGION="${AWS_REGION:-us-west-2}"
PROJECT_ID=""
APP_ID=""
CONTACT=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Creates tagged Bedrock inference profiles for Claude Code models.

Required:
  --project-id ID      wma:project_id tag value
  --app-id ID          wma:application_id tag value
  --contact EMAIL      wma:contact tag value

Optional:
  --region REGION      AWS region (default: us-west-2)

Examples:
  $(basename "$0") --project-id uncertainty_ts --app-id claude --contact thodson@usgs.gov
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id)  PROJECT_ID="$2";  shift 2 ;;
    --app-id)      APP_ID="$2";      shift 2 ;;
    --contact)     CONTACT="$2";     shift 2 ;;
    --region)      AWS_REGION="$2";  shift 2 ;;
    -h|--help)     usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [[ -z "$PROJECT_ID" ]]; then
  read -r -p "Project ID (wma:project_id, e.g. uncertainty_ts): " PROJECT_ID  [[ -z "$PROJECT_ID" ]] && { echo "Error: project ID is required." >&2; exit 1; }
fi
if [[ -z "$APP_ID" ]]; then
  read -r -p "Application ID (wma:application_id, e.g. claude): " APP_ID  [[ -z "$APP_ID" ]] && { echo "Error: application ID is required." >&2; exit 1; }
fi
if [[ -z "$CONTACT" ]]; then
  read -r -p "Contact email (wma:contact, e.g. user@usgs.gov): " CONTACT  [[ -z "$CONTACT" ]] && { echo "Error: contact email is required." >&2; exit 1; }
fi

for cmd in aws jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not found in PATH." >&2
    exit 1
  fi
done

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
  echo "Error: no active AWS credentials found." >&2
  echo "Configure credentials via SSO (aws sso login), environment variables," >&2
  echo "a named profile (AWS_PROFILE), or an instance role." >&2
  exit 1
}
echo "AWS Account: $ACCOUNT_ID  Region: $AWS_REGION"

echo ""
echo "Validating ${#MODELS[@]} model(s)..."

ACCOUNT_ARN_PREFIX="arn:aws:bedrock:${AWS_REGION}:${ACCOUNT_ID}"

for SYSTEM_ID in "${MODELS[@]}"; do
  if ! aws bedrock get-inference-profile \
      --inference-profile-identifier "$SYSTEM_ID" \
      --region "$AWS_REGION" &>/dev/null; then
    echo "Error: system inference profile '$SYSTEM_ID' not found." >&2
    echo "Run: aws bedrock list-inference-profiles --type-equals SYSTEM_DEFINED" >&2
    echo "to see available profiles, then update the MODELS array in this script." >&2
    exit 1
  fi
done
echo "All models validated."

EXISTING_PROFILES=$(aws bedrock list-inference-profiles \
  --type-equals APPLICATION \
  --region "$AWS_REGION" \
  --query 'inferenceProfileSummaries[].inferenceProfileName' \
  --output json)

echo ""
TAGS=$(jq -nc \
  --arg pid "$PROJECT_ID" \
  --arg aid "$APP_ID" \
  --arg con "$CONTACT" \
  '[{key:"wma:project_id",value:$pid},{key:"wma:application_id",value:$aid},{key:"wma:contact",value:$con}]')

for SYSTEM_ID in "${MODELS[@]}"; do
  SYSTEM_ARN="${ACCOUNT_ARN_PREFIX}:inference-profile/${SYSTEM_ID}"

  MODEL_SLUG=$(echo "$SYSTEM_ID" | sed 's/^us\.anthropic\.//' | tr '.:' '--')
  PROFILE_NAME="${PROJECT_ID}-${APP_ID}-${MODEL_SLUG}"

  if echo "$EXISTING_PROFILES" | jq -e --arg name "$PROFILE_NAME" 'index($name) != null' &>/dev/null; then
    echo "  SKIP  $PROFILE_NAME (already exists)"
    continue
  fi

  RESULT=$(aws bedrock create-inference-profile \
    --inference-profile-name "$PROFILE_NAME" \
    --description "${PROJECT_ID} ${APP_ID}" \
    --model-source "{\"copyFrom\": \"$SYSTEM_ARN\"}" \
    --tags "$TAGS" \
    --region "$AWS_REGION" \
    --output json 2>&1) || {
      echo "  FAIL  $PROFILE_NAME: $RESULT"
      continue
    }

  ARN=$(echo "$RESULT" | jq -r '.inferenceProfileArn')
  echo "  OK    $PROFILE_NAME → $ARN"
done

echo ""
echo "Done. Profiles are tagged with:"
echo "  wma:project_id=$PROJECT_ID"
echo "  wma:application_id=$APP_ID"
echo "  wma:contact=$CONTACT"
echo ""
echo "Users can now run: ./configure-claude-cli.sh --project-id $PROJECT_ID"
