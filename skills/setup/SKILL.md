---
name: setup
description: Set up Claude Code with tagged AWS Bedrock inference profiles for cost attribution
argument-hint: "[--project-id ID] [--app-id ID] [--contact EMAIL] [--region REGION]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh:*)"]
---

```!
bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh" $ARGUMENTS
```
