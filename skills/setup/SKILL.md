---
name: setup
description: Set up Claude Code with tagged AWS Bedrock inference profiles for cost attribution
argument-hint: "[--project-id ID] [--app-id ID] [--contact EMAIL] [--region REGION]"
allowed-tools: Bash("${CLAUDE_SKILL_DIR}/setup.sh":*)
---

```!
"${CLAUDE_SKILL_DIR}/setup.sh" $ARGUMENTS
```
