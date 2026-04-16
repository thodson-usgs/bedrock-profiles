#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# setup.sh
#
# All-in-one interactive setup: discovers or creates tagged Bedrock inference
# profiles for a project, then configures ~/.claude/settings.json.
#
# Prerequisites:
#   - AWS CLI v2 with credentials configured (SSO, env vars, instance role, etc.)
#   - jq
#
# Usage:
#   ./setup.sh [--project-id ID] [--app-id ID] [--contact EMAIL] [--region REGION]
###############################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AWS_REGION="us-west-2"
PROJECT_ID=""
APP_ID=""
CONTACT=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Discovers or creates tagged Bedrock inference profiles and configures Claude Code.

Optional:
  --project-id ID      wma:project_id tag value
  --app-id ID          wma:application_id tag value (only needed if creating profiles)
  --contact EMAIL      wma:contact tag value (only needed if creating profiles)
  --region REGION      AWS region (default: us-west-2)
  -h, --help           Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --project-id uncertainty_ts --app-id claude --contact thodson@usgs.gov
EOF
  exit 0
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

for cmd in aws jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not found." >&2
    case "$(uname)" in
      Darwin) echo "Install with: brew install $cmd" >&2 ;;
      Linux)  echo "Install with: sudo apt install $cmd" >&2 ;;
      *)      echo "Install '$cmd' for your platform." >&2 ;;
    esac
    exit 1
  fi
done

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || {
  echo "Error: no active AWS credentials found." >&2
  echo "Configure credentials via SSO (aws sso login), environment variables," >&2
  echo "a named profile (AWS_PROFILE), or an instance role." >&2
  exit 1
}
echo "AWS account: $ACCOUNT_ID  region: $AWS_REGION"

if [[ -z "$PROJECT_ID" ]]; then
  read -r -p "Project ID (wma:project_id, e.g. uncertainty_ts): " PROJECT_ID
  [[ -z "$PROJECT_ID" ]] && { echo "Error: project ID is required." >&2; exit 1; }
fi

echo "Searching for existing profiles matching '$PROJECT_ID'..."

ALL_PROFILES=$(aws bedrock list-inference-profiles \
  --type-equals APPLICATION \
  --region "$AWS_REGION" \
  --output json)

PROFILE_COUNT=$(echo "$ALL_PROFILES" | jq --arg prefix "$PROJECT_ID" \
  '[.inferenceProfileSummaries[] | select(.inferenceProfileName | startswith($prefix))] | length')

if [[ "$PROFILE_COUNT" -eq 0 ]]; then
  echo "No profiles found. Creating new profiles for '$PROJECT_ID'."

  # Pass known args through; create-bedrock-profiles.sh prompts for any that are missing
  CREATE_ARGS=(--project-id "$PROJECT_ID" --region "$AWS_REGION")
  [[ -n "$APP_ID"  ]] && CREATE_ARGS+=(--app-id  "$APP_ID")
  [[ -n "$CONTACT" ]] && CREATE_ARGS+=(--contact "$CONTACT")

  bash "${SCRIPT_DIR}/create-bedrock-profiles.sh" "${CREATE_ARGS[@]}"
else
  echo "Found $PROFILE_COUNT existing profile(s) — skipping creation."
fi

bash "${SCRIPT_DIR}/configure-claude-cli.sh" \
  --project-id "$PROJECT_ID" \
  --region "$AWS_REGION"
