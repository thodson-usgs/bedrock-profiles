---
name: create
description: Create tagged AWS Bedrock inference profiles for a project with wma cost attribution tags
argument-hint: "[--project-id ID] [--app-id ID] [--contact EMAIL] [--region REGION]"
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

## Create Bedrock Inference Profiles

Arguments: `$ARGUMENTS`

Parse `$ARGUMENTS` for `--project-id`, `--app-id`, `--contact`, and `--region` (default: `us-west-2`). For any not provided, ask the user:
- **project-id**: "What is your project ID? (`wma:project_id` tag, e.g. `uncertainty_ts`)"
- **app-id**: "What application ID? (`wma:application_id` tag, e.g. `claude`)"
- **contact**: "What contact email? (`wma:contact` tag, e.g. `user@usgs.gov`)"

Once all three are collected, run:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/create-bedrock-profiles.sh" --project-id PROJECT_ID --app-id APP_ID --contact CONTACT --region REGION
```

Report the output. If it fails, show the error and stop.
