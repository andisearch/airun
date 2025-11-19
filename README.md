# Claude Switcher

A collection of scripts to easily switch between different authentication modes and providers for [Claude Code](https://claude.ai/code).

## Features

- **Multiple Providers**: Support for Anthropic API, AWS Bedrock, and Google Vertex AI.
- **Model Switching**: Easily switch between Sonnet 4.5, Opus 4.1, or custom models.
- **Pro Plan Support**: Toggle back to standard Claude Pro web authentication.
- **Session Management**: Unique session IDs for tracking.
- **Secure Configuration**: API keys stored in a separate, git-ignored file.
- **System-Wide Access**: Scripts are installed to `/usr/local/bin` for easy access.

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/andisearch/claude-switcher.git
cd claude-switcher
```

### 2. Run the Setup Script
This script will install the necessary commands to `/usr/local/bin` and create your configuration directory. You may be prompted for your password to allow installation to system directories.

```bash
./setup.sh
```

### 3. Configure Your Secrets
The setup script creates a secrets file at `~/.claude-switcher/secrets.sh`. You must edit this file to add your API keys and credentials.

```bash
nano ~/.claude-switcher/secrets.sh
```

#### Adding API Keys
Uncomment and fill in the sections for the providers you wish to use:

**AWS Bedrock:**
```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_REGION="us-west-2" # Change if your models are in a different region
```

**Google Vertex AI:**
```bash
export GOOGLE_CLOUD_PROJECT="your_project_id"
export GOOGLE_LOCATION="us-central1"
```

**Anthropic API:**
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

#### Overriding Defaults (Optional)
You can override default model IDs or regions in the same `secrets.sh` file. This is useful for testing new models or using custom endpoints.

**Example: Override AWS Region and Model**
```bash
export AWS_REGION="us-east-1"
export CLAUDE_MODEL_SONNET_AWS="us.anthropic.claude-3-5-sonnet-20241022-v2:0"
```

## Switching Providers to Avoid Rate Limits

**This is the killer feature.** Claude Pro has rate limits that reset every 5 hours. When you hit a limit mid-task, instantly switch to your own API and keep working.

### Quick Switch with `--resume`

```bash
# Working with Claude Pro, hit rate limit
claude
# "Rate limit exceeded. Try again in 4 hours 23 minutes."

# Immediately continue with AWS (keeps conversation context)
claude-aws --resume

# Or switch to Haiku for speed/cost
claude-aws --haiku --resume

# Or switch to Opus for complex reasoning
claude-aws --opus --resume

# Or use Vertex AI
claude-vertex --resume
```

The `--resume` flag lets you pick up your last conversation exactly where you left off (or any recent conversation). No lost context, no restarting explanations.

### Common Workflows

**Hit Pro limit mid-debugging:**
```bash
claude-aws --resume  # Continue on your AWS credits
```

**Need faster responses:**
```bash
claude-aws --haiku --resume  # Switch to Haiku for speed
```

**Large codebase analysis:**
```bash
claude-anthropic --opus --resume  # Upgrade to Opus for complex reasoning
```

**Back to Pro when limits reset:**
```bash
claude --resume  # Resume on your default Pro or Max plan
```

### Why This Works

- **Claude Pro**: Great for normal work, but limited (10-40 prompts per 5-hour window)
- **Your API**: Unlimited usage, pay per token. Allows you to use cloud credits.
- **Instant switching**: One command, same conversation
- **No friction**: The only thing stopping you from switching was how annoying it was. Not anymore.


## Usage

Once installed, you can use the following commands from any terminal window.

### AWS Bedrock
```bash
# Use default model (Sonnet 4.5 - latest)
claude-aws

# Use Opus 4.1 (most capable for planning and reasoning)
claude-aws --opus

#Use Haiku 4.5 (fastest, most cost-effective)
claude-aws --haiku

# Use a custom model ID
claude-aws --model "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
```

### Google Vertex AI
```bash
# Use default model (Sonnet 4.5 - latest)
claude-vertex

# Use Opus (most capable for planning and reasoning)
claude-vertex --opus

# Use Haiku (fastest, most cost-effective)
claude-vertex --haiku
```

### Anthropic API
```bash
# Use default model (Sonnet 4.5 - latest)
claude-anthropic

# Use Opus (most capable for planning and reasoning)
claude-anthropic --opus

# Use Haiku (fastest, most cost-effective)
claude-anthropic --haiku
```

### Claude Pro Plan
```bash
# Switch back to standard web auth (default Claude Code behavior)
claude-pro

# OR simply run claude directly
# This works because the switcher scripts only affect the current command execution
claude
```

### Utilities
```bash
# Check your current configuration and environment variables
claude-status

# List active Claude Code sessions
claude-sessions
```

## Configuration

### Models
Default model IDs are defined in `config/models.sh`. The `--sonnet`, `--opus`, and `--haiku` flags automatically use the latest available version of each model tier.

While you can modify `config/models.sh` directly, it is recommended to use `~/.claude-switcher/secrets.sh` for overrides to avoid merge conflicts when updating.

### Updating to New Models
When new Claude models are released:

```bash
cd claude-switcher
git pull
./setup.sh
```

The setup script will update all commands with the latest model definitions while preserving your API keys in `~/.claude-switcher/secrets.sh`.

### Secrets
Credentials are stored in `~/.claude-switcher/secrets.sh`. This file is not committed to the repository and is safe for your private keys.

## License

MIT License. Copyright (c) 2025 Jed White from Andi AI Search.
