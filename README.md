# bedrock-profiles

A [Claude Code plugin](https://code.claude.com/docs/en/plugins) that sets up tagged AWS Bedrock inference profiles for cost attribution.

## Prerequisites

- [Claude Code](https://claude.ai/install.sh)
- [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) with a valid SSO session
- [jq](https://jqlang.github.io/jq/download/)

## Install

```
/plugin marketplace add thodson-usgs/bedrock-profiles
/plugin install bedrock-profiles
```

## Usage

```
/bedrock-profiles:setup
```

The skill walks you through the full setup interactively: checks prerequisites, prompts for your project tags, creates Bedrock inference profiles if needed, and writes the configuration to `~/.claude/settings.json`. Restart Claude Code when it finishes.

You can also pass arguments directly:

```
/bedrock-profiles:setup --project-id my_project --app-id claude --contact user@example.com
```

## Advanced: standalone scripts

The same scripts the skill uses can be run directly for automation or CI:

```bash
aws sso login

# 1. Create inference profiles (once per project)
bash skills/setup/create-bedrock-profiles.sh \
    --project-id my_project --app-id claude --contact user@example.com

# 2. Configure Claude Code (each user)
bash skills/setup/configure-claude-cli.sh \
    --project-id my_project
```

Both scripts accept `--region` (default: `us-west-2`). Run either with `--help` for full usage.

## Updating models

Edit the `MODELS` array at the top of `skills/setup/create-bedrock-profiles.sh`, then re-run the skill or both scripts.
