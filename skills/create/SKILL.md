---
name: create
description: Create tagged AWS Bedrock inference profiles for a project with wma cost attribution tags
argument-hint: "[--project-id ID] [--app-id ID] [--contact EMAIL] [--region REGION]"
allowed-tools: Bash("${CLAUDE_SKILL_DIR}/../setup/create-bedrock-profiles.sh":*)
---

```!
"${CLAUDE_SKILL_DIR}/../setup/create-bedrock-profiles.sh" $ARGUMENTS
```
