---
name: configure
description: Configure Claude Code to use existing Bedrock inference profiles for a project. Discovers profiles by project ID and writes env vars to ~/.claude/settings.json. Only requires Bedrock read access.
argument-hint: "[--project-id ID] [--region REGION]"
allowed-tools: Bash("${CLAUDE_SKILL_DIR}/../setup/configure-claude-cli.sh":*)
---

```!
"${CLAUDE_SKILL_DIR}/../setup/configure-claude-cli.sh" $ARGUMENTS
```
