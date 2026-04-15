---
name: create
description: Create tagged AWS Bedrock inference profiles for a project. Run once per project by someone with Bedrock write access. Prompts for project tags interactively if not passed as arguments.
argument-hint: "[--project-id ID] [--app-id ID] [--contact EMAIL] [--region REGION]"
allowed-tools: Bash("${CLAUDE_SKILL_DIR}/../setup/create-bedrock-profiles.sh":*)
---

```!
"${CLAUDE_SKILL_DIR}/../setup/create-bedrock-profiles.sh" $ARGUMENTS
```
