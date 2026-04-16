---
name: configure
description: Configure Claude Code to use existing Bedrock inference profiles for a project
argument-hint: "[--project-id ID] [--region REGION]"
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

## Configure Claude Code for Bedrock Profiles

Arguments: `$ARGUMENTS`

Parse `$ARGUMENTS` for `--project-id` and `--region` (default: `us-west-2`). If `--project-id` is not provided, ask:
- **project-id**: "What is your project ID? (`wma:project_id` tag, e.g. `uncertainty_ts`)"

Once collected, run:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/configure-claude-cli.sh" --project-id PROJECT_ID --region REGION
```

Report the output. If it fails, show the error and stop.
