# Claude Switcher

[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub-pink?logo=github&style=for-the-badge)](https://github.com/sponsors/andisearch)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support-yellow?logo=buy-me-a-coffee&style=for-the-badge)](https://buymeacoffee.com/andisearch)
[![PayPal](https://img.shields.io/badge/PayPal-Donate-blue?logo=paypal&style=for-the-badge)](https://www.paypal.me/lazywebai)
[![GitHub Stars](https://img.shields.io/github/stars/andisearch/claude-switcher?style=for-the-badge&logo=github)](https://github.com/andisearch/claude-switcher/stargazers)

A collection of scripts to easily switch between different authentication modes and model providers for [Claude Code](https://claude.ai/code).

Never get blocked by rate limits again! Jump between your Claude Pro/Max subscription and API keys from Anthropic, AWS, Google Cloud and now Microsoft Azure. Switch providers on the fly and pick up where you left off.

Startups: Get the most from your Claude subscription PLUS use your free Cloud Credits.

Claude Switcher is brought to you by the team from [Andi AI](https://andisearch.com).

> [!TIP]
> **Love this project?** ⭐ **[Star this repo](https://github.com/andisearch/claude-switcher)** to show your support and help others discover it! If Claude Switcher saves you money and time, consider [buying us a coffee](https://buymeacoffee.com/andisearch) or [sponsoring on GitHub](https://github.com/sponsors/andisearch). Every contribution helps!

## Quick Start

**Prerequisites**: [Claude Code](https://claude.ai/code) installed

1. **Clone and run setup:**
   ```bash
   git clone https://github.com/andisearch/claude-switcher.git
   cd claude-switcher
   ./setup.sh
   ```

2. **Configure your API keys:**
   ```bash
   nano ~/.claude-switcher/secrets.sh
   ```
   
   **Minimal example** (supports all four providers):
   ```bash
   # AWS Profile
   export AWS_PROFILE="my-aws-profile"
   export AWS_REGION="us-west-2"
   
   # Google Vertex AI Credentials
   export ANTHROPIC_VERTEX_PROJECT_ID="my-ai-project"
   export CLOUD_ML_REGION="global"
   
   # Anthropic API Key
   export ANTHROPIC_API_KEY="sk-ant-..."
   
   # Microsoft Foundry on Azure Credentials
   export ANTHROPIC_FOUNDRY_API_KEY="my-azure-foundry-project-api-key"
   export ANTHROPIC_FOUNDRY_RESOURCE="my-azure-foundry-resource-name"
   ```

3. **Start switching between providers:**
   ```bash
   claude-aws          # Use AWS Bedrock
   claude-vertex       # Use Google Vertex AI
   claude-apikey       # Use Anthropic API
   claude-azure        # Use Microsoft Azure
   
   # Continue your last conversation on any provider
   claude-aws --resume
   claude-vertex --resume
   ```

That's it! See below for detailed configuration options and advanced features.

## Features

- **Multiple Providers**: Support for Anthropic API, AWS Bedrock, Google Vertex AI, and Microsoft Foundry on Azure.
- **Model Switching**: Easily switch between Sonnet 4.5, Opus 4.1, Haiku 4.5, or custom models.
- **Pro Plan Support**: Toggle back to standard Claude Pro or Max subscriptions with native web authentication.
- **Seamless Switching**: Switch between providers and authentication methods without logout flows.
- **Session Management**: Unique session IDs for tracking.
- **Secure Configuration**: API keys stored in a separate, git-ignored file.
- **System-Wide Access**: Scripts are installed to `/usr/local/bin` for easy access.

## How It Works

Claude Switcher uses two complementary approaches for provider switching, **both session-scoped and non-destructive**:

### API Key Helper (Anthropic API ↔ Pro/Max)

For switching between **Claude Pro/Max subscription** and **Anthropic native API key**, claude-switcher uses Claude Code's `apiKeyHelper` setting with **automatic state preservation**:

1. **Session start**: `claude-apikey` saves your existing apiKeyHelper configuration (if any), then adds its own
2. **Mode tracking** in `~/.claude-switcher/current-mode.sh` stores the current provider (`pro` or `anthropic`)
3. **Dynamic authentication**: The helper script reads `ANTHROPIC_API_KEY` from `secrets.sh` and returns it to Claude
4. **No env variable exposure**: `ANTHROPIC_API_KEY` is NOT exported to the Claude CLI process, preventing auth conflicts
5. **Session end**: Restore trap automatically restores your original apiKeyHelper configuration
6. **Plain `claude` unaffected**: Always works exactly as before installation

**Similarly for Pro mode**: `claude-pro` temporarily removes apiKeyHelper for the session, then restores it on exit.

**Key benefits**:
- ✅ **Non-destructive**: Preserves your existing apiKeyHelper if you have one
- ✅ **Session-scoped**: Like AWS/Vertex/Azure, changes only affect the wrapper script session  
- ✅ **Auto-cleanup**: Plain `claude` always runs in native state after any script exits
- ✅ **Multi-session safe**: Each session has independent state tracking
- ✅ **No auth conflicts**: Only one authentication method visible to Claude CLI
### Environment Variables (AWS, Vertex AI, Azure)

For **AWS Bedrock**, **Google Vertex AI**, and **Microsoft Foundry on Azure**, switching is even simpler:

- Each provider has a dedicated environment variable (`CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`, `CLAUDE_CODE_USE_FOUNDRY`)
- Setting these automatically disables `/login` and `/logout` commands
- No apiKeyHelper needed—Claude Code natively supports these providers
- Scripts just set the appropriate environment variables and launch Claude Code

**Result**: Seamless switching between any provider without logout flows, browser prompts, or authentication friction.

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/andisearch/claude-switcher.git
cd claude-switcher
```

### 2. Run the Setup Script
This script will:
- Install commands to `/usr/local/bin` for system-wide access
- Create your configuration directory at `~/.claude-switcher/`
- Install the API key helper script (but NOT activate it yet)
- **Does NOT modify** your existing `~/.claude/settings.json`

You may be prompted for your password to allow installation to system directories.

```bash
./setup.sh
```

> **Important**: Setup does NOT modify your Claude configuration. The switcher scripts are **session-scoped**:
> - Running `claude-apikey` or `claude-pro` only affects THAT session
> - On exit, your original apiKeyHelper configuration is automatically restored
> - Plain `claude` always runs in its native, unmodified state
> - Safe even if you already have a custom apiKeyHelper configured

## Uninstallation

To completely remove claude-switcher from your system:

```bash
cd claude-switcher
./uninstall.sh
```

The uninstall script will:
- Remove all installed command scripts from `/usr/local/bin`
- Ask before removing your configuration directory (contains API keys)
- Clean up any references to apiKeyHelper in settings.json (if applicable)
- Preserve your `~/.claude/settings.json` and any backups

**Safe and non-destructive**: The script asks for confirmation before removing any user data.

### 3. Configure Your Secrets
The setup script creates a secrets file at `~/.claude-switcher/secrets.sh`. You must edit this file to add your API keys and credentials.

```bash
nano ~/.claude-switcher/secrets.sh
```

#### Adding API Keys
Uncomment and fill in the sections for the providers you wish to use:

**AWS Bedrock:**

Multiple authentication methods supported (see [official docs](https://code.claude.com/docs/en/amazon-bedrock)):

```bash
# Option 1: AWS Bedrock API Key (recommended for simplicity)
export AWS_BEARER_TOKEN_BEDROCK="your-bedrock-api-key"
export AWS_REGION="us-west-2"

# Option 2: AWS Access Keys
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-west-2"

# Option 3: AWS Profile
export AWS_PROFILE="your-profile-name"
export AWS_REGION="us-west-2"
```
> **Note**: `AWS_REGION` is required for all auth methods. Scripts validate authentication is configured before launching.

**Google Vertex AI:**

**Authentication Methods** (checked in this precedence order):

1. **Service Account Key File** (highest precedence) - Recommended for production/CI
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
   ```

2. **Application Default Credentials** - Recommended for local development
   ```bash
   gcloud auth application-default login
   ```

3. **gcloud User Credentials** (lowest precedence) - Fallback method
   ```bash
   gcloud auth login
   ```

The `claude-vertex` script automatically detects which method is available and uses the highest precedence one.

**Setup Steps:**
1. **Install Google Cloud SDK**: [Download here](https://cloud.google.com/sdk/docs/install)
2. **Authenticate** using one of the methods above
3. **Enable Vertex AI API**: [Click to enable](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com)
4. **Enable Claude Models**: [Open Model Garden](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4) and click "Enable" on models you want to use
5. **Configure secrets.sh**:
   ```bash
   export ANTHROPIC_VERTEX_PROJECT_ID="your-gcp-project-id"
   export CLOUD_ML_REGION="global"
   ```

> **Optional**: Set specific regions per model (defaults to `CLOUD_ML_REGION`):
> ```bash
> export VERTEX_REGION_CLAUDE_4_5_SONNET="us-east5"
> export VERTEX_REGION_CLAUDE_4_1_OPUS="global"
> ```
>
> **Note**: Models are region-specific. Check [availability](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden) in your region.

**Anthropic API:**

> **Note**: When using `claude-apikey`, your API key is validated but NOT exported as an environment variable to avoid authentication conflicts. The `apiKeyHelper` script reads the key directly from `secrets.sh` and provides it to Claude CLI as a token. This ensures only one authentication method is active.

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

**Microsoft Foundry on Azure:**

Announced November 18, 2024 ([blog post](https://www.anthropic.com/news/claude-in-microsoft-foundry)).

**Setup Steps:**
1. **Create Azure Resource**: Navigate to [Microsoft Foundry portal](https://ai.azure.com/)
2. **Deploy Models**: Create deployments for Claude Opus, Sonnet, and/or Haiku
3. **Get Credentials**: From your resource's "Endpoints and keys" section
4. **Configure secrets.sh**:
   ```bash
   # Option 1: API Key (simpler)
   export ANTHROPIC_FOUNDRY_API_KEY="your-azure-api-key"
   export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
   
   # Option 2: Azure CLI (az login)
   export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
   # Then run: az login
   
   # Set your deployment names (must match what you created in Azure)
   export CLAUDE_MODEL_SONNET_AZURE="claude-sonnet-4-5"
   export CLAUDE_MODEL_HAIKU_AZURE="claude-haiku-4-5"
   export CLAUDE_MODEL_OPUS_AZURE="claude-opus-4-1"
   ```

> **Note**: Model names in Azure are your custom deployment names, not the standard model IDs.

#### Overriding Defaults (Optional)
You can override default model IDs or regions in the same `secrets.sh` file. This is useful for testing new models or using custom endpoints.

**Example: Override AWS Region and Model**
```bash
export AWS_REGION="us-east-1"
export CLAUDE_MODEL_SONNET_AWS="global.anthropic.claude-sonnet-4-5-20250929-v1:0"
```

## Switching Providers to Avoid Rate Limits

**This is the killer feature.** Claude Pro has daily rate limits that reset every 5 hours, and weekly limits that reset every 7 days. When you hit a limit mid-task, instantly switch to your own API keys and keep working.

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
claude-apikey --opus --resume  # Upgrade to Opus for complex reasoning
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
claude-aws --model "global.anthropic.claude-sonnet-4-5-20250929-v1:0"
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
claude-apikey

# Use Opus (most capable for planning and reasoning)
claude-apikey --opus

# Use Haiku (fastest, most cost-effective)
claude-apikey --haiku
```

### Microsoft Foundry on Azure
```bash
# Use default model (Sonnet deployment)
claude-azure

# Use Opus deployment
claude-azure --opus

# Use Haiku deployment
claude-azure --haiku

# Use custom deployment name
claude-azure --model "my-custom-deployment"
```

### Claude Pro Plan
```bash
# Force Pro/Max subscription for this session (removes any apiKeyHelper)
claude-pro

# OR simply run claude directly
# Uses your native state (respects any existing apiKeyHelper you have)
claude
```

**Key difference**: 
- `claude-pro`: Explicitly removes apiKeyHelper for the session to ensure Pro/Max subscription is used, then restores your original config on exit
- `claude`: Always uses your native, unmodified configuration

### Utilities

#### `claude-status`
Shows your current Claude Code authentication configuration with mode-specific details:

```bash
claude-status
```

**Detects and displays:**
- **AWS Bedrock**: Shows region, API token status, model settings, and output token limits
- **Vertex AI**: Shows GCP project, location, authentication status, and active gcloud account
- **Anthropic API**: Shows API key status and model configuration
- **Claude Pro**: Shows when using default web authentication

**Example output (Anthropic API mode):**
```
[Claude Switcher] Current mode: Anthropic API

[Claude Switcher] Anthropic API Configuration:
[Claude Switcher]   CLAUDE_CODE_USE_BEDROCK: 0
[Claude Switcher]   ANTHROPIC_API_KEY: set (hidden)
[Claude Switcher]   ANTHROPIC_MODEL: claude-sonnet-4-5-20250929

[Claude Switcher] Features:
  - API authentication via Anthropic API
  - Login/logout disabled
  - Direct access to Anthropic models
```

#### `claude-sessions`
Lists all active Claude Code sessions with detailed tracking information:

```bash
claude-sessions
```

**Shows:**
- Process ID (PID)
- Provider (AWS Bedrock, Vertex AI, Anthropic API, Claude Pro)
- Model name
- Region (AWS) or Project (Vertex AI)
- Session ID (abbreviated)
- Uptime

**Example output:**
```
[Claude Switcher] Active Claude Code Sessions:

PID      Provider        Model                                    Region/Project   Session ID      Uptime
----     --------        -----                                    --------------   ----------      ------
12345    AWS Bedrock     claude-sonnet-4-5-20250929-v1:0          us-west-2        1234567890      2h15m
67890    Vertex AI       claude-sonnet-4-5@20250929               my-gcp-project   2345678901      45m30s
```

> **Note**: Session tracking is file-based with automatic stale session cleanup. Only actual running Claude processes are shown.

## Configuration

### Models
Default model IDs are defined in `config/models.sh`. The `--sonnet`, `--opus`, and `--haiku` flags automatically use the latest available version of each model tier.

While you can modify `config/models.sh` directly, it is recommended to use `~/.claude-switcher/secrets.sh` for overrides to avoid merge conflicts when updating.

#### Variable Naming
The scripts use provider-specific model variables that can be customized in `secrets.sh`:

```bash
# AWS Bedrock
export CLAUDE_MODEL_SONNET_AWS="global.anthropic.claude-sonnet-4-5-20250929-v1:0"
export CLAUDE_MODEL_OPUS_AWS="us.anthropic.claude-opus-4-1-20250805-v1:0"
export CLAUDE_MODEL_HAIKU_AWS="us.anthropic.claude-haiku-4-5-20251001-v1:0"
export CLAUDE_SMALL_FAST_MODEL_AWS="us.anthropic.claude-haiku-4-5-20251001-v1:0"

# Google Vertex AI
export CLAUDE_MODEL_SONNET_VERTEX="claude-sonnet-4-5@20250929"
export CLAUDE_MODEL_OPUS_VERTEX="claude-opus-4-1@20250805"
export CLAUDE_MODEL_HAIKU_VERTEX="claude-haiku-4-5@20251001"
export CLAUDE_SMALL_FAST_MODEL_VERTEX="claude-haiku-4-5@20251001"

# Anthropic API
export CLAUDE_MODEL_SONNET_ANTHROPIC="claude-sonnet-4-5-20250929"
export CLAUDE_MODEL_OPUS_ANTHROPIC="claude-opus-4-1-20250805"
export CLAUDE_MODEL_HAIKU_ANTHROPIC="claude-haiku-4-5"
export CLAUDE_SMALL_FAST_MODEL_ANTHROPIC="claude-haiku-4-5"

# Microsoft Foundry/Azure (deployment names)
export CLAUDE_MODEL_SONNET_AZURE="claude-sonnet-4-5"
export CLAUDE_MODEL_OPUS_AZURE="claude-opus-4-1"
export CLAUDE_MODEL_HAIKU_AZURE="claude-haiku-4-5"
export CLAUDE_SMALL_FAST_MODEL_AZURE="claude-haiku-4-5"
```

These variables are used by the scripts to set `ANTHROPIC_MODEL` and `ANTHROPIC_SMALL_FAST_MODEL` at runtime based on which provider you're using.

### Model Configuration: Main + Small/Fast Models

Claude Code uses **two models** for optimal performance and cost efficiency:

1. **`ANTHROPIC_MODEL`** - Your main model for interactive work
   - Used for conversation, reasoning, and complex tasks
   - Set via `--sonnet`, `--opus`, `--haiku` flags or `--model` override
   - Examples: Sonnet 4.5, Opus 4.1, Haiku 4.5

2. **`ANTHROPIC_SMALL_FAST_MODEL`** - Background operations model  
   - Used for sub-agents, file operations, and auxiliary tasks
   - **Defaults to Haiku** for each provider
   - Reduces costs for background work
   - See [Claude Code docs](https://code.claude.com/docs/en/model-config#environment-variables)

**How It Works:**

Both models follow the **same configuration pattern**:

- **Defaults** in `config/models.sh`:
  ```bash
  export CLAUDE_SMALL_FAST_MODEL_AWS="${CLAUDE_SMALL_FAST_MODEL_AWS:-${CLAUDE_MODEL_HAIKU_AWS}}"
  export CLAUDE_SMALL_FAST_MODEL_VERTEX="${CLAUDE_SMALL_FAST_MODEL_VERTEX:-${CLAUDE_MODEL_HAIKU_VERTEX}}"
  ```

- **Overrides** in `~/.claude-switcher/secrets.sh`:
  ```bash
  # Use a custom small/fast model for AWS
  export CLAUDE_SMALL_FAST_MODEL_AWS="us.anthropic.claude-3-5-haiku-20241022-v1:0"
  ```

- **Runtime**: Scripts set `ANTHROPIC_SMALL_FAST_MODEL` from the appropriate provider variable

**Example:**
```bash
claude-aws --opus
# Sets: ANTHROPIC_MODEL = Opus 4.1 (your choice)
#       ANTHROPIC_SMALL_FAST_MODEL = Haiku 4.5 (auto, from CLAUDE_SMALL_FAST_MODEL_AWS)
```

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

## Troubleshooting

### Verify apiKeyHelper Setup

Check if the API key helper is properly configured:

```bash
claude-status
```

This will show:
- Whether `settings.json` has `apiKeyHelper` configured
- Whether the helper script exists and is executable
- Your current switcher mode (`pro`, `anthropic`, etc.)

### Check Current Mode

View your current mode (if a switcher script is running):

```bash
cat ~/.claude-switcher/current-mode.sh
```

Should show something like:
```bash
export CLAUDE_SWITCHER_MODE="pro"
# or
export CLAUDE_SWITCHER_MODE="anthropic"
```

### Session-Scoped Behavior

**Important**: All wrapper scripts are session-scoped:
- Changes only affect the active Claude session
- On exit, original settings are automatically restored
- Plain `claude` always runs in native state

To verify native state:
```bash
# Exit any active claude-apikey or claude-pro session
# Then check settings
cat ~/.claude/settings.json
# Should show your original apiKeyHelper (or no apiKeyHelper if you never had one)
```

### Manually Reset (Emergency Only)

If something goes wrong and you need to reset:

```bash
# Remove state files
rm -f ~/.claude-switcher/apiKeyHelper-state-*.tmp

# Check your settings
cat ~/.claude/settings.json

# If apiKeyHelper points to our script when it shouldn't:
# Restore from backup
ls ~/.claude/settings.json.backup-*
cp ~/.claude/settings.json.backup-YYYYMMDD-HHMMSS ~/.claude/settings.json
```

### Test apiKeyHelper Directly

Verify the helper script works:

```bash
# Test in Pro mode (should output nothing)
echo 'export CLAUDE_SWITCHER_MODE="pro"' > ~/.claude-switcher/current-mode.sh
~/.claude-switcher/claude-api-key-helper.sh

# Test in Anthropic mode (should output your API key)
echo 'export CLAUDE_SWITCHER_MODE="anthropic"' > ~/.claude-switcher/current-mode.sh 
~/.claude-switcher/claude-api-key-helper.sh
```

### Still Getting Rate Limits After Switching?

If you switch from Pro to `claude-apikey` but still see Pro plan rate limits:

1. Verify API key is set: `grep ANTHROPIC_API_KEY ~/.claude-switcher/secrets.sh`
2. Check you're using the wrapper: Make sure you ran `claude-apikey` (not plain `claude`)
3. Run `claude-status` during the session to verify configuration
4. In the Claude session, run `/status` to see authentication method

**Remember**: The wrapper only affects the current session. Each time you want Anthropic API, run `claude-apikey`.

### Switching Back to Pro Not Working?

If web authentication doesn't activate after running `claude-pro`:

1. Make sure you're running `claude-pro` (creates new session)
2. OR just use plain `claude` (always native state)
3. In Claude session, run `/status` to verify authentication method

**Remember**: After exiting ANY wrapper script, plain `claude` returns to native state automatically.

## Versioning

**Current Version**: `1.0.4` (see [VERSION](VERSION) or run `claude-apikey --version`)

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). See [CHANGELOG.md](CHANGELOG.md) for version history.

**Creating a Release** (maintainers):
```bash
# 1. Update VERSION and CHANGELOG.md
# 2. Commit and tag
git add VERSION CHANGELOG.md
git commit -m "Bump version to x.y.z"
git tag -a vx.y.z -m "Release vx.y.z: Description"
git push origin main && git push origin vx.y.z
```

## Support This Project

**Claude Switcher is free and open source**, built with ❤️ to help developers be more productive and save money with Claude Code.

If you find this tool valuable, here's how you can support its development:

### ⭐ Star This Repo
The simplest way to show your support is to **[give us a star on GitHub](https://github.com/andisearch/claude-switcher)**! It helps others discover the project.

[![GitHub Stars](https://img.shields.io/github/stars/andisearch/claude-switcher?style=social)](https://github.com/andisearch/claude-switcher/stargazers)

### 💖 Donate
Your financial support not only helps us to maintain this project but also to build Andi AI search and keep it free. These scripts help us save a lot of time and money, and we hope they'll help you too!

**Choose your preferred platform:**

- 🩷 **[GitHub Sponsors](https://github.com/sponsors/andisearch)** - Recurring or one-time support
- ☕ **[Buy Me a Coffee](https://buymeacoffee.com/andisearch)** - Quick one-time donation
- 💙 **[PayPal](https://www.paypal.me/lazywebai)** - Direct donation via PayPal

> Every contribution, no matter the size, makes a real difference. Thank you for considering supporting our work! 🙏

### 🤝 Other Ways to Help
- **Share**: Tell your colleagues and friends about Claude Switcher
- **Contribute**: Submit bug reports, feature requests, or pull requests
- **Feedback**: Let us know how you're using Claude Switcher and how we can improve it

## Acknowledgments

Thanks to the team at Anthropic for creating the awesome Claude Code, the fantastic Sonnet, Opus and Haiku models, and for their open source tools. Their efforts to support the open source community, and to make their models available across cloud providers are greatly appreciated.

We are not associated with Anthropic in any way, other than being big fans of Claude Code.

Huge thanks also to the Startups teams at Microsoft Azure, AWS and Google Cloud for their generous support of Andi and startups in general. 

And very special thanks to Britton Winterrose and Ryan Merket at Microsoft for going above and beyond to help keep Andi running! Without their support this project would not be possible.

## Authors

**Claude Switcher** is created and maintained by:
- **Jed White**, CTO of [Andi](https://andisearch.com)
- **Angela Hoover**, CEO of [Andi](https://andisearch.com)

Contributions welcome. See [CONTRIBUTORS.md](CONTRIBUTORS.md) for a full list of contributors.

## License

MIT License. Copyright (c) 2025 LazyWeb Inc DBA Andi (https://andisearch.com).

See [LICENSE](LICENSE) for full license text.
