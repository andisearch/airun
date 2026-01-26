# AI Runner

Universal prompt interpreter for AI coding agents.

Execute markdown prompts as shell scripts. Currently extends [Claude Code](https://claude.ai/code) with multi-provider support.

[![GitHub Stars](https://img.shields.io/github/stars/andisearch/airun?style=for-the-badge&logo=github)](https://github.com/andisearch/airun/stargazers)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-Support-yellow?logo=buy-me-a-coffee&style=for-the-badge)](https://buymeacoffee.com/andisearch)

**What it does:**
- Executable markdown with `#!/usr/bin/env ai` shebang for script automation
- Unix pipe support: pipe data into scripts, redirect output, chain in pipelines
- Provider switching: bypass rate limits with Ollama (local/free), AWS, Vertex, Azure, Vercel, Anthropic API
- Model tiers: `--opus`/`--high`, `--sonnet`/`--mid`, `--haiku`/`--low`
- Session continuity: `--resume` picks up your last conversation on any provider
- Non-destructive: plain `claude` always works as before

From [Andi AI Search](https://andisearch.com). [Star this repo](https://github.com/andisearch/airun) if it helps!

## Quick Start

**Supported Platforms:**
- macOS 13.0+
- Linux (Ubuntu 20.04+, Debian 10+)
- Windows 10+ via WSL

**Prerequisites**: [Claude Code](https://claude.ai/code) (Anthropic's AI coding CLI) installed

```bash
# Install Claude Code (if not already installed)
curl -fsSL https://claude.ai/install.sh | bash

# Install AI Runner
git clone https://github.com/andisearch/airun.git
cd airun && ./setup.sh
```

**That's it!** You can now run any markdown file as an AI script:

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
| `ai-sessions` | View active AI coding sessions |
| `ai-status` | Show current configuration and provider status |

### Usage Examples

```bash
# Run a markdown script
ai task.md

# Interactive mode with provider
ai --aws                          # AWS Bedrock
ai --vertex                       # Google Vertex AI
ai --ollama                       # Ollama (local, free)
ai --apikey                       # Anthropic API
ai --azure                        # Microsoft Azure
ai --vercel                       # Vercel AI Gateway
ai --pro                          # Claude Pro/Max subscription

# Model selection (Pro defaults to Opus, API providers default to Sonnet)
ai --opus task.md                 # Opus 4.5 (most capable)
ai --sonnet task.md               # Sonnet 4.5
ai --haiku task.md                # Haiku 4.5 (fastest)

# Alternative tier names
ai --high task.md                 # Same as --opus
ai --mid task.md                  # Same as --sonnet
ai --low task.md                  # Same as --haiku

# Resume last conversation
ai --aws --resume
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
#!/usr/bin/env -S ai --opus --output-format stream-json
Review this PR for security issues. Stream output in real-time.
```

```markdown
#!/usr/bin/env -S ai --permission-mode bypassPermissions
Run ./test/automation/run_tests.sh and report results.
```

**Usage:**
```bash
chmod +x task.md
./task.md                          # Execute directly (uses shebang flags)
ai --vercel task.md                # Override: use Vercel instead
ai --opus task.md                  # Override: use Opus instead
```

> **Tip:** Use `#!/usr/bin/env -S` (with `-S`) to pass multiple flags in the shebang line.

> **Warning:** Executable markdown runs AI-generated code without approval (like `claude -p`). Only run trusted prompts in trusted directories.

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

## Providers

### Currently Implemented

| Flag | Provider | Notes |
|------|----------|-------|
| `--ollama` | Ollama (local) | Free, no API costs, runs locally |
| `--aws` | AWS Bedrock | Requires AWS credentials |
| `--vertex` | Google Vertex AI | Requires GCP project |
| `--apikey` | Anthropic API | Direct API access |
| `--azure` | Microsoft Azure | Azure Foundry |
| `--vercel` | Vercel AI Gateway | Unified billing |
| `--pro` | Claude Pro | Subscription-based (default) |

### Coming Soon

| Flag | Provider | Notes |
|------|----------|-------|
| `--openrouter` / `--or` | OpenRouter | 500+ models, single API key |
| `--lmstudio` | LM Studio | Local OpenAI-compatible |
| `--openai` | Generic OpenAI | Any OpenAI-compatible endpoint |

### Provider Setup

Configure providers by adding credentials to `~/.ai-runner/secrets.sh`:

```bash
nano ~/.ai-runner/secrets.sh
```

#### Ollama (Local or Cloud)

Ollama runs models locally (free) or on Ollama's cloud (no GPU needed).

**Install Ollama:**
```bash
# macOS
brew install ollama

# Linux / Windows (WSL)
curl -fsSL https://ollama.com/install.sh | sh
```

##### Quick Setup (Recommended)

Ollama 0.15+ can auto-configure Claude Code:

```bash
ollama launch claude          # Interactive setup, picks model, launches Claude
ollama launch claude --config # Configure only, don't launch
```

##### Cloud Models (No GPU Required)

Cloud models run on Ollama's infrastructure. Pull the manifest first:

```bash
ollama pull glm-4.7:cloud            # Tiny download, runs remotely
ai --ollama --model glm-4.7:cloud
```

| Cloud Model | Description |
|-------------|-------------|
| `glm-4.7:cloud` | High-performance, 128K context, tool-calling |
| `minimax-m2.1:cloud` | Fast responses, good for iteration |

See [Ollama cloud models](https://ollama.com/search?c=cloud) for full list.

##### Local Models (Free, Private)

```bash
ollama pull qwen3-coder   # Coding optimized (needs 24GB VRAM)
ollama pull glm-4.7       # 128K context, tool-calling
ai --ollama
```

**Recommended:** `qwen3-coder`, `glm-4.7`, `gpt-oss:20b`

##### Model Aliases

Create aliases for tools expecting Anthropic model names:

```bash
ollama cp qwen3-coder claude-sonnet-4-5-20250514
ai --ollama --model claude-sonnet-4-5-20250514
```

##### Configuration

**Override defaults** in `~/.ai-runner/secrets.sh`:
```bash
export OLLAMA_MODEL_MID="qwen3-coder"        # Default model
export OLLAMA_SMALL_FAST_MODEL="gemma3"      # Background model (24GB+ VRAM)
```

> **Note:** By default, Ollama uses the same model for both main and background operations to avoid VRAM swapping.

See [Ollama Anthropic API compatibility](https://docs.ollama.com/api/anthropic-compatibility) for details.

#### AWS Bedrock

```bash
export AWS_PROFILE="your-profile-name"
export AWS_REGION="us-west-2"
```

See [AWS Bedrock setup](https://code.claude.com/docs/en/amazon-bedrock) for all auth options.

#### Google Vertex AI

```bash
export ANTHROPIC_VERTEX_PROJECT_ID="your-gcp-project-id"
export CLOUD_ML_REGION="global"
```

See [Vertex AI setup](https://code.claude.com/docs/en/google-vertex-ai) for authentication methods.

#### Anthropic API

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

#### Microsoft Azure

```bash
export ANTHROPIC_FOUNDRY_API_KEY="your-azure-api-key"
export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
```

See [Microsoft Foundry setup](https://code.claude.com/docs/en/microsoft-foundry) for details.

#### Vercel AI Gateway

```bash
export VERCEL_AI_GATEWAY_TOKEN="vck_..."
export VERCEL_AI_GATEWAY_URL="https://ai-gateway.vercel.sh"  # Optional
```

## Tools

### Currently Supported

- **Claude Code** (`--tool cc`) - Anthropic's official coding CLI (default)

### Coming Soon

- **OpenCode** (`--tool opencode`) - Open-source Go-based alternative
- **Aider** (`--tool aider`) - Git-aware multi-file AI pair programming
- **Codex CLI** (`--tool codex`) - OpenAI's Rust-based coding CLI
- **Gemini CLI** (`--tool gemini`) - Google's TypeScript CLI

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
cd airun && git pull && ./setup.sh
```

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
export CLAUDE_MODEL_SONNET_AWS="global.anthropic.claude-sonnet-4-5-20250929-v1:0"

# Override small/fast model for background operations
export CLAUDE_SMALL_FAST_MODEL_AWS="us.anthropic.claude-haiku-4-5-20251001-v1:0"
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

All wrapper scripts are session-scoped:
- Changes only affect the active session
- On exit, original settings automatically restore
- Plain `claude` always runs in native state

## Versioning

**Current Version**: see [VERSION](VERSION) or run `ai --version`

This project follows [Semantic Versioning](https://semver.org/). See [CHANGELOG.md](CHANGELOG.md) for version history.

## Name History

This project was originally named **claude-switcher** and has been renamed to **AI Runner** (repo: `airun`).

- **2025**: Started as "Claude Switcher" - a tool to switch between Claude Code providers
- **2026**: Renamed to "AI Runner" - reflecting expanded scope (executable markdown, multi-tool support)

If you found this project searching for "claude-switcher", you're in the right place!

Previous URLs automatically redirect:
- `github.com/andisearch/claude-switcher` → `github.com/andisearch/airun`

Legacy configuration (`~/.claude-switcher/`) is still supported for backward compatibility.

## Support

AI Runner is free and open source.

- **[Star on GitHub](https://github.com/andisearch/airun)** - helps others discover the project
- **[Buy Me a Coffee](https://buymeacoffee.com/andisearch)** - one-time support
- **[GitHub Sponsors](https://github.com/sponsors/andisearch)** - supports [Andi AI search](https://andisearch.com)

## Acknowledgments

Thanks to [Pete Koomen](https://x.com/koomen) from YC for the great idea of executable markdown! Pete's insight: executable prompts become reusable tools. Put them in your repo. Run them in CI. Chain them together.

Thanks to Reddit user [apf6](https://www.reddit.com/user/apf6/) for the suggestion to add a minimal alternative script for shebang support.

Thanks to the team at Anthropic for Claude Code and the fantastic Claude models. We are not associated with Anthropic.

Thanks to the Startups teams at Microsoft Azure, AWS and Google Cloud for their support.

## Authors

**AI Runner** is created and maintained by:
- **Jed White**, CTO of [Andi](https://andisearch.com)
- **Angela Hoover**, CEO of [Andi](https://andisearch.com)

Contributions welcome. See [CONTRIBUTORS.md](CONTRIBUTORS.md).

## License

MIT License. Copyright (c) 2025 LazyWeb Inc DBA Andi (https://andisearch.com).

See [LICENSE](LICENSE) for full license text.
