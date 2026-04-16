---
name: configure
description: Configure Claude Code to use existing Bedrock inference profiles for a project
argument-hint: "[--project-id ID] [--region REGION]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/configure-claude-cli.sh:*)"]
---

```!
bash "${CLAUDE_PLUGIN_ROOT}/scripts/configure-claude-cli.sh" $ARGUMENTS
```
