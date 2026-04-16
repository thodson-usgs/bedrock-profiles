# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Purpose

This repo is a Claude Code plugin (`bedrock-profiles`) that sets up tagged AWS Bedrock inference profiles for cost attribution. Users install it via `/plugin marketplace add`, then run `/bedrock-profiles:setup` to interactively create profiles and configure their CLI.

## Architecture

This is a single-plugin marketplace. The plugin structure:

```
.claude-plugin/
  plugin.json            # plugin manifest (name, version, etc.)
  marketplace.json       # marketplace catalog listing this plugin
scripts/
  setup.sh               # all-in-one wrapper: discover/create profiles, then configure
  create-bedrock-profiles.sh
  configure-claude-cli.sh
skills/
  setup/SKILL.md         # fires scripts/setup.sh
  create/SKILL.md        # fires scripts/create-bedrock-profiles.sh
  configure/SKILL.md     # fires scripts/configure-claude-cli.sh
```

- **`setup.sh`** is the all-in-one entry point: runs preflight checks, prompts for project ID, discovers existing profiles, creates them if absent (delegating to `create-bedrock-profiles.sh`), then runs `configure-claude-cli.sh`.
- **`create-bedrock-profiles.sh`** creates tagged Bedrock application inference profiles. Idempotent (skips existing). Maintains the canonical model list in the `MODELS` array at the top.
- **`configure-claude-cli.sh`** discovers profiles by project ID, maps them to Claude Code tiers (opus/sonnet/haiku) via regex on the foundation model ID, and writes env vars to `~/.claude/settings.json`. Prompts for confirmation before overwriting existing env vars.

All three scripts follow the same structure: argument parsing, interactive prompts for missing args, preflight checks (`aws`, `jq`), AWS API calls, and output. There is no shared code between them — each is independently runnable.

**Key design decisions:**
- SKILL.md files use `${CLAUDE_PLUGIN_ROOT}` and the `Bash(path:*)` allowed-tools pattern so the skill fires the script directly with no Claude reasoning.
- `configure-claude-cli.sh` has no hardcoded model list; it dynamically discovers profiles from Bedrock.
- Tags use `wma:` prefix (`wma:project_id`, `wma:application_id`, `wma:contact`) for cost attribution.
- Profile naming convention: `{project_id}-{app_id}-{model_slug}` where the slug is derived from the system profile ID with `us.anthropic.` stripped and `.:` replaced with `-`.
- Neither script clobbers existing state: `create-bedrock-profiles.sh` skips profiles that already exist, and `configure-claude-cli.sh` warns before overwriting env vars.

## Prerequisites

- AWS CLI v2 with credentials configured (SSO, env vars, named profile, or instance role)
- `jq`

## Running

```bash
# Install the plugin
/plugin marketplace add thodson-usgs/bedrock-profiles
/plugin install bedrock-profiles

# Run the skill
/bedrock-profiles:setup

# Or with arguments
/bedrock-profiles:setup --project-id my_project --app-id claude --contact user@example.com
```

Scripts can also be run standalone:
```bash
bash scripts/create-bedrock-profiles.sh --help
bash scripts/configure-claude-cli.sh --help
```

Both accept `--region` (default: `us-west-2`).

## Updating models

Edit the `MODELS` array at the top of `scripts/create-bedrock-profiles.sh`, then re-run the skill or scripts.

## Testing

No test suite exists. To verify changes, test against a real AWS account with valid credentials. Check idempotency by running `create-bedrock-profiles.sh` twice — the second run should show `SKIP` for all profiles.
