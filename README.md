# Claude Code Switcher

[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub-pink?logo=github&style=for-the-badge)](https://github.com/sponsors/andisearch)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support-yellow?logo=buy-me-a-coffee&style=for-the-badge)](https://buymeacoffee.com/andisearch)
[![PayPal](https://img.shields.io/badge/PayPal-Donate-blue?logo=paypal&style=for-the-badge)](https://www.paypal.me/lazywebai)
[![GitHub Stars](https://img.shields.io/github/stars/andisearch/claude-switcher?style=for-the-badge&logo=github)](https://github.com/andisearch/claude-switcher/stargazers)

Switch between Claude Code providers (Pro/Max, Anthropic API, AWS, Google Cloud, Azure, Vercel) with a single command. Hit rate limits? Continue on your API keys. Need Opus without Max? Use any provider.

**Key features:**
- **Provider switching**: `claude-run --aws --opus` or `claude-run --vertex --resume`
- **Executable markdown**: `#!/usr/bin/env claude-run` shebang for AI-powered scripts
- **Non-destructive**: Plain `claude` always works normally—switcher only affects its own sessions

From [Andi AI](https://andisearch.com).

> [!TIP]
> ⭐ **[Star this repo](https://github.com/andisearch/claude-switcher)** if it helps! [Buy us a coffee](https://buymeacoffee.com/andisearch) or [sponsor on GitHub](https://github.com/sponsors/andisearch).

## Quick Start

**Prerequisites**: [Claude Code](https://www.claude.com/product/claude-code) installed

```bash
# Install
git clone https://github.com/andisearch/claude-switcher.git
cd claude-switcher && ./setup.sh

# Configure at least one provider (e.g., AWS)
echo 'export AWS_PROFILE="my-profile"' >> ~/.claude-switcher/secrets.sh
echo 'export AWS_REGION="us-west-2"' >> ~/.claude-switcher/secrets.sh

# Use it
claude-run --aws              # Use AWS Bedrock
claude-run --aws --opus       # With Opus 4.5
claude-run --aws --resume     # Resume conversation

# Plain claude is always unaffected
claude                        # Your normal Claude setup
```

See [Provider Setup](#provider-setup) for all providers and [Usage](#usage) for full options.

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

## Provider Setup

The secrets file at `~/.claude-switcher/secrets.sh` stores your API credentials. Edit it to add your provider keys:

```bash
nano ~/.claude-switcher/secrets.sh
```

### AWS Bedrock

Recommended authentication ([see all options](https://code.claude.com/docs/en/amazon-bedrock)):

```bash
# AWS Profile (recommended)
export AWS_PROFILE="your-profile-name"
export AWS_REGION="us-west-2"
```

> **Note**: Alternatives include `AWS_BEARER_TOKEN_BEDROCK` or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`. `AWS_REGION` is required.

### Google Vertex AI

**Setup:**
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

### Anthropic API

> **Note**: When using `claude-apikey`, your API key is validated but NOT exported as an environment variable to avoid authentication conflicts. The `apiKeyHelper` script reads the key directly from `secrets.sh` and provides it to Claude CLI as a token. This ensures only one authentication method is active.

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

### Microsoft Azure

**Setup:**
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

### Vercel AI Gateway

Routes through Vercel for failover and unified billing. [Docs](https://vercel.com/ai-gateway)

**Setup:**
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

### claude-run (Recommended)

A unified command for provider switching and executable markdown.

**Interactive mode:**
```bash
claude-run                         # Default (same as claude)
claude-run --aws                   # AWS Bedrock
claude-run --vertex                # Google Vertex AI
claude-run --apikey                # Anthropic API
claude-run --azure                 # Microsoft Azure
claude-run --vercel                # Vercel AI Gateway
claude-run --pro                   # Claude Pro/Max subscription
```

**Model selection:**
```bash
claude-run --aws --opus            # Opus 4.5 (most capable)
claude-run --vertex --sonnet       # Sonnet 4.5 (default)
claude-run --apikey --haiku        # Haiku 4.5 (fastest)
claude-run --aws --resume          # Resume last conversation
```

**Executable markdown files:**

Create markdown files with prompts that run directly via shebang. **Flags are fully supported in the shebang line:**

```markdown
#!/usr/bin/env claude-run
Summarize the architecture of this codebase.
```

```markdown
#!/usr/bin/env -S claude-run --aws
Use AWS Bedrock to analyze this code.
```

```markdown
#!/usr/bin/env -S claude-run --vertex --opus
Use Vertex AI with Opus 4.5 for complex reasoning.
```

```markdown
#!/usr/bin/env -S claude-run --output-format json
Return a JSON object with keys "summary" and "recommendations".
```

```markdown
#!/usr/bin/env -S claude-run --output-format stream-json
Stream output in real-time as JSON chunks (for live feedback).
```

**Usage:**
```bash
chmod +x task.md
./task.md                          # Execute directly (uses shebang flags)
claude-run --vercel task.md        # Override: use Vercel instead of shebang provider
claude-run --opus task.md          # Override: use Opus instead of shebang model
```

Command-line flags override any flags specified in the shebang line.

> [!TIP]
> Use `#!/usr/bin/env -S` (with `-S`) to pass multiple flags in the shebang line. This works on macOS and modern Linux.

> [!WARNING]
> **Security**: Executable markdown runs AI-generated code without approval (like `claude -p`). Only run trusted prompts in trusted directories. Never use `--dangerously-skip-permissions` outside sandboxed environments.

---

### Individual Provider Scripts

For more control, use provider-specific scripts:

| Provider | Script | Example |
|----------|--------|---------|
| AWS Bedrock | `claude-aws` | `claude-aws --opus --resume` |
| Google Vertex AI | `claude-vertex` | `claude-vertex --haiku` |
| Anthropic API | `claude-apikey` | `claude-apikey --model claude-opus-4-5-20250929` |
| Microsoft Azure | `claude-azure` | `claude-azure --sonnet` |
| Vercel AI Gateway | `claude-vercel` | `claude-vercel` |
| Claude Pro/Max | `claude-pro` | `claude-pro` |

These scripts handle authentication, environment setup, and session tracking automatically.

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
- **Vercel AI Gateway**: Shows base URL, auth token status, and model configuration
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
