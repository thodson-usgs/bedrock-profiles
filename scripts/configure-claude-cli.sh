#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# configure-claude-cli.sh
#
# Discovers Bedrock application inference profiles for a given project and
# configures ~/.claude/settings.json so Claude Code uses them with friendly
# display names in the /model picker.
#
# No hardcoded model list — profiles are discovered from Bedrock and matched
# to Claude Code tiers (opus/sonnet/haiku) by inspecting the underlying
# foundation model.
#
# Prerequisites:
#   - AWS CLI v2 with credentials configured (SSO, env vars, instance role, etc.)
#   - jq
#   - Inference profiles already created (see create-bedrock-profiles.sh)
#
# Usage:
#   ./configure-claude-cli.sh --project-id uncertainty_ts
###############################################################################

AWS_REGION="${AWS_REGION:-us-west-2}"
PROJECT_ID=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Configures Claude Code CLI to use tagged Bedrock inference profiles.

Required:
  --project-id ID      wma:project_id to look up profiles for

Optional:
  --region REGION      AWS region (default: us-west-2)

Examples:
  $(basename "$0") --project-id uncertainty_ts
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id)  PROJECT_ID="$2";  shift 2 ;;
    --region)      AWS_REGION="$2";  shift 2 ;;
    -h|--help)     usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [[ -z "$PROJECT_ID" ]]; then
  read -r -p "Project ID (wma:project_id, e.g. uncertainty_ts): " PROJECT_ID  [[ -z "$PROJECT_ID" ]] && { echo "Error: project ID is required." >&2; exit 1; }
fi

for cmd in aws jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is required but not found in PATH." >&2
    exit 1
  fi
done

aws sts get-caller-identity &>/dev/null || {
  echo "Error: no active AWS credentials found." >&2
  echo "Configure credentials via SSO (aws sso login), environment variables," >&2
  echo "a named profile (AWS_PROFILE), or an instance role." >&2
  exit 1
}

echo "Searching for inference profiles matching project '$PROJECT_ID'..."

ALL_PROFILES=$(aws bedrock list-inference-profiles \
  --type-equals APPLICATION \
  --region "$AWS_REGION" \
  --output json)

PROJECT_PROFILES=$(echo "$ALL_PROFILES" | jq -c --arg prefix "$PROJECT_ID" \
  '[.inferenceProfileSummaries[] | select(.inferenceProfileName | startswith($prefix))]')

PROFILE_COUNT=$(echo "$PROJECT_PROFILES" | jq length)
if [ "$PROFILE_COUNT" -eq 0 ]; then
  echo "Error: no inference profiles found for project '$PROJECT_ID'." >&2
  echo "Run create-bedrock-profiles.sh first to create them." >&2
  exit 1
fi
echo "Found $PROFILE_COUNT profile(s)."

TIER_MAP=$(echo "$PROJECT_PROFILES" | jq -c '
  reduce .[] as $p ({};
    ($p.models[0].modelArn | split("/") | last) as $model_id |
    (if   ($model_id | test("opus-4-6"))   then {tier: "OPUS",   name: "Opus 4.6"}
     elif ($model_id | test("opus-4-5"))   then {tier: "OPUS",   name: "Opus 4.5"}
     elif ($model_id | test("opus-4-1"))   then {tier: "OPUS",   name: "Opus 4.1"}
     elif ($model_id | test("opus-4-"))    then {tier: "OPUS",   name: "Opus 4"}
     elif ($model_id | test("opus"))       then {tier: "OPUS",   name: "Opus"}
     elif ($model_id | test("sonnet-4-6")) then {tier: "SONNET", name: "Sonnet 4.6"}
     elif ($model_id | test("sonnet-4-5")) then {tier: "SONNET", name: "Sonnet 4.5"}
     elif ($model_id | test("sonnet-4-"))  then {tier: "SONNET", name: "Sonnet 4"}
     elif ($model_id | test("sonnet-3-7")) then {tier: "SONNET", name: "Sonnet 3.7"}
     elif ($model_id | test("sonnet"))     then {tier: "SONNET", name: "Sonnet"}
     elif ($model_id | test("haiku-4-5"))  then {tier: "HAIKU",  name: "Haiku 4.5"}
     elif ($model_id | test("haiku"))      then {tier: "HAIKU",  name: "Haiku"}
     else null
     end) as $match |
    if $match then
      .[$match.tier] = {arn: $p.inferenceProfileArn, name: $match.name}
    else .
    end
  )
')

MATCHED=$(echo "$TIER_MAP" | jq 'length')
if [ "$MATCHED" -eq 0 ]; then
  echo "Error: no profiles could be mapped to Claude Code tiers." >&2
  exit 1
fi

for TIER in OPUS SONNET HAIKU; do
  ARN=$(echo "$TIER_MAP" | jq -r --arg t "$TIER" '.[$t].arn // empty')
  NAME=$(echo "$TIER_MAP" | jq -r --arg t "$TIER" '.[$t].name // empty')
  if [ -n "$ARN" ]; then
    echo "  ${TIER}  ${NAME} (${PROJECT_ID}) → $ARN"
  fi
done

SETTINGS_FILE="$HOME/.claude/settings.json"
echo ""

if [ ! -f "$SETTINGS_FILE" ]; then
  echo "Creating $SETTINGS_FILE..."
  echo '{}' > "$SETTINGS_FILE"
fi

ENV_JSON=$(echo "$TIER_MAP" | jq -c --arg pid "$PROJECT_ID" '
  {"CLAUDE_CODE_USE_BEDROCK": "1"} +
  (to_entries | reduce .[] as $e ({};
    . + {
      ("ANTHROPIC_DEFAULT_" + $e.key + "_MODEL"): $e.value.arn,
      ("ANTHROPIC_DEFAULT_" + $e.key + "_MODEL_NAME"): ($e.value.name + " (" + $pid + ")"),
      ("ANTHROPIC_DEFAULT_" + $e.key + "_MODEL_DESCRIPTION"): "Bedrock inference profile"
    }
  ))
')

EXISTING_ENV=$(jq -r '.env // {} | keys[]' "$SETTINGS_FILE" 2>/dev/null)
CONFLICTS=""
for KEY in $(echo "$ENV_JSON" | jq -r 'keys[]'); do
  if echo "$EXISTING_ENV" | grep -qx "$KEY"; then
    OLD_VAL=$(jq -r --arg k "$KEY" '.env[$k]' "$SETTINGS_FILE")
    NEW_VAL=$(echo "$ENV_JSON" | jq -r --arg k "$KEY" '.[$k]')
    if [ "$OLD_VAL" != "$NEW_VAL" ]; then
      CONFLICTS="${CONFLICTS}  ${KEY}\n    old: ${OLD_VAL}\n    new: ${NEW_VAL}\n"
    fi
  fi
done

if [ -n "$CONFLICTS" ]; then
  echo "The following env vars in $SETTINGS_FILE will be overwritten:"
  echo ""
  printf "$CONFLICTS"
  echo ""
  read -r -p "Continue? [y/N] " REPLY
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

TEMP_FILE=$(mktemp)
jq --argjson new_env "$ENV_JSON" '.env = ((.env // {}) + $new_env)' "$SETTINGS_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$SETTINGS_FILE"

echo "Updated $SETTINGS_FILE"
echo ""
echo "The /model picker will show:"
for TIER in OPUS SONNET HAIKU; do
  NAME=$(echo "$TIER_MAP" | jq -r --arg t "$TIER" '.[$t].name // empty')
  if [ -n "$NAME" ]; then
    echo "  ${NAME} (${PROJECT_ID})"
  fi
done
echo ""
echo "Restart Claude Code for changes to take effect."
