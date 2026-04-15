---
name: setup
description: Set up Claude Code with tagged AWS Bedrock inference profiles for cost attribution. Creates profiles if needed, then configures ~/.claude/settings.json.
argument-hint: "[--project-id ID] [--app-id ID] [--contact EMAIL] [--region REGION]"
disable-model-invocation: true
allowed-tools: Bash(aws *) Bash(bash *) Bash(command -v *) Bash(jq *) Read Write
---

## Set Up AWS Bedrock Inference Profiles

You are helping the user set up Claude Code with tagged AWS Bedrock inference profiles.

**Arguments:** `$ARGUMENTS` — optional flags: `--project-id ID`, `--app-id ID`, `--contact EMAIL`, `--region REGION`

Follow these steps in order. If any step fails, explain the problem clearly and stop.

### Step 1 — Preflight checks

Check that `aws` and `jq` are installed using `command -v`. If either is missing, tell the user how to install it (brew on macOS, apt on Ubuntu, winget on Windows) and stop.

Then run `aws sts get-caller-identity` to confirm an active AWS session. If it fails, tell the user to run `aws sso login` and stop.

### Step 2 — Gather project ID

Parse `$ARGUMENTS` for `--project-id`. If not provided, ask the user:

> What is your project ID? This is the `wma:project_id` tag used for cost attribution (e.g., `uncertainty_ts`).

Also parse `--region` from arguments. Default to `us-west-2` if not provided.

### Step 3 — Discover existing profiles

Run:

```bash
aws bedrock list-inference-profiles --type-equals APPLICATION --region REGION --output json
```

Filter the results for profiles whose `inferenceProfileName` starts with the project ID. Report how many were found.

### Step 4 — Create or connect

**If profiles were found:** Tell the user you found existing profiles and will configure Claude Code to use them. Skip to Step 5.

**If no profiles were found:** Tell the user no profiles exist yet and you will create them. Parse `--app-id` and `--contact` from `$ARGUMENTS`. For any not provided, ask the user:

- **app-id**: "What application ID should be used? (`wma:application_id` tag, e.g., `claude`)"
- **contact**: "What contact email should be used? (`wma:contact` tag, e.g., `user@usgs.gov`)"

Then run the create script:

```bash
bash "${CLAUDE_SKILL_DIR}/create-bedrock-profiles.sh" \
    --project-id PROJECT_ID \
    --app-id APP_ID \
    --contact CONTACT \
    --region REGION
```

Report the results. If it fails, show the error and stop.

### Step 5 — Configure Claude Code

Run the configure script:

```bash
bash "${CLAUDE_SKILL_DIR}/configure-claude-cli.sh" \
    --project-id PROJECT_ID \
    --region REGION
```

Report what was written to `~/.claude/settings.json`.

### Step 6 — Summary

Tell the user:
- Which profiles are now configured
- That the `/model` picker will show friendly names like "Opus 4.6 (project_id)"
- That they need to **restart Claude Code** for changes to take effect
