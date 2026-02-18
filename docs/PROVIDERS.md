# Provider Setup Guide

This guide covers detailed setup instructions for each AI provider supported by Andi AIRun.

## How to Configure

All provider credentials go in **one file**: `~/.ai-runner/secrets.sh`

This file is created automatically by `./setup.sh` from the `secrets.example.sh` template. Edit it to add your credentials:

```bash
nano ~/.ai-runner/secrets.sh
```

AI Runner loads this file at startup. You don't need to set environment variables in your shell profile or `.bashrc` — just add them to secrets.sh, and then switch providers freely with `ai --aws`, `ai --vertex`, etc.

> **Tip:** You only need to configure the providers you want to use. Configure multiple providers to switch between them when you hit rate limits, or want to use different models.

## Quick Reference

| Flag | Provider | Type | Notes |
|------|----------|------|-------|
| `--ollama` / `--ol` | Ollama | Local | Free, no API costs, cloud option |
| `--lmstudio` / `--lm` | LM Studio | Local | MLX models (fast on Apple Silicon) |
| `--aws` | AWS Bedrock | Cloud | Requires AWS credentials |
| `--vertex` | Google Vertex AI | Cloud | Requires GCP project |
| `--apikey` | Anthropic API | Cloud | Direct API access |
| `--azure` | Microsoft Azure | Cloud | Azure Foundry |
| `--vercel` | Vercel AI Gateway | Cloud | Any model: Anthropic,OpenAI, xAI, Google, Meta, more |
| `--pro` | Claude Pro | Subscription | Default if logged in |

**Agent Teams:** All providers support agent teams (`ai --team`). Coordination uses Claude Code's internal task list and mailbox, not provider-specific features. See [Claude Code Agent Teams docs](https://code.claude.com/docs/en/agent-teams).

---

## Local Providers

> **Hardware requirements:** Running local models requires significant RAM/VRAM. Capable coding models (30B+ parameters) need 24GB+ VRAM or unified memory (Apple Silicon M2 Pro/Max and above). Smaller models run on less hardware but may struggle with complex coding tasks. If your system is limited, Ollama's cloud models are an excellent free alternative — they run on Ollama's servers with no local GPU needed.

### Ollama (Local or Cloud)

Ollama runs models locally (free) or on Ollama's cloud (no GPU needed).

**Install Ollama:**
```bash
# macOS
brew install ollama

# Linux / Windows (WSL)
curl -fsSL https://ollama.com/install.sh | sh
```

#### Quick Setup (Recommended)

Ollama 0.15+ can auto-configure Claude Code:

```bash
ollama launch claude          # Interactive setup, picks model, launches Claude
ollama launch claude --config # Configure only, don't launch
```

#### Cloud Models (No GPU Required)

Cloud models run on Ollama's infrastructure — ideal if your system doesn't have enough VRAM for local models. Pull the manifest first (tiny download, the model runs remotely):

```bash
ollama pull minimax-m2.5:cloud       # Tiny download, runs remotely
ai --ollama --model minimax-m2.5:cloud
```

| Cloud Model | SWE-bench | Params (active) | Best For |
|-------------|-----------|-----------------|----------|
| `minimax-m2.5:cloud` | 80.2% | 230B MoE (10B) | Coding, agentic workflows (MIT) |
| `glm-5:cloud` | 77.8% | 744B MoE (40B) | Reasoning, math, knowledge (MIT) |

See [Ollama cloud models](https://ollama.com/search?c=cloud) for full list.

#### Local Models (Free, Private)

Local models require sufficient VRAM — 24GB+ recommended for capable coding models.

```bash
ollama pull qwen3-coder   # Coding optimized (needs 24GB+ VRAM)
ai --ollama
```

**Recommended:** `qwen3-coder`, `gpt-oss:20b`

#### Model Aliases

Create aliases for tools expecting Anthropic model names:

```bash
ollama cp qwen3-coder claude-sonnet-4-6
ai --ollama --model claude-sonnet-4-6
```

#### Configuration

**Override defaults** in `~/.ai-runner/secrets.sh`:
```bash
export OLLAMA_MODEL_MID="qwen3-coder"        # Default model
export OLLAMA_SMALL_FAST_MODEL="gemma3"      # Background model (24GB+ VRAM)
```

> **Note:** By default, Ollama uses the same model for both main and background operations to avoid VRAM swapping.

#### Auto-Download

When you specify a model that isn't installed locally, AI Runner offers a choice between local and cloud:

```bash
ai --ollama --model qwen3-coder
# Model 'qwen3-coder' not found locally.
#
# Your system has ~32GB usable VRAM.
#
# Options:
#   1) Pull local version (recommended) - qwen3-coder
#   2) Use cloud version - qwen3-coder:cloud
#
# Choice [1]: 1
# Pulling model: qwen3-coder
# [##################################################] 100%
# Model pulled successfully
```

For systems with limited VRAM (< 20GB), cloud is recommended first.

See [Ollama Anthropic API compatibility](https://docs.ollama.com/api/anthropic-compatibility) for details.

---

### LM Studio (Local)

LM Studio runs local models with Anthropic API compatibility. Especially powerful on Apple Silicon with MLX models. Requires sufficient RAM/VRAM for the model you choose.

**Advantages over Ollama:**
- MLX model support (significantly faster on Apple Silicon)
- GGUF + MLX formats supported
- Bring your own models from HuggingFace

**Install LM Studio:**
Download from [lmstudio.ai](https://lmstudio.ai)

#### Setup

1. **Download a model** in LM Studio (e.g., from HuggingFace)
2. **Load the model** in LM Studio UI
3. **Start the server:**
   ```bash
   lms server start --port 1234
   ```
   Or start from the LM Studio app's local server tab.

4. **Run AI Runner:**
   ```bash
   ai --lmstudio
   # or
   ai --lm
   ```

#### Recommended Models

For Claude Code, use models with:
- 25K+ context window (required for Claude Code's heavy context usage)
- Function calling / tool use support

Examples:
- `openai/gpt-oss-20b` - Strong general-purpose
- `ibm/granite-4-micro` - Fast, efficient

#### Apple Silicon Optimization

LM Studio supports MLX models which are significantly faster than GGUF on M1/M2/M3/M4 chips. When downloading models, look for MLX versions for best performance.

#### Configuration

**Override defaults** in `~/.ai-runner/secrets.sh`:
```bash
export LMSTUDIO_HOST="http://localhost:1234"     # Custom server URL
export LMSTUDIO_MODEL_MID="openai/gpt-oss-20b"   # Default model
export LMSTUDIO_MODEL_HIGH="openai/gpt-oss-20b"  # High tier model
export LMSTUDIO_MODEL_LOW="ibm/granite-4-micro"  # Low tier model
```

> **Note:** By default, LM Studio uses the same model for all tiers and background operations to avoid model swapping.

#### Context Window

Configure context size in LM Studio:
- UI: Settings → Context Length
- Minimum recommended: 25K tokens
- Higher is better for complex coding tasks

#### Auto-Download

When you specify a model that isn't available, AI Runner will offer to download it:

```bash
ai --lm --model lmstudio-community/qwen3-8b-gguf
# Model 'lmstudio-community/qwen3-8b-gguf' not found in LM Studio.
# Download it? [Y/n]: y
# Downloading model: lmstudio-community/qwen3-8b-gguf
# Progress: 100.0%
# Model downloaded successfully
# Load it now? [Y/n]: y
# Model loaded
```

See [LM Studio Claude Code guide](https://lmstudio.ai/blog/claudecode) for details.

---

## Cloud Providers

### AWS Bedrock

Add to `~/.ai-runner/secrets.sh`:
```bash
export AWS_PROFILE="your-profile-name"
export AWS_REGION="us-west-2"
```

**Usage:**
```bash
ai --aws
ai --aws --opus task.md
```

See [AWS Bedrock setup](https://code.claude.com/docs/en/amazon-bedrock) for all auth options including:
- AWS profiles
- Access keys
- IAM roles
- Bearer tokens

---

### Google Vertex AI

Add to `~/.ai-runner/secrets.sh`:
```bash
export ANTHROPIC_VERTEX_PROJECT_ID="your-gcp-project-id"
export CLOUD_ML_REGION="global"
```

**Usage:**
```bash
ai --vertex
ai --vertex --opus task.md
```

See [Vertex AI setup](https://code.claude.com/docs/en/google-vertex-ai) for authentication methods.

---

### Anthropic API

Add to `~/.ai-runner/secrets.sh`:
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

**Usage:**
```bash
ai --apikey
ai --apikey --opus task.md
```

---

### Microsoft Azure

Add to `~/.ai-runner/secrets.sh`:
```bash
export ANTHROPIC_FOUNDRY_API_KEY="your-azure-api-key"
export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
```

**Usage:**
```bash
ai --azure
ai --azure --opus task.md
```

See [Microsoft Foundry setup](https://code.claude.com/docs/en/microsoft-foundry) for details.

---

### Vercel AI Gateway

Add to `~/.ai-runner/secrets.sh`:
```bash
export VERCEL_AI_GATEWAY_TOKEN="vck_..."
export VERCEL_AI_GATEWAY_URL="https://ai-gateway.vercel.sh"  # Optional
```

**Usage:**
```bash
ai --vercel
ai --vercel --opus task.md
```

#### Use Any Model

Vercel AI Gateway supports 100+ models from OpenAI, xAI, Google, Meta, Anthropic, Mistral, DeepSeek, and more — all through one API. Use `--model provider/model` to run Claude Code with any supported model:

```bash
ai --vercel --model xai/grok-code-fast-1         # xAI coding model
ai --vercel --model openai/gpt-5.2-codex         # OpenAI coding model
ai --vercel --model google/gemini-3-pro-preview   # Google reasoning model
ai --vercel --model alibaba/qwen3-coder           # Alibaba coding model
ai --vercel --model zai/glm-5                     # Zhipu AI GLM-5 198K context
```

**Example coding models:**

| Model ID | Provider | Description |
|----------|----------|-------------|
| `xai/grok-code-fast-1` | xAI | Fast coding model |
| `openai/gpt-5.2-codex` | OpenAI | Coding-optimized GPT (also `openai/gpt-5.3-codex`) |
| `google/gemini-3-pro-preview` | Google | Latest reasoning model |
| `alibaba/qwen3-coder` | Alibaba | Open-source coding model |
| `zai/glm-5` | Zhipu AI | GLM-5, 198K context, MIT license |

Browse all available models: [vercel.com/ai-gateway/models](https://vercel.com/ai-gateway/models)

#### Configuration

**Override defaults** in `~/.ai-runner/secrets.sh`:
```bash
# Use a non-Anthropic model as default for Vercel
export CLAUDE_MODEL_SONNET_VERCEL="xai/grok-code-fast-1"

# Set a specific background/small-fast model
export CLAUDE_SMALL_FAST_MODEL_VERCEL="xai/grok-code-fast-1"
```

**Automatic small/fast model:** When you use `--model` with a non-Anthropic model (e.g., `xai/grok-code-fast-1`), the background model is automatically set to the same model. This avoids mixing providers (e.g., xAI for main work + Anthropic for background). For Anthropic models on Vercel, the background model defaults to Haiku as usual.

**Set as default provider:**
```bash
ai --vercel --model xai/grok-code-fast-1 --set-default
ai --clear-default
```

---

## Subscription Provider

### Claude Pro

Uses your Claude Pro/Max subscription. No API keys needed.

**Prerequisites:**
- Claude Code installed
- Logged in with Claude subscription (`claude login`)

**Usage:**
```bash
ai --pro
ai --pro --opus task.md
```

This is the default provider if you're logged into Claude Code with a subscription.

---

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

# Or use local LM Studio
ai --lm --resume
```

The `--resume` flag lets you pick up a previous conversation exactly where you left off.

---

## Session-Scoped Behavior

All wrapper scripts are session-scoped:
- Changes only affect the active terminal session
- On exit, original settings automatically restore
- Plain `claude` always runs in native state
- Running `claude` in another terminal is unaffected

This means you can safely run `ai --lmstudio` in one terminal while using `claude` normally in another.
