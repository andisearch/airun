# Claude Code Switcher

[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub-pink?logo=github&style=for-the-badge)](https://github.com/sponsors/andisearch)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support-yellow?logo=buy-me-a-coffee&style=for-the-badge)](https://buymeacoffee.com/andisearch)
[![PayPal](https://img.shields.io/badge/PayPal-Donate-blue?logo=paypal&style=for-the-badge)](https://www.paypal.me/lazywebai)
[![GitHub Stars](https://img.shields.io/github/stars/andisearch/claude-switcher?style=for-the-badge&logo=github)](https://github.com/andisearch/claude-switcher/stargazers)

A collection of scripts to easily switch between different authentication modes and model providers for [Claude Code](https://claude.ai/code).

Never get blocked by rate limits again! Jump between your Claude Pro/Max subscription and API keys from Anthropic, AWS, Google Cloud and now Microsoft Azure. Now includes Vercel AI Gateway support! Switch providers on the fly and pick up where you left off.

Startups: Get the most from your Claude subscription PLUS use your free Cloud Credits.

Claude Pro users: Easily switch to Opus 4.5 on any provider when you need its power, without the need for a Max Subscription ($200/mo).

Claude Switcher is brought to you by the team from [Andi AI](https://andisearch.com).

> [!TIP]
> **Love this project?** ⭐ **[Star this repo](https://github.com/andisearch/claude-switcher)** to show your support and help others discover it! If Claude Switcher saves you money and time, consider [buying us a coffee](https://buymeacoffee.com/andisearch) or [sponsoring on GitHub](https://github.com/sponsors/andisearch). Every contribution helps!

## Quick Start

**Prerequisites**: [Claude Code](https://www.claude.com/product/claude-code) installed

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
   
   # Vercel AI Gateway Credentials
   export VERCEL_AI_GATEWAY_TOKEN="vck_..."
   ```

3. **Start switching between providers:**
   ```bash
   claude-aws          # Use AWS Bedrock
   claude-vertex       # Use Google Vertex AI
   claude-apikey       # Use Anthropic API
   claude-azure --opus # Use Microsoft Azure with Opus 4.5
   claude-vercel       # Use Vercel AI Gateway (failover, unified billing)
   
   # Continue your last conversation on any provider
   claude-aws --resume
   claude-vertex --opus --resume

   # Switch back to your native Claude Code
   claude --resume
   ```

That's it! See below for detailed configuration options and advanced features.

## Features

- **Multiple Providers**: Support for Anthropic API, AWS Bedrock, Google Vertex AI, Microsoft Foundry on Azure, and Vercel AI Gateway.
- **Model Switching**: Easily switch between Sonnet 4.5, Opus 4.5, Haiku 4.5, or custom models.
- **Pro Plan Support**: Toggle back to standard Claude Pro or Max subscriptions with native web authentication.
- **Seamless Switching**: Switch between providers and authentication methods without logout flows.
- **Session Management**: Unique session IDs for tracking.
- **Secure Configuration**: API keys stored in a separate, git-ignored file.
- **System-Wide Access**: Scripts are installed to `/usr/local/bin` for easy access.

## How It Works

Claude Switcher provides **session-scoped, non-destructive** provider switching:

- **AWS/Vertex/Azure**: Scripts set provider-specific environment variables (`CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`, `CLAUDE_CODE_USE_FOUNDRY`) and launch Claude Code
- **Anthropic API**: Uses Claude Code's `apiKeyHelper` to read your API key from `secrets.sh` without exposing it as an environment variable
- **Pro/Max Mode**: `claude-pro` temporarily removes apiKeyHelper for the session
- **Automatic Restoration**: All sessions preserve and restore your original configuration on exit
- **Plain `claude` Unaffected**: Always runs in your native, unmodified state

**Result**: Switch between any provider instantly without logout flows, browser prompts, or authentication friction.

## Installation

### 1. Clone and Setup
```bash
git clone https://github.com/andisearch/claude-switcher.git
cd claude-switcher
./setup.sh
```

The setup script installs commands to `/usr/local/bin`, creates `~/.claude-switcher/` for configuration, and installs the API key helper. You may be prompted for your password.

> [!TIP]
> Setup does NOT modify your Claude configuration. All switcher scripts are **session-scoped**—they only affect their own session and automatically restore your original configuration on exit. Plain `claude` always runs unmodified.

### 2. Uninstallation

To remove claude-switcher:

```bash
./uninstall.sh
```

Removes all commands from `/usr/local/bin`, prompts before removing configuration (contains API keys), and cleans up apiKeyHelper references while preserving your settings and backups.

### 3. Configure Your Secrets
The setup script creates a secrets file at `~/.claude-switcher/secrets.sh`. You must edit this file to add your API keys and credentials.

```bash
nano ~/.claude-switcher/secrets.sh
```

#### Adding API Keys
Uncomment and fill in the sections for the providers you wish to use:

**AWS Bedrock:**

Recommended authentication ([see all options](https://code.claude.com/docs/en/amazon-bedrock)):

```bash
# AWS Profile (recommended)
export AWS_PROFILE="your-profile-name"
export AWS_REGION="us-west-2"
```

> **Note**: Alternatives include `AWS_BEARER_TOKEN_BEDROCK` or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`. `AWS_REGION` is required.

**Google Vertex AI:**

**Setup Steps:**
1. **Install Google Cloud SDK**: [Download here](https://cloud.google.com/sdk/docs/install)
2. **Authenticate** using one of these methods (checked in precedence order):
   - **Service Account Key** (production/CI): `export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"`
   - **Application Default Credentials** (local dev): `gcloud auth application-default login`
   - **gcloud User Credentials** (fallback): `gcloud auth login`
3. **Enable Vertex AI API**: [Click to enable](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com)
4. **Enable Claude Models**: [Open Model Garden](https://console.cloud.google.com/vertex-ai/model-garden/) and enable desired models under the Anthropic publisher
5. **Configure secrets.sh**:
   ```bash
   export ANTHROPIC_VERTEX_PROJECT_ID="your-gcp-project-id"
   export CLOUD_ML_REGION="global"
   ```

See Anthropic's [Google Vertex instructions](https://code.claude.com/docs/en/google-vertex-ai) for more details.

> **Note**: Models are region-specific. Check [availability](https://console.cloud.google.com/vertex-ai/model-garden/) in your region. Optionally set per-model regions with `VERTEX_REGION_CLAUDE_4_5_SONNET` etc.

**Anthropic API:**

> **Note**: When using `claude-apikey`, your API key is validated but NOT exported as an environment variable to avoid authentication conflicts. The `apiKeyHelper` script reads the key directly from `secrets.sh` and provides it to Claude CLI as a token. This ensures only one authentication method is active.

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

**Microsoft Foundry on Azure:**

Announced November 18, 2024 ([blog post](https://www.anthropic.com/news/claude-in-microsoft-foundry)).

**Setup Steps:**
1. Navigate to [Microsoft Foundry portal](https://ai.azure.com/) and create an Azure resource
2. Deploy Claude models (Opus, Sonnet, and/or Haiku)
3. Get credentials from your resource's "Endpoints and keys" section
4. **Configure secrets.sh**:
   ```bash
   # Option 1: API Key (simpler)
   export ANTHROPIC_FOUNDRY_API_KEY="your-azure-api-key"
   export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
   
   # Option 2: Azure CLI (run: az login)
   export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
   ```

See Anthropic's [Microsoft Foundry instructions](https://code.claude.com/docs/en/microsoft-foundry) for more details.

> **Note**: Use the default deployment names or set custom names to match what you created in Azure: `CLAUDE_MODEL_SONNET_AZURE`, `CLAUDE_MODEL_HAIKU_AZURE`, `CLAUDE_MODEL_OPUS_AZURE`.

**Vercel AI Gateway:**

Route Claude Code through Vercel's AI Gateway for failover, unified billing, and spend management ([announcement](https://x.com/rauchg/status/2007556249437778419)).

**Setup Steps:**
1. Create a Vercel account and go to [AI Gateway settings](https://vercel.com/dashboard/~/ai)
2. Generate an API key (starts with `vck_`)
3. **Configure secrets.sh**:
   ```bash
   export VERCEL_AI_GATEWAY_TOKEN="vck_..."
   export VERCEL_AI_GATEWAY_URL="https://ai-gateway.vercel.sh"  # Optional, this is the default
   ```

See [Vercel AI Gateway docs](https://vercel.com/ai-gateway) for more details.

> **Note**: Vercel AI Gateway provides automatic failover (e.g., to AWS Bedrock) and unified billing across all AI providers.

#### Overriding Defaults (Optional)
You can override default model IDs or regions in the same `secrets.sh` file. This is useful for testing new models or using custom endpoints.

**Example: Override AWS Region and Model**
```bash
export AWS_REGION="us-east-1"
export CLAUDE_MODEL_SONNET_AWS="global.anthropic.claude-sonnet-4-5-20250929-v1:0"
```

## Switching Providers to Avoid Rate Limits

**This is the killer feature.** Claude Pro has rate limits that reset every 5 hours (daily) and 7 days (weekly). When you hit a limit mid-task, instantly switch to your API keys and keep working.

### Quick Switch with `--resume`

```bash
# Working with Claude Pro, hit rate limit
claude
# "Rate limit exceeded. Try again in 4 hours 23 minutes."

# Immediately continue with AWS (keeps conversation context)
claude-aws --resume

# Or switch to Haiku for speed/cost, Opus for complex reasoning
claude-aws --haiku --resume
claude-aws --opus --resume

# Or use Vertex AI
claude-vertex --resume
```

The `--resume` flag picks up your last conversation exactly where you left off. No lost context, no restarting explanations.

### Common Workflows

```bash
claude-aws --resume          # Hit Pro limit? Continue on AWS credits
claude-aws --haiku --resume  # Need faster responses? Switch to Haiku
claude-apikey --opus --resume # Complex reasoning needed? Use Opus
claude --resume              # Back to Pro when limits reset
```

### Why This Works

- **Claude Pro**: Great for normal work, limited (10-40 prompts per 5-hour window)
- **Your API**: Unlimited usage, pay per token, use cloud credits
- **Instant switching**: One command, same conversation, no friction


## Usage

Once installed, use these commands from any terminal window:

### Provider Commands

| Provider | Command | Model Flags | Custom Model |
|----------|---------|-------------|-------------|
| **AWS Bedrock** | `claude-aws` | `--opus`, `--haiku`, `--sonnet` (default) | `--model "global.anthropic.claude-sonnet-4-5-20250929-v1:0"` |
| **Google Vertex AI** | `claude-vertex` | `--opus`, `--haiku`, `--sonnet` (default) | `--model "claude-sonnet-4-5@20250929"` |
| **Anthropic API** | `claude-apikey` | `--opus`, `--haiku`, `--sonnet` (default) | `--model "claude-sonnet-4-5-20250929"` |
| **Microsoft Azure** | `claude-azure` | `--opus`, `--haiku`, `--sonnet` (default) | `--model "my-custom-deployment"` |
| **Vercel AI Gateway** | `claude-vercel` | `--opus`, `--haiku`, `--sonnet` (default) | `--model "anthropic/claude-sonnet-4.5"` |
| **Claude Pro/Max** | `claude-pro` or `claude` | N/A - uses subscription | N/A |

**Examples:**
```bash
# Use default model (Sonnet 4.5 - latest)
claude-aws

# Use Opus 4.5 (most capable for planning and reasoning)
claude-vertex --opus

# Use Haiku 4.5 (fastest, most cost-effective)
claude-apikey --haiku

# Use custom model ID or deployment
claude-aws --model "global.anthropic.claude-sonnet-4-5-20250929-v1:0"

# Use Vercel AI Gateway
claude-vercel
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

Default model IDs are defined in `config/models.sh`. The `--sonnet`, `--opus`, and `--haiku` flags use the latest version of each model tier. To customize models, override them in `~/.claude-switcher/secrets.sh` (see `secrets.example.sh` for all available variables).

#### Model Configuration: Main + Small/Fast Models

Claude Code uses **two models** for optimal performance:

1. **`ANTHROPIC_MODEL`** - Main model for interactive work (conversation, reasoning, complex tasks)
   - Set via `--sonnet`, `--opus`, `--haiku` flags or `--model` override
   
2. **`ANTHROPIC_SMALL_FAST_MODEL`** - Background operations model (sub-agents, file operations)  
   - Defaults to Haiku for each provider to reduce costs
   - See [Claude Code docs](https://code.claude.com/docs/en/model-config#environment-variables)

**Configuration Pattern:**

- **Defaults**: Set in `config/models.sh` (e.g., `CLAUDE_SMALL_FAST_MODEL_AWS` defaults to Haiku)
- **Overrides**: Customize in `~/.claude-switcher/secrets.sh`:
  ```bash
  # Example: Use custom small/fast model for AWS
  export CLAUDE_SMALL_FAST_MODEL_AWS="us.anthropic.claude-3-5-haiku-20241022-v1:0"
  ```
- **Runtime**: Scripts automatically set `ANTHROPIC_MODEL` and `ANTHROPIC_SMALL_FAST_MODEL` based on provider

**Example:**
```bash
claude-aws --opus
# Sets: ANTHROPIC_MODEL = Opus 4.5 (your choice)
#       ANTHROPIC_SMALL_FAST_MODEL = Haiku 4.5 (auto)
```

### Updating Models and Secrets

When new Claude models are released, update with:

```bash
cd claude-switcher
git pull
./setup.sh
```

Setup preserves your API keys in `~/.claude-switcher/secrets.sh`. Your credentials are stored separately in `~/.claude-switcher/secrets.sh` and are never committed to the repository.

## Troubleshooting

### Verify Configuration

Check your current configuration:

```bash
claude-status  # Shows authentication, mode, and configuration
cat ~/.claude-switcher/current-mode.sh  # Current provider mode
```

### Common Issues

**Still getting rate limits after switching to API?**

1. Verify API key: `grep ANTHROPIC_API_KEY ~/.claude-switcher/secrets.sh`
2. Confirm you're using the wrapper (not plain `claude`)
3. Run `claude-status` during the session
4. In Claude, run `/status` to see authentication method

**Switching back to Pro not working?**

1. Make sure you're running `claude-pro` (creates new session)
2. Or use plain `claude` (always native state)
3. In Claude, run `/status` to verify authentication

> **Remember**: Wrapper scripts are session-scoped. Each time you want Anthropic API, run `claude-apikey`. After exiting any wrapper, plain `claude` returns to native state.

### Session-Scoped Behavior

All wrapper scripts are session-scoped:
- Changes only affect the active Claude session
- On exit, original settings automatically restore
- Plain `claude` always runs in native state

Verify native state:
```bash
# Exit any active session, then check:
cat ~/.claude/settings.json
# Should show your original apiKeyHelper (or none if you never had one)
```

### Manual Reset (Emergency Only)

If something goes wrong:

```bash
# Remove state files
rm -f ~/.claude-switcher/apiKeyHelper-state-*.tmp

# Check settings
cat ~/.claude/settings.json

# Restore from backup if needed
ls ~/.claude/settings.json.backup-*
cp ~/.claude/settings.json.backup-YYYYMMDD-HHMMSS ~/.claude/settings.json
```

### Test apiKeyHelper

Verify the helper script:

```bash
# Test in Pro mode (should output nothing)
echo 'export CLAUDE_SWITCHER_MODE="pro"' > ~/.claude-switcher/current-mode.sh
~/.claude-switcher/claude-api-key-helper.sh

# Test in Anthropic mode (should output your API key)
echo 'export CLAUDE_SWITCHER_MODE="anthropic"' > ~/.claude-switcher/current-mode.sh 
~/.claude-switcher/claude-api-key-helper.sh
```

## Versioning

**Current Version**: see [VERSION](VERSION) or run `claude-apikey --version`

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

Claude Switcher is **free and open source**, built to help developers be more productive and save money with Claude Code.

### ⭐ Star This Repo
The simplest way to show your support is to **[give us a star on GitHub](https://github.com/andisearch/claude-switcher)**!

[![GitHub Stars](https://img.shields.io/github/stars/andisearch/claude-switcher?style=social)](https://github.com/andisearch/claude-switcher/stargazers)

### 💖 Donate
Your support helps us maintain this project and build [Andi AI search](https://andisearch.com).

- 🩷 **[GitHub Sponsors](https://github.com/sponsors/andisearch)** - Recurring or one-time
- ☕ **[Buy Me a Coffee](https://buymeacoffee.com/andisearch)** - Quick one-time
- 💙 **[PayPal](https://www.paypal.me/lazywebai)** - Direct donation

### 🤝 Other Ways to Help
- **Share** with colleagues and friends
- **Contribute** via bug reports, feature requests, or pull requests
- **Feedback** on how you're using it and how we can improve

## Acknowledgments

Thanks to the team at Anthropic for creating the awesome Claude Code, the fantastic Sonnet, Opus and Haiku models, and for their open source tools. We are not associated with Anthropic in any way, other than being big fans of Claude Code.

Huge thanks also to the Startups teams at Microsoft Azure, AWS and Google Cloud for their generous support of Andi and startups in general. And very special thanks to Britton Winterrose and Ryan Merket at Microsoft for going above and beyond to help keep Andi running! Without their support this project would not be possible.

## Authors

**Claude Switcher** is created and maintained by:
- **Jed White**, CTO of [Andi](https://andisearch.com)
- **Angela Hoover**, CEO of [Andi](https://andisearch.com)

Contributions welcome. See [CONTRIBUTORS.md](CONTRIBUTORS.md) for a full list of contributors.

## License

MIT License. Copyright (c) 2025 LazyWeb Inc DBA Andi (https://andisearch.com).

See [LICENSE](LICENSE) for full license text.
