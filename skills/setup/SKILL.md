---
name: setup
description: Set up Claude Code with tagged AWS Bedrock inference profiles for cost attribution
argument-hint: "[--project-id ID] [--app-id ID] [--contact EMAIL] [--region REGION]"
allowed-tools: Bash(aws *), Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

## Set Up AWS Bedrock Inference Profiles

Arguments: `$ARGUMENTS`

Run the setup script with all provided arguments. Collect any missing required values first by asking the user, then invoke the script with all values as flags — **do not run the script without all values resolved**.

### Step 1 — Collect inputs

Parse `$ARGUMENTS` for `--project-id`, `--app-id`, `--contact`, and `--region` (default: `us-west-2`).

For any not provided, ask the user before proceeding:
- **project-id**: "What is your project ID? (`wma:project_id` tag, e.g. `uncertainty_ts`)"

Check if profiles already exist before asking for `--app-id` and `--contact` — they're only needed if creating new profiles. First check by running:

```
aws bedrock list-inference-profiles --type-equals APPLICATION --region REGION --output json
```

Filter for names starting with the project ID. If profiles exist, skip to Step 2 with only `--project-id` and `--region`. If none exist, also ask:
- **app-id**: "What application ID? (`wma:application_id` tag, e.g. `claude`)"
- **contact**: "What contact email? (`wma:contact` tag, e.g. `user@usgs.gov`)"

### Step 2 — Run the script

Once all needed values are collected, run:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh" --project-id PROJECT_ID --region REGION [--app-id APP_ID --contact CONTACT]
```

Report the output. If it fails, show the error and stop.
