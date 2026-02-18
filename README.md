# Andi AIRun

Run AI prompts like programs. Executable markdown with shebang, Unix pipes, and output redirection. Extends Claude Code with cross-cloud provider switching and any-model support — free local or 100+ cloud models.

```bash
# Run Claude Code interactively: any model or provider
ai                                        # Regular Claude subscription (Pro, Max)
ai --aws --opus --team --resume           # Resume chats on AWS w/ Opus 4.6 + Agent Teams
ai --ollama --bypass --model qwen3-coder  # Ollama local model with bypassPermissions set
ai --vercel --model openai/gpt-5.2-codex  # Vercel AI Gateway with 100+ models

# Run prompts like programs
ai --azure --haiku script.md

# Script automation
cat data.json | ./analyze.md > results.txt
```

Switch between your [Claude Code](https://claude.ai/code) subscription and different clouds + models: AWS Bedrock, Google Vertex, Azure, Vercel + Anthropic API. Supports free local models ([Ollama](https://ollama.com/), [LM Studio](https://lmstudio.ai/)) and 100+ alternate cloud models via [Vercel AI Gateway](https://vercel.com/ai-gateway) or Ollama Cloud. Swap and resume conversations mid-task to avoid rate limits and keep working.

[![GitHub Stars](https://img.shields.io/github/stars/andisearch/airun?style=for-the-badge&logo=github)](https://github.com/andisearch/airun/stargazers)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support-yellow?logo=buy-me-a-coffee&style=for-the-badge)](https://buymeacoffee.com/andisearch)
[![Website](https://img.shields.io/badge/Website-airun.me-blue?style=for-the-badge&logo=safari)](https://airun.me)

**What it does:**
- Executable markdown with `#!/usr/bin/env ai` shebang for script automation
- Unix pipe support: pipe data into scripts, redirect output, chain in pipelines
- Cross-cloud provider switching: use Claude on AWS, Vertex, Azure, Anthropic API + switch mid-conversation to bypass rate limits. Also supports local models and Vercel AI Gateway
- Model tiers: `--opus`/`--high`, `--sonnet`/`--mid`, `--haiku`/`--low`
- Session continuity: `--resume` picks up your previous chats with any model/provider
- Non-destructive: plain `claude` always works untouched as before

From [Andi AI Search](https://andisearch.com). [Star this repo](https://github.com/andisearch/airun) if it helps!

**Latest:** Script variables (`vars:` front-matter + `{{placeholders}}`), live streaming (`--live`), Agent Teams (`--team`), Opus 4.6, local models (Ollama, LM Studio), persistent defaults, 100+ cloud models via Vercel. See [CHANGELOG.md](CHANGELOG.md).

## Quick Start

**Supported Platforms:**
- macOS 13.0+
- Linux (Ubuntu 20.04+, Debian 10+)
- Windows 10+ via WSL

**Prerequisites**: [Claude Code](https://claude.ai/code) (Anthropic's AI coding CLI) installed

```bash
# Install Claude Code (if not already installed)
curl -fsSL https://claude.ai/install.sh | bash

# Install Andi AIRun
git clone https://github.com/andisearch/airun.git
cd airun && ./setup.sh
```

You can now run any markdown file as an AI script:

```bash
# Create an executable prompt
cat > task.md << 'EOF'
#!/usr/bin/env ai
Analyze my codebase and summarize the architecture.
EOF

chmod +x task.md
./task.md                         # Runs with your Claude subscription
```

Or run any markdown file directly:
```bash
ai task.md
```

**Pipe data and redirect output** (Unix-style automation):
```bash
cat data.json | ./analyze.md > results.txt    # Pipe in, redirect out
git log -10 | ./summarize.md                  # Feed git history to AI
./generate.md | ./review.md > final.txt       # Chain scripts together
```

**Run scripts from the web** ([installmd.org](https://installmd.org/) support):
```bash
curl -fsSL https://andisearch.github.io/ai-scripts/analyze.md | ai
echo "Explain what a Makefile does" | ai         # Simple prompt
```

**Minimal alternative**: If you just want basic executable markdown without installing this repo, add a `ai` script to your PATH:
```bash
#!/bin/bash
claude -p "$(tail -n +2 "$1")"
```

This works for simple prompts but lacks provider switching, model selection, stdin piping, output formats, and session isolation. ([credit: apf6](https://www.reddit.com/r/ClaudeAI/comments/1q44kkd/comment/nxpyfui/))

## Commands

| Command | Description |
|---------|-------------|
| `ai` / `airun` | Universal entry point - run scripts, switch providers |
| `ai update` | Update AI Runner to the latest version |
| `ai-sessions` | View active AI coding sessions |
| `ai-status` | Show current configuration and provider status |

Running `ai` with no flags is equivalent to running `claude` with your regular subscription settings, but session-scoped. Your environment is automatically restored on exit. Add provider flags to switch, or use `ai --aws --opus --set-default` to save your preferred provider and model for future runs.

### Usage Examples

```bash
# Run a markdown script (uses your Claude subscription, same as 'claude')
ai task.md

# Switch provider with flags
ai --aws                          # AWS Bedrock
ai --vertex                       # Google Vertex AI
ai --ollama                       # Ollama (local, free)
ai --lmstudio                     # LM Studio (local, free)
ai --apikey                       # Anthropic API
ai --azure                        # Microsoft Azure
ai --vercel                       # Vercel AI Gateway
ai --pro                          # Claude Pro/Max subscription

# Local model selection
ai --ollama --model qwen3-coder   # Ollama with specific model
ai --ollama --model glm-5:cloud       # Ollama cloud model (no GPU needed)
ai --lmstudio --model openai/gpt-oss-20b  # LM Studio with specific model

# Use any model via Vercel (OpenAI, xAI, Google, more)
ai --vercel --model openai/gpt-5.2-codex      # OpenAI coding model

# Model selection (Pro defaults to latest, API providers default to Sonnet)
ai --opus task.md                 # Opus 4.6 (most capable)
ai --sonnet task.md               # Sonnet 4.6
ai --haiku task.md                # Haiku 4.5 (fastest)

# Alternative tier names
ai --high task.md                 # Same as --opus
ai --mid task.md                  # Same as --sonnet
ai --low task.md                  # Same as --haiku

# Stream output in real-time (prompt should say "print as you go" or similar)
ai --live --skip task.md

# Suppress --live status for CI/CD (clean stdout only)
ai --quiet ./live-script.md > output.md

# Live output + file redirect (narration to console, clean content to file)
./live-report.md > report.md

# Browser automation with live progress (--chrome is a Claude Code flag, passed through)
ai --chrome --live --skip test-flow.md

# Override script variables (--topic, --style match declared vars: names)
./summarize-topic.md --live --topic "the fall of rome" --style "peter griffin"

# Resume last conversation
ai --aws --resume

# Set a default provider+model for when you run 'ai' with no flags
ai --vercel --opus --set-default
ai --clear-default              # Remove saved default

# Enable agent teams (experimental, interactive only)
ai --team                        # Auto display mode
ai --aws --opus --team           # Teams with AWS Bedrock + Opus
ai --team --teammate-mode tmux   # Teams with tmux split panes
```

## Features

### Executable Markdown

Create markdown files with prompts that run directly via shebang:

```markdown
#!/usr/bin/env ai
Summarize the architecture of this codebase.
```

```markdown
#!/usr/bin/env -S ai --aws
Use AWS Bedrock to analyze this code.
```

```markdown
#!/usr/bin/env -S ai --opus --live
Review this PR for security issues. Stream output in real-time.
```

**Scripts that write files or run commands** need a permission mode:
```markdown
#!/usr/bin/env -S ai --skip
Run ./test/automation/run_tests.sh and report results.
```
(`--skip` is a shortcut for `--dangerously-skip-permissions`. See also `--bypass` for `--permission-mode bypassPermissions`.)

```markdown
#!/usr/bin/env -S ai --allowedTools 'Bash(npm test)' 'Read'
Run the test suite and report results. Do not modify any files.
```
(`--allowedTools` is a Claude Code flag, passed through by AI Runner.)

**Usage:**
```bash
chmod +x task.md
./task.md                          # Execute directly (uses shebang flags)
ai --vercel task.md                # Override: use Vercel instead
ai --opus task.md                  # Override: use Opus instead
```

> **Tip:** Use `#!/usr/bin/env -S` (with `-S`) to pass flags in the shebang line. Standard `env` only accepts one argument, so `#!/usr/bin/env ai --aws` won't work — you need `-S` to split the string.

> **Flag precedence:** CLI flags > shebang flags > saved defaults. Running `ai --vercel task.md` overrides the script's shebang provider. Shebang flags override `--set-default` preferences.

> **Passthrough flags:** AI Runner handles its own flags (provider, model, `--live`, `--quiet`, `--skip`, `--bypass`, `--team`, etc.) and forwards any unrecognized flags (e.g. `--chrome`, `--allowedTools`, `--output-format`, `--verbose`) to the underlying Claude Code process unchanged.

> **Warning:** `--skip`, `--bypass`, and `--permission-mode bypassPermissions` give the AI full system access. Only run trusted scripts in trusted directories. Use `--allowedTools` for granular control. See **[docs/SCRIPTING.md](docs/SCRIPTING.md)** for details.

See **[examples/](examples/)** for ready-to-run scripts and **[docs/SCRIPTING.md](docs/SCRIPTING.md)** for the full scripting & automation guide.

### Script Variables

Declare variables with defaults in YAML front-matter. Users override them from the CLI without editing the script:

```markdown
#!/usr/bin/env -S ai --haiku
---
vars:
  topic: "machine learning"
  style: casual
  length: short
---
Write a {{length}} summary of {{topic}} in a {{style}} tone.
```

```bash
./summarize-topic.md                          # uses defaults
./summarize-topic.md --topic "AI safety"      # overrides one
./summarize-topic.md --topic "robotics" --style formal  # overrides two
```

Variable overrides mix freely with AI Runner flags like `--live` and provider overrides:

```bash
./summarize-topic.md --live --length "100 words" --topic "the fall of rome" --style "peter griffin"
ai --aws --opus summarize-topic.md --topic "quantum computing"
```

Override flags matching declared var names are consumed — `--live`, `--aws`, and other unrecognized flags still pass through. Only activates when front-matter contains `vars:` — no behavior change for existing scripts.

### Unix Pipe Support

Executable markdown scripts have proper Unix semantics for automation:

- Clean piped output - when you redirect to a file, you get only the AI's response
- Stdin support - pipe data directly into scripts
- Chainable - connect scripts together in pipelines
- Standard streams - stdout is data, stderr is diagnostics

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

> **Composable scripts:** AIRun clears inherited environment variables between nested calls, so chained scripts each start fresh. See [docs/SCRIPTING.md](docs/SCRIPTING.md) for composable patterns, the dispatcher pattern (`--cc --skip`), and long-running script tips.

### Piped Script Execution

Run AI scripts directly from the web:

```bash
# Run a script from the web
curl -fsSL https://andisearch.github.io/ai-scripts/analyze.md | ai

# Simple prompt via pipe
echo "Explain what a Dockerfile does" | ai

# Override provider from shebang
curl -fsSL https://example.com/script.md | ai --aws
```

### Agent Teams (Experimental)

Enable [Claude Code's agent teams](https://code.claude.com/docs/en/agent-teams) — multiple Claude instances collaborating on shared tasks with one session as lead coordinating teammates.

```bash
ai --team                        # Enable agent teams
ai --aws --opus --team           # Combine with any provider
ai --team --teammate-mode tmux   # Split panes via tmux
```

| Flag | Purpose |
|------|---------|
| `--team` | **AI Runner flag** — enables agent teams by setting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` |
| `--teammate-mode <mode>` | **Claude Code native flag** — controls display: `in-process`, `tmux`, or `auto` (default) |

- Interactive mode only (not supported in shebang/piped script modes)
- Works with all providers — coordination is through Claude Code's internal task list, not provider-specific
- Token usage scales with team size (5 teammates ≈ 5× tokens)

## Providers

| Flag | Provider | Type | Notes |
|------|----------|------|-------|
| `--ollama` / `--ol` | Ollama | Local | Free, no API costs, cloud option |
| `--lmstudio` / `--lm` | LM Studio | Local | MLX models (fast on Apple Silicon) |
| `--aws` | AWS Bedrock | Cloud | Requires AWS credentials |
| `--vertex` | Google Vertex AI | Cloud | Requires GCP project |
| `--apikey` | Anthropic API | Cloud | Direct API access |
| `--azure` | Microsoft Azure | Cloud | Azure Foundry |
| `--vercel` | Vercel AI Gateway | Cloud | Any model: OpenAI, xAI, Google, Meta, more |
| `--pro` | Claude Pro | Subscription | Default if logged in |

### Quick Start Examples

```bash
# Local providers (free, no API costs)
ai --ollama                    # Ollama (GGUF models)
ai --lm                        # LM Studio (MLX/GGUF, fast on Apple Silicon)

# Cloud providers
ai --aws --opus task.md        # AWS Bedrock + Opus
ai --vertex task.md            # Google Vertex AI
ai --apikey task.md            # Anthropic API direct
```

### Provider Setup

#### Local Providers (Free, No API Keys)

> **Hardware note:** Coding models need 24GB+ VRAM (or unified memory on Apple Silicon). Ollama's cloud models work on any hardware.

**Ollama** — runs models locally or on Ollama's cloud:

```bash
# Install Ollama
brew install ollama                   # macOS
curl -fsSL https://ollama.com/install.sh | sh  # Linux / WSL

# Quick setup (Ollama 0.15+)
ollama launch claude                  # Auto-configure and launch Claude Code

# Or manual setup
ollama pull qwen3-coder               # Pull a model (needs 24GB+ VRAM)
ai --ollama                           # Run with Ollama

# Cloud models — no GPU required, runs on Ollama's servers
ollama pull minimax-m2.5:cloud        # Best coding (80% SWE-bench, MIT)
ollama pull glm-5:cloud               # Best reasoning (78% SWE-bench, MIT)
ai --ollama --model minimax-m2.5:cloud
```

**LM Studio** — local models with MLX support (fast on latest Apple Silicon):

```bash
# 1. Download from lmstudio.ai and load a model
# 2. Start the server: lms server start --port 1234
ai --lm                               # Run with LM Studio
```

See **[docs/PROVIDERS.md](docs/PROVIDERS.md)** for model recommendations, configuration, and auto-download features.

#### Cloud Providers

Add your credentials to `~/.ai-runner/secrets.sh` (created by `./setup.sh`). Andi AIRun loads this file automatically, so you don't need to set environment variables in your shell profile.

```bash
nano ~/.ai-runner/secrets.sh
```

Uncomment and fill in what you have:
```bash
# Anthropic API
export ANTHROPIC_API_KEY="sk-ant-..."

# AWS Bedrock
export AWS_PROFILE="your-profile-name"
export AWS_REGION="us-west-2"

# Google Vertex AI
export ANTHROPIC_VERTEX_PROJECT_ID="your-gcp-project-id"
export CLOUD_ML_REGION="global"

# Vercel AI Gateway
export VERCEL_AI_GATEWAY_TOKEN="vck_..."

# Microsoft Azure
export ANTHROPIC_FOUNDRY_API_KEY="your-azure-api-key"
export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
```

You only need to configure the providers you want to use. See **[docs/PROVIDERS.md](docs/PROVIDERS.md)** for all authentication options and detailed setup instructions.

## Switching Providers to Avoid Rate Limits

Claude Pro has rate limits. When you hit a limit mid-task, switch to your API keys and keep working.

```bash
# Working with Claude Pro, hit rate limit
claude
# "Rate limit exceeded. Try again in 4 hours 23 minutes."

# Immediately continue with AWS (keeps conversation context)
ai --aws --resume

# Or switch to Haiku for speed/cost, Opus for complex reasoning
ai --aws --haiku --resume
ai --aws --opus --resume

# Or use local Ollama (free!)
ai --ollama --resume
```

The `--resume` flag lets you pick up a previous conversation exactly where you left off.

## Installation

### Setup

```bash
git clone https://github.com/andisearch/airun.git
cd airun
./setup.sh
```

The setup script installs commands to `/usr/local/bin`, creates `~/.ai-runner/` for configuration, and migrates any existing `~/.claude-switcher/` configuration.

> **Note:** Setup does NOT modify your Claude configuration. All scripts are session-scoped and automatically restore your original configuration on exit.

### Updating

```bash
ai update
```

Or manually: `cd airun && git pull && ./setup.sh`

AI Runner checks for updates once every 24 hours (non-blocking, cache-only) and shows a notice in interactive mode and `ai-status` when a new version is available. Disable with `export AI_NO_UPDATE_CHECK=1`.

Your API keys in `~/.ai-runner/secrets.sh` are preserved.

### Updating from claude-switcher

If you have the original `claude-switcher` installed, just pull and re-run setup:

```bash
cd claude-switcher && git pull && ./setup.sh
```

GitHub's redirect ensures git operations continue working with the old remote URL.

**What happens automatically:**
- Your `~/.claude-switcher/secrets.sh` is migrated to `~/.ai-runner/secrets.sh`
- All legacy `claude-*` commands continue to work (see Backward Compatibility)
- Existing `#!/usr/bin/env claude-run` shebangs still work

**Optional cleanup:**
```bash
# Rename local directory
cd .. && mv claude-switcher airun && cd airun

# Update remote to canonical URL
git remote set-url origin https://github.com/andisearch/airun.git
```

**New commands:** `ai` / `airun` replace `claude-run` as the primary entry point.

### Uninstallation

```bash
./uninstall.sh
```

## Backward Compatibility

All legacy `claude-*` commands continue to work unchanged:

| Legacy Command | Equivalent |
|----------------|-----------|
| `claude-run` | `ai` |
| `claude-aws` | `ai --aws` |
| `claude-vertex` | `ai --vertex` |
| `claude-apikey` | `ai --apikey` |
| `claude-azure` | `ai --azure` |
| `claude-vercel` | `ai --vercel` |
| `claude-pro` | `ai --pro` |
| `claude-status` | `ai-status` |
| `claude-sessions` | `ai-sessions` |

Existing shebang scripts with `#!/usr/bin/env claude-run` still work.

Configuration in `~/.claude-switcher/` is automatically migrated to `~/.ai-runner/`.

## Configuration

### Models

Default model IDs are defined in `config/models.sh`. Override them in `~/.ai-runner/secrets.sh`:

```bash
# Override AWS model
export CLAUDE_MODEL_SONNET_AWS="global.anthropic.claude-sonnet-4-6"

# Override small/fast model for background operations
export CLAUDE_SMALL_FAST_MODEL_AWS="us.anthropic.claude-haiku-4-5-20251001-v1:0"

# Save preferred provider+model as default
ai --aws --opus --set-default
ai --clear-default              # Remove saved default
```

### Dual Model Configuration

Claude Code uses two models:

1. **`ANTHROPIC_MODEL`** - Main model for interactive work
2. **`ANTHROPIC_SMALL_FAST_MODEL`** - Background operations (defaults to Haiku)

## Troubleshooting

### Verify Configuration

```bash
ai-status                              # Shows authentication and configuration
```

### Common Issues

**Still getting rate limits after switching to API?**

1. Verify API key: `grep ANTHROPIC_API_KEY ~/.ai-runner/secrets.sh`
2. Confirm you're using `ai` (not plain `claude`)
3. Run `ai-status` during the session
4. In Claude, run `/status` to see authentication method

**Switching back to Pro not working?**

1. Use `ai --pro` or plain `claude`
2. Run `/status` in Claude to verify authentication

### Session-Scoped Behavior

`ai` with no flags uses your regular Claude subscription, identical to running `claude` directly. Provider flags (`--aws`, `--ollama`, etc.) only affect the current session:
- On exit, your original Claude settings are automatically restored
- Plain `claude` in another terminal is completely unaffected
- No global configuration is changed

## Versioning

**Current Version**: see [VERSION](VERSION) or run `ai --version`

This project follows [Semantic Versioning](https://semver.org/). See [CHANGELOG.md](CHANGELOG.md) for version history.

## Name History

Originally named **claude-switcher**, renamed to **Andi AIRun** in 2026. Previous URLs (`github.com/andisearch/claude-switcher`) redirect here automatically. Legacy configuration (`~/.claude-switcher/`) is still supported.

## Support

Andi AIRun is free and open source.

- **[Star on GitHub](https://github.com/andisearch/airun)** - helps others discover the project
- **[Buy Me a Coffee](https://buymeacoffee.com/andisearch)** - one-time support
- **[GitHub Sponsors](https://github.com/sponsors/andisearch)** - supports [Andi AI search](https://andisearch.com)

## Acknowledgments

Thanks to [Pete Koomen](https://x.com/koomen) from YC for the great idea of executable markdown! Pete's insight: executable prompts become reusable tools. Put them in your repo. Run them in CI. Chain them together.

Thanks to Reddit user [apf6](https://www.reddit.com/user/apf6/) for the suggestion to add a minimal alternative script for shebang support.

Thanks to the team at Anthropic for Claude Code and the fantastic Claude models. We are not associated with Anthropic.

Thanks to the Startups teams at Microsoft Azure, AWS and Google Cloud for their support.

## Authors

**Andi AIRun** is created and maintained by:
- **Jed White**, CTO of [Andi](https://andisearch.com)
- **Angela Hoover**, CEO of [Andi](https://andisearch.com)

Contributions welcome. See [CONTRIBUTORS.md](CONTRIBUTORS.md).

## License

MIT License. Copyright (c) 2025 LazyWeb Inc DBA Andi (https://andisearch.com).

See [LICENSE](LICENSE) for full license text.
