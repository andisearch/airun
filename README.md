# Andi AIRun

Run AI prompts like programs. Executable markdown with shebang, Unix pipes, and output redirection. Supports multiple runtimes (Claude Code, Codex CLI) with cross-cloud provider switching and any-model support — free local or 100+ cloud models.

```bash
# Claude Code: any model or provider
ai                                        # Regular Claude subscription (Pro, Max)
ai --aws --opus --team --resume           # Resume chats on AWS w/ Opus 4.6 + Agent Teams
ai --ollama --bypass --model qwen3-coder  # Ollama local model with bypassPermissions set

# Codex CLI: OpenAI's coding agent
ai --codex                                # Codex with gpt-5.4 (default)
ai --codex --high                         # Codex with gpt-5.4 (flagship)
ai --codex --ollama                       # Codex with local Ollama models

# Run prompts like programs (works with any runtime)
ai --azure --haiku script.md
ai --codex script.md

# Script automation
cat data.json | ./analyze.md > results.txt
```

Choose your runtime — [Claude Code](https://claude.ai/code) or [Codex CLI](https://developers.openai.com/codex/cli) — and switch between clouds + models: AWS Bedrock, Google Vertex, Azure, Vercel, Anthropic API, OpenAI API. Supports free local models ([Ollama](https://ollama.com/), [LM Studio](https://lmstudio.ai/)) and 100+ alternate cloud models via [Vercel AI Gateway](https://vercel.com/ai-gateway) or Ollama Cloud. Swap and resume conversations mid-task to avoid rate limits and keep working.

[![GitHub Stars](https://img.shields.io/github/stars/andisearch/airun?style=for-the-badge&logo=github)](https://github.com/andisearch/airun/stargazers)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support-yellow?logo=buy-me-a-coffee&style=for-the-badge)](https://buymeacoffee.com/andisearch)
[![Website](https://img.shields.io/badge/Website-airun.me-blue?style=for-the-badge&logo=safari)](https://airun.me)
[![Docs](https://img.shields.io/badge/Docs-docs.airun.me-green?style=for-the-badge&logo=readthedocs)](https://docs.airun.me)

**What it does:**
- **Multiple runtimes**: Claude Code and Codex CLI with a single `ai` command (`--cc`, `--codex`)
- Executable markdown with `#!/usr/bin/env ai` shebang for script automation
- Unix pipe support: pipe data into scripts, redirect output, chain in pipelines
- Cross-cloud provider switching: use Claude on AWS, Vertex, Azure, Anthropic API, or Codex on OpenAI, Azure OpenAI, OpenRouter + switch mid-conversation to bypass rate limits
- Model tiers: `--opus`/`--high`, `--sonnet`/`--mid`, `--haiku`/`--low` — maps to each runtime's models
- Cross-interpreter effort control: `--effort low|medium|high|max`
- Session continuity: `--resume` picks up your previous chats with any model/provider
- Non-destructive: plain `claude` and `codex` always work untouched as before

From [Andi AI Search](https://andisearch.com). [Star this repo](https://github.com/andisearch/airun) if it helps!

**Latest:** **Codex CLI support** (`--codex`), cross-interpreter effort levels (`--effort`), tool profiles (`--profile`). Script variables, live streaming, Agent Teams, Opus 4.6, local models (Ollama, LM Studio), persistent defaults, 100+ cloud models via Vercel. See [CHANGELOG.md](CHANGELOG.md).

## Quick Start

**Supported Platforms:**
- macOS 13.0+
- Linux (Ubuntu 20.04+, Debian 10+)
- Windows 10+ via WSL

**Prerequisites**: At least one runtime installed — [Claude Code](https://claude.ai/code) or [Codex CLI](https://developers.openai.com/codex/cli)

```bash
# Install a runtime (one or both)
curl -fsSL https://claude.ai/install.sh | bash   # Claude Code (Anthropic)
npm install -g @openai/codex                      # Codex CLI (OpenAI)

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

Running `ai` with no flags is equivalent to running `claude` directly — same auth, same model defaults, session-scoped. Your environment is passed through unmodified. Add provider flags to switch, or use `ai --aws --opus --set-default` to save your preferred provider and model for future runs.

> **Note:** If `ANTHROPIC_API_KEY` is set in your environment, `ai` will use it (matching native `claude -p` behavior). Use `ai --pro` to force subscription, or `ai --pro --set-default` to make it permanent.

### Usage Examples

```bash
# Run a markdown script (auto-detects runtime + provider)
ai task.md

# Choose your runtime
ai --cc                           # Claude Code (default if installed)
ai --codex                        # Codex CLI (OpenAI)

# Claude Code providers
ai --aws                          # AWS Bedrock
ai --vertex                       # Google Vertex AI
ai --apikey                       # Anthropic API
ai --azure                        # Microsoft Azure Foundry
ai --vercel                       # Vercel AI Gateway
ai --pro                          # Claude Pro/Max subscription

# Codex CLI providers
ai --codex                        # OpenAI API (default)
ai --codex --azure                # Azure OpenAI (via config.toml)
ai --codex --profile openrouter   # OpenRouter (via config.toml profile)

# Local models (work with both runtimes)
ai --ollama                       # Ollama with Claude Code
ai --codex --ollama               # Ollama with Codex CLI
ai --lmstudio                     # LM Studio (MLX, Apple Silicon)

# Model tiers (map to each runtime's best models)
ai --opus task.md                 # Claude: Opus 4.6 / Codex: gpt-5.4
ai --sonnet task.md               # Claude: Sonnet 4.6 / Codex: gpt-5.3-codex (mid tier)
ai --haiku task.md                # Claude: Haiku 4.5 / Codex: gpt-5.4-mini
ai --codex --high task.md         # Codex with gpt-5.4

# Effort level (cross-interpreter reasoning control)
ai --effort high task.md          # Claude Code: deeper reasoning
ai --codex --effort max task.md   # Codex: maximum reasoning (xhigh)

# Stream output in real-time
ai --live --skip task.md

# Suppress --live status for CI/CD (clean stdout only)
ai --quiet ./live-script.md > output.md

# Live output + file redirect (narration to console, clean content to file)
./live-report.md > report.md

# Override script variables (--topic, --style match declared vars: names)
./summarize-topic.md --live --topic "the fall of rome" --style "peter griffin"

# Resume last conversation
ai --aws --resume

# Save runtime + provider + model as default
ai --codex --high --set-default   # Always use Codex + gpt-5.4
ai --aws --opus --set-default     # Always use Claude Code + AWS + Opus
ai --clear-default                # Remove saved default

# Smart auto permissions (AI classifier for Claude Code, sandbox for Codex)
ai --auto task.md

# Enable agent teams (Claude Code, experimental, interactive only)
ai --team                         # Auto display mode
ai --aws --opus --team            # Teams with AWS Bedrock + Opus
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
#!/usr/bin/env -S ai --codex --high
Use Codex CLI with the flagship model to review this code.
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
#!/usr/bin/env -S ai --auto
Run tests and fix any issues found.
```
(`--auto` uses an AI classifier (Claude Code) or sandbox (Codex) to auto-approve safe actions.)

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

> **Passthrough flags:** AI Runner handles its own flags (provider, model, `--live`, `--quiet`, `--skip`, `--bypass`, `--auto`, `--team`, etc.) and forwards any unrecognized flags (e.g. `--chrome`, `--allowedTools`, `--output-format`, `--verbose`) to the underlying Claude Code process unchanged.

> **Portability:** Scripts are portable across runtimes. If a script includes interpreter-specific flags (e.g., `--chrome` for Claude Code), running it on another runtime produces a warning but continues execution.

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

Boolean flags — `--varname` without a value sets the variable to `"true"`:

```bash
# Given a script with vars: verbose: false
./script.md --verbose                         # sets verbose to "true"
./script.md --verbose --topic "AI safety"     # verbose="true", topic overridden
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

## Runtimes and Providers

### Runtimes

| Flag | Runtime | Default Model | Install |
|------|---------|---------------|---------|
| `--cc` | Claude Code | claude-opus-4-6 | `curl -fsSL https://claude.ai/install.sh \| bash` |
| `--codex` | Codex CLI | gpt-5.4 | `npm install -g @openai/codex` |

Claude Code is the default runtime when both are installed. If only Codex is installed, it becomes the default automatically.

### Providers

| Flag | Provider | Claude Code | Codex CLI | Type |
|------|----------|-------------|-----------|------|
| `--ollama` / `--ol` | Ollama | Yes | Yes | Local |
| `--lmstudio` / `--lm` | LM Studio | Yes | Yes | Local |
| `--aws` | AWS Bedrock | Yes | — | Cloud |
| `--vertex` | Google Vertex AI | Yes | — | Cloud |
| `--apikey` | Anthropic / OpenAI API | Yes | Yes | Cloud |
| `--azure` | Azure Foundry / Azure OpenAI | Yes | Yes | Cloud |
| `--vercel` | Vercel AI Gateway | Yes | — | Cloud |
| `--pro` | Claude Pro | Yes | — | Subscription |
| `--profile <name>` | Config profile | — | Yes | Any |

Codex custom providers (OpenRouter, Mistral, DeepSeek, etc.) are configured in `~/.codex/config.toml` and selected with `--profile <name>`. See the [Codex CLI docs](https://developers.openai.com/codex/cli) for config.toml setup.

### Quick Start Examples

```bash
# Local providers (free, no API costs — work with both runtimes)
ai --ollama                    # Claude Code + Ollama
ai --codex --ollama            # Codex CLI + Ollama

# Claude Code cloud providers
ai --aws --opus task.md        # AWS Bedrock + Opus 4.6
ai --vertex task.md            # Google Vertex AI

# Codex CLI cloud providers
ai --codex task.md             # OpenAI API + gpt-5.4
ai --codex --azure task.md     # Azure OpenAI (config.toml)
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
# Override Claude Code AWS model
export CLAUDE_MODEL_SONNET_AWS="global.anthropic.claude-sonnet-4-6"

# Override Codex model tiers
export CODEX_MODEL_HIGH="gpt-5.4"
export CODEX_MODEL_MID="gpt-5.3-codex"
export CODEX_MODEL_LOW="gpt-5.4-mini"

# Save preferred runtime + provider + model as default
ai --codex --high --set-default
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

`ai` with no flags matches your system `claude` configuration — same auth method and model defaults as running `claude` directly. Provider flags (`--aws`, `--ollama`, etc.) only affect the current session:
- On exit, your original Claude settings are automatically restored
- Plain `claude` in another terminal is completely unaffected
- No global configuration is changed
- If `ANTHROPIC_API_KEY` is in your environment, `ai` uses it (matching `claude -p`). Use `ai --pro` to force subscription.

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
