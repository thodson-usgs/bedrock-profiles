# bedrock-profiles

A [Claude Code plugin](https://code.claude.com/docs/en/plugins) that sets up tagged AWS Bedrock inference profiles for cost attribution.

Inference profiles let you attach `wma:project_id`, `wma:application_id`, and `wma:contact` tags to every Claude API call so usage shows up in your AWS Cost Explorer by project.

## Prerequisites

### Claude Code

```bash
# macOS / Linux
curl -fsSL https://claude.ai/install.sh | bash
```

```powershell
# Windows
winget install Anthropic.ClaudeCode
```

### AWS CLI v2 and jq

**macOS (Homebrew)**
```bash
brew install awscli jq
```

**Ubuntu / Debian**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip -qo awscliv2.zip && sudo ./aws/install --update && rm -rf awscliv2.zip aws
sudo apt-get install -y jq
```

**Windows**
```powershell
winget install Amazon.AWSCLI jqlang.jq
```

### AWS credentials

The scripts call Bedrock and STS — any valid credential method works:

- **SSO (recommended):** `aws sso login`
- **Environment variables:** `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`
- **Named profile:** `AWS_PROFILE=my-profile`
- **Instance role / ECS task role:** no extra steps needed

Verify your session is active before running the skill:
```bash
aws sts get-caller-identity
```

## Install the plugin

```
/plugin marketplace add thodson-usgs/bedrock-profiles
/plugin install bedrock-profiles
```

## Usage

### All-in-one setup

The `setup` skill handles everything: checks prerequisites, prompts for your project tags, creates profiles if they don't exist, and writes configuration to `~/.claude/settings.json`.

```
/bedrock-profiles:setup
```

Pass arguments to skip the prompts:

```
/bedrock-profiles:setup --project-id my_project --app-id claude --contact user@example.com
```

Restart Claude Code when it finishes. The `/model` picker will show entries like **Opus 4.6 (my_project)**.

---

### Separate create and configure steps

If you prefer more control — or if an admin creates profiles once and developers configure their own CLI — the two steps can be run independently.

**Step 1 — Create profiles** (run once per project, typically by an admin with write access to Bedrock):

```
/bedrock-profiles:create --project-id my_project --app-id claude --contact user@example.com
```

**Step 2 — Configure Claude Code** (run by each developer):

```
/bedrock-profiles:configure --project-id my_project
```

`configure` only needs read access to Bedrock (`bedrock:ListInferenceProfiles`) and write access to `~/.claude/settings.json` — no profile creation permissions required.

---

## Standalone scripts

The same scripts the skills use can be run directly for automation or CI:

```bash
# Create inference profiles (once per project)
bash skills/setup/create-bedrock-profiles.sh \
    --project-id my_project --app-id claude --contact user@example.com

# Configure Claude Code (each developer)
bash skills/setup/configure-claude-cli.sh \
    --project-id my_project
```

Both accept `--region` (default: `us-west-2`). Run with `--help` for full usage.

## Updating models

Edit the `MODELS` array at the top of `skills/setup/create-bedrock-profiles.sh`, then re-run the skill or scripts.
