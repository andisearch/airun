# Claude Code Switcher

[![GitHub Stars](https://img.shields.io/github/stars/andisearch/claude-switcher?style=for-the-badge&logo=github)](https://github.com/andisearch/claude-switcher/stargazers)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support-yellow?logo=buy-me-a-coffee&style=for-the-badge)](https://buymeacoffee.com/andisearch)

Automate scripts with Claude Code. Use shebang support for executable markdown files, pipe data through AI scripts in standard Unix pipelines, and switch between providers (Pro/Max, Anthropic API, AWS, Google Cloud, Azure, Vercel) without logging out.

**What it does:**
- Script automation with `#!/usr/bin/env claude-run` shebang for executable markdown files
- Unix pipe support: pipe data into scripts, redirect output, chain in pipelines
- Provider switching (optional): `claude-run --aws`, `claude-run --vertex`, etc. Use specific provider API keys in scripts or when you hit rate limits, or for billing management / isolation
- Model selection: `--opus`, `--haiku`, `--sonnet` and full Claude Code flag support
- Session continuity: `--resume` picks up your last conversation on any provider
- Non-destructive: plain `claude` always works as before (switcher is session-scoped)

From [Andi Search](https://andisearch.com). [Star this repo ⭐](https://github.com/andisearch/claude-switcher) if it helps!

## Quick Start

**Prerequisites**: [Claude Code](https://www.claude.com/product/claude-code) installed

```bash
# Install
git clone https://github.com/andisearch/claude-switcher.git
cd claude-switcher && ./setup.sh
```

**That's it!** You can now run any markdown file as a Claude script:

```bash
# Create an executable prompt
cat > task.md << 'EOF'
#!/usr/bin/env claude-run
Analyze my codebase and summarize the architecture.
EOF

chmod +x task.md
./task.md                         # Runs with your Claude subscription
```

Or run any markdown file directly:
```bash
claude-run task.md
```

**Pipe data and redirect output** (Unix-style automation):
```bash
cat data.json | ./analyze.md > results.txt    # Pipe in, redirect out
git log -10 | ./summarize.md                  # Feed git history to AI
./generate.md | ./review.md > final.txt       # Chain scripts together
```

**Minimal alternative**: If you just want basic executable markdown without installing this repo, add a `claude-runner` script to your PATH:
```bash
#!/bin/bash
claude -p "$(tail -n +2 "$1")"
```
This script strips the shebang line (`tail -n +2`) and runs in print mode (`-p`) for clean output. It does **not** support Unix pipe features (stdin input, pipeline chaining, clean redirected output), provider switching, model selection, output formats, or session isolation — these require the full repo.

### Optional: Configure Providers

To switch between providers (AWS, Vertex, etc.) or use API keys:

```bash
# Edit secrets file
nano ~/.claude-switcher/secrets.sh

# Example: Add AWS credentials
export AWS_PROFILE="my-profile"
export AWS_REGION="us-west-2"
```

Then use provider flags:
```bash
claude-run --aws task.md          # Run via AWS Bedrock
claude-run --aws --opus           # Interactive with Opus 4.5
claude-run --vertex --resume      # Resume via Vertex AI
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

### 2. Updating

```bash
cd claude-switcher && git pull && ./setup.sh
```

Your API keys in `~/.claude-switcher/secrets.sh` are preserved.

### 3. Uninstallation

To remove claude-switcher:

```bash
./uninstall.sh
```

Removes all commands from `/usr/local/bin`, prompts before removing configuration (contains API keys), and cleans up apiKeyHelper references while preserving your settings and backups.

### 4. Tests

Run `./test/automation/run_tests.sh` to validate script automation examples. See [test/README.md](test/README.md) for details.

## Provider Setup

Configure providers by adding credentials to `~/.claude-switcher/secrets.sh`, then use `claude-run` with provider flags:

```bash
nano ~/.claude-switcher/secrets.sh   # Add credentials
claude-run --aws task.md             # Use AWS Bedrock
claude-run --vertex --opus           # Interactive Vertex AI with Opus
```

### AWS Bedrock

Recommended authentication ([see all options](https://code.claude.com/docs/en/amazon-bedrock)):

```bash
# AWS Profile (recommended)
export AWS_PROFILE="your-profile-name"
export AWS_REGION="us-west-2"
```

Alternatives: `AWS_BEARER_TOKEN_BEDROCK` or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`. `AWS_REGION` is required.

### Google Vertex AI

1. Install [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
2. Authenticate (checked in precedence order):
   - Service Account Key (production/CI): `export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"`
   - Application Default Credentials (local dev): `gcloud auth application-default login`
   - gcloud User Credentials (fallback): `gcloud auth login`
3. [Enable Vertex AI API](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com)
4. Enable Claude models in [Model Garden](https://console.cloud.google.com/vertex-ai/model-garden/) under the Anthropic publisher
5. Configure secrets.sh:
   ```bash
   export ANTHROPIC_VERTEX_PROJECT_ID="your-gcp-project-id"
   export CLOUD_ML_REGION="global"
   ```

See Anthropic's [Vertex AI instructions](https://code.claude.com/docs/en/google-vertex-ai) for details. Models are region-specific; optionally set per-model regions with `VERTEX_REGION_CLAUDE_4_5_SONNET` etc.

### Anthropic API

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

Interactive sessions use `apiKeyHelper` to provide your key without exporting it as an environment variable, avoiding authentication conflicts.

### Microsoft Azure

1. Create an Azure resource in [Microsoft Foundry portal](https://ai.azure.com/)
2. Deploy Claude models (Opus, Sonnet, and/or Haiku)
3. Get credentials from "Endpoints and keys"
4. Configure secrets.sh:
   ```bash
   # Option 1: API Key (simpler)
   export ANTHROPIC_FOUNDRY_API_KEY="your-azure-api-key"
   export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
   
   # Option 2: Azure CLI (run: az login)
   export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
   ```

See Anthropic's [Foundry instructions](https://code.claude.com/docs/en/microsoft-foundry) for details. Set custom deployment names with `CLAUDE_MODEL_SONNET_AZURE`, `CLAUDE_MODEL_HAIKU_AZURE`, `CLAUDE_MODEL_OPUS_AZURE`.

### Vercel AI Gateway

Routes through Vercel for failover and unified billing.

1. Go to [AI Gateway settings](https://vercel.com/dashboard/~/ai)
2. Generate an API key (starts with `vck_`)
3. Configure secrets.sh:
   ```bash
   export VERCEL_AI_GATEWAY_TOKEN="vck_..."
   export VERCEL_AI_GATEWAY_URL="https://ai-gateway.vercel.sh"  # Optional default
   ```

See [Vercel AI Gateway docs](https://vercel.com/ai-gateway) for details.

#### Overriding Defaults (Optional)
You can override default model IDs or regions in the same `secrets.sh` file. This is useful for testing new models or using custom endpoints.

**Example: Override AWS Region and Model**
```bash
export AWS_REGION="us-east-1"
export CLAUDE_MODEL_SONNET_AWS="global.anthropic.claude-sonnet-4-5-20250929-v1:0"
```

## Switching Providers to Avoid Rate Limits

Claude Pro has rate limits that reset every 5 hours (daily) and 7 days (weekly). When you hit a limit mid-task, switch to your API keys and keep working.

### Quick Switch with `--resume`

```bash
# Working with Claude Pro, hit rate limit
claude
# "Rate limit exceeded. Try again in 4 hours 23 minutes."

# Immediately continue with AWS (keeps conversation context)
claude-run --aws --resume

# Or switch to Haiku for speed/cost, Opus for complex reasoning
claude-run --aws --haiku --resume
claude-run --aws --opus --resume

# Or use Vertex AI
claude-run --vertex --resume
```

The `--resume` flag picks up your last conversation exactly where you left off. No lost context, no restarting explanations.

### Common Workflows

```bash
claude-run --aws --resume          # Hit Pro limit? Continue on AWS credits
claude-run --aws --haiku --resume  # Need faster responses? Switch to Haiku
claude-run --apikey --opus --resume # Complex reasoning needed? Use Opus
claude --resume                     # Back to Pro when limits reset
```

### Why This Works

- Claude Pro: Included with subscription, rate-limited (10-40 prompts per 5-hour window)
- Your API: Pay per token, no rate limits, use cloud credits
- One command switches provider, same conversation


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

```markdown
#!/usr/bin/env -S claude-run --permission-mode bypassPermissions
Run ./test/automation/run_tests.sh and report results.
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
> Security: Executable markdown runs AI-generated code without approval (like `claude -p`). Only run trusted prompts in trusted directories. Never use `--dangerously-skip-permissions` outside sandboxed environments.

> [!NOTE]
> Full Automation: By default, Claude asks for approval before running commands. Use `--permission-mode bypassPermissions` to skip all permission checks for unattended scripts. Only use in trusted environments.

**Unix pipe support:**

Executable markdown scripts have proper Unix semantics for automation:

- Clean piped output — when you redirect to a file, you get only Claude's response. No banners, no escape codes, no status messages.
- Stdin support — pipe data directly into scripts.
- Chainable — connect scripts together in pipelines.
- Standard streams — stdout is data, stderr is diagnostics (the Unix convention).

```bash
# Clean output to file
./analyze.md > results.txt

# Pipe data into scripts  
cat data.json | ./process.md
git log --oneline -20 | ./summarize-changes.md

# Chain scripts together
./generate-report.md | ./format-output.md > final.txt

# Control stdin position (default: prepend)
cat data.txt | ./analyze.md --stdin-position append
```

Use in shell scripts:

```bash
#!/bin/bash
for f in logs/*.txt; do
    cat "$f" | ./analyze.md >> summary.txt
done
```

Combine traditional tools with AI:

```bash
git log --oneline -20 | ./explain-changes.md > changelog-summary.txt
```

---

### Legacy Provider Scripts

Direct scripts are available for backward compatibility:

| Script | Equivalent |
|--------|-----------|
| `claude-aws` | `claude-run --aws` |
| `claude-vertex` | `claude-run --vertex` |
| `claude-apikey` | `claude-run --apikey` |
| `claude-azure` | `claude-run --azure` |
| `claude-vercel` | `claude-run --vercel` |
| `claude-pro` | `claude-run --pro` |

All legacy scripts support the same flags (`--opus`, `--haiku`, `--resume`, etc.).

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

> **Remember**: Wrapper scripts are session-scoped. Each time you want Anthropic API, run `claude-run --apikey`. After exiting any wrapper, plain `claude` returns to native state.

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

## Support

Claude Switcher is free and open source.

- **[Star on GitHub](https://github.com/andisearch/claude-switcher)** — helps others discover the project
- **[Buy Me a Coffee](https://buymeacoffee.com/andisearch)** — one-time support
- **[GitHub Sponsors](https://github.com/sponsors/andisearch)** — supports the broader [Andi AI search](https://andisearch.com) project
- **Share** with colleagues, report bugs, or submit PRs

## Acknowledgments

Thanks to [Pete Koomen](https://x.com/koomen/status/2007894999506235409?s=20) from YC for the great idea of executable markdown! Pete's insight was spot-on: executable prompts become reusable tools. Put them in your repo. Run them in CI. Chain them together. Share them with your team. A prompt that lives in a file is a prompt you'll actually use again.

Thanks to Reddit user ([apf6](https://www.reddit.com/user/apf6/)) for the suggestion to add a minimal alternative script like `claude "$(cat "$1")"` for shebang support for Claude.

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
