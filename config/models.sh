#!/bin/bash

# Model Configuration
# This file defines default model identifiers for each provider.
# You can override these in ~/.ai-runner/secrets.sh (or legacy ~/.claude-switcher/secrets.sh)
#
# IMPORTANT: Per official Claude Code documentation, the runtime uses:
#   - ANTHROPIC_MODEL (primary model)
#   - ANTHROPIC_SMALL_FAST_MODEL (for Haiku/fast operations)
#
# This file defines provider-specific defaults that our scripts use to
# SET those runtime variables based on which provider is active.

# AWS Bedrock Model Defaults
# See: https://code.claude.com/docs/en/amazon-bedrock#4-model-configuration
# Official defaults from Claude Code docs:
#   Primary: global.anthropic.claude-sonnet-4-6
#   Small/fast: us.anthropic.claude-haiku-4-5-20251001-v1:0
# To pin a specific dated version, override in secrets.sh (e.g., claude-opus-4-6-20260205)
export CLAUDE_MODEL_SONNET_AWS="${CLAUDE_MODEL_SONNET_AWS:-global.anthropic.claude-sonnet-4-6}"
export CLAUDE_MODEL_OPUS_AWS="${CLAUDE_MODEL_OPUS_AWS:-global.anthropic.claude-opus-4-6-v1}"
export CLAUDE_MODEL_HAIKU_AWS="${CLAUDE_MODEL_HAIKU_AWS:-us.anthropic.claude-haiku-4-5-20251001-v1:0}"

# Google Vertex AI Model Defaults
# See: https://code.claude.com/docs/en/google-vertex-ai#5-model-configuration
# Official example from docs:
#   ANTHROPIC_MODEL='claude-opus-4-6'
#   ANTHROPIC_SMALL_FAST_MODEL='claude-haiku-4-5@20251001'
export CLAUDE_MODEL_SONNET_VERTEX="${CLAUDE_MODEL_SONNET_VERTEX:-claude-sonnet-4-6}"
export CLAUDE_MODEL_OPUS_VERTEX="${CLAUDE_MODEL_OPUS_VERTEX:-claude-opus-4-6}"
export CLAUDE_MODEL_HAIKU_VERTEX="${CLAUDE_MODEL_HAIKU_VERTEX:-claude-haiku-4-5@20251001}"

# Anthropic API Model Defaults
# See: https://docs.anthropic.com/
# Standard model IDs without provider prefix
# To pin a specific dated version, override in secrets.sh (e.g., claude-opus-4-6-20260205)
export CLAUDE_MODEL_SONNET_ANTHROPIC="${CLAUDE_MODEL_SONNET_ANTHROPIC:-claude-sonnet-4-6}"
export CLAUDE_MODEL_OPUS_ANTHROPIC="${CLAUDE_MODEL_OPUS_ANTHROPIC:-claude-opus-4-6}"
export CLAUDE_MODEL_HAIKU_ANTHROPIC="${CLAUDE_MODEL_HAIKU_ANTHROPIC:-claude-haiku-4-5}"

# Microsoft Foundry on Azure Model Defaults
# See: https://code.claude.com/docs/en/microsoft-foundry
# Model names are deployment names (user-defined in Azure portal)
# These are just suggested defaults - users must set their actual deployment names
export CLAUDE_MODEL_SONNET_AZURE="${CLAUDE_MODEL_SONNET_AZURE:-claude-sonnet-4-6}"
export CLAUDE_MODEL_OPUS_AZURE="${CLAUDE_MODEL_OPUS_AZURE:-claude-opus-4-6}"
export CLAUDE_MODEL_HAIKU_AZURE="${CLAUDE_MODEL_HAIKU_AZURE:-claude-haiku-4-5}"

# Vercel AI Gateway Model Defaults
# See: https://vercel.com/ai-gateway
# Uses format: anthropic/model-name (no date suffix)
export CLAUDE_MODEL_SONNET_VERCEL="${CLAUDE_MODEL_SONNET_VERCEL:-anthropic/claude-sonnet-4.6}"
export CLAUDE_MODEL_OPUS_VERCEL="${CLAUDE_MODEL_OPUS_VERCEL:-anthropic/claude-opus-4.6}"
export CLAUDE_MODEL_HAIKU_VERCEL="${CLAUDE_MODEL_HAIKU_VERCEL:-anthropic/claude-haiku-4.5}"

# Ollama Model Defaults (Local + Cloud)
# See: https://docs.ollama.com/integrations/claude-code
#
# By default, AI Runner auto-detects available Ollama models.
# To override auto-detection, uncomment and set specific models:
#
# Local models (64K+ context, 24GB+ VRAM):
#   export OLLAMA_MODEL_HIGH="qwen3:72b"            # For --opus/--high
#   export OLLAMA_MODEL_MID="qwen3-coder"           # For --sonnet/--mid
#   export OLLAMA_MODEL_LOW="gemma3"                # For --haiku/--low
#
# Cloud models (no GPU required, 198K context):
#   export OLLAMA_MODEL_HIGH="minimax-m2.5:cloud"   # 80% SWE-bench, best coding (MIT)
#   export OLLAMA_MODEL_MID="glm-5:cloud"           # 78% SWE-bench, strong reasoning (MIT)
#   export OLLAMA_MODEL_LOW="glm-5:cloud"           # Same — no small cloud model yet

# OpenRouter Model Defaults
# See: https://openrouter.ai
# Uses format: provider/model-name (with dots like 4.5, not dashes)
export ROUTER_MODEL_HIGH="${ROUTER_MODEL_HIGH:-anthropic/claude-opus-4.6}"
export ROUTER_MODEL_MID="${ROUTER_MODEL_MID:-anthropic/claude-sonnet-4.6}"
export ROUTER_MODEL_LOW="${ROUTER_MODEL_LOW:-anthropic/claude-haiku-4.5}"

# LM Studio Model Defaults (Local)
# See: https://lmstudio.ai/blog/claudecode
#
# Models use format: provider/model-name
# Example: openai/gpt-oss-20b, ibm/granite-4-micro
#
# By default, AI Runner uses the first loaded model for ALL tiers.
# (Same model for all tiers avoids model swapping overhead)
#
# To use different models per tier, set in ~/.ai-runner/secrets.sh:
#   export LMSTUDIO_MODEL_HIGH="openai/gpt-oss-20b"
#   export LMSTUDIO_MODEL_MID="openai/gpt-oss-20b"
#   export LMSTUDIO_MODEL_LOW="ibm/granite-4-micro"
#
# APPLE SILICON USERS: LM Studio supports MLX models which are
# significantly faster than GGUF on M1/M2/M3/M4 chips.
#
# IMPORTANT: LM Studio recommends 25K+ context for Claude Code.
# Configure context size in LM Studio UI or via API parameters.

# Small/Fast Model Defaults (for background operations)
# These are used by Claude Code for sub-agents, file operations, and auxiliary tasks
# Default to Haiku for each provider but can be overridden in secrets.sh
export CLAUDE_SMALL_FAST_MODEL_AWS="${CLAUDE_SMALL_FAST_MODEL_AWS:-${CLAUDE_MODEL_HAIKU_AWS}}"
export CLAUDE_SMALL_FAST_MODEL_VERTEX="${CLAUDE_SMALL_FAST_MODEL_VERTEX:-${CLAUDE_MODEL_HAIKU_VERTEX}}"
export CLAUDE_SMALL_FAST_MODEL_ANTHROPIC="${CLAUDE_SMALL_FAST_MODEL_ANTHROPIC:-${CLAUDE_MODEL_HAIKU_ANTHROPIC}}"
export CLAUDE_SMALL_FAST_MODEL_AZURE="${CLAUDE_SMALL_FAST_MODEL_AZURE:-${CLAUDE_MODEL_HAIKU_AZURE}}"
export CLAUDE_SMALL_FAST_MODEL_VERCEL="${CLAUDE_SMALL_FAST_MODEL_VERCEL:-${CLAUDE_MODEL_HAIKU_VERCEL}}"

# ============================================================================
# DUAL MODEL CONFIGURATION
# ============================================================================
#
# Claude Code uses TWO distinct models for optimal performance:
#
# 1. ANTHROPIC_MODEL - The primary model you interact with
#    - Used for main conversation and complex reasoning
#    - Can be Sonnet, Opus, or Haiku based on your needs
#    - Set by your --sonnet, --opus, --haiku flags or --model override
#
# 2. ANTHROPIC_SMALL_FAST_MODEL - The background/auxiliary model
#    - Used for sub-agents, file operations, and quick tasks
#    - Configured via CLAUDE_SMALL_FAST_MODEL_{PROVIDER} variables
#    - Defaults to Haiku but can be overridden in secrets.sh
#    - Reduces costs for background operations
#
# AUTOMATIC CONFIGURATION:
# Our scripts automatically set ANTHROPIC_SMALL_FAST_MODEL based on the
# CLAUDE_SMALL_FAST_MODEL_{PROVIDER} variable for the active provider.
# These default to each provider's Haiku model but can be overridden.
#
# MANUAL OVERRIDE:
# To use a different small/fast model for a provider, set the appropriate
# variable in ~/.ai-runner/secrets.sh:
#   export CLAUDE_SMALL_FAST_MODEL_AWS="your-custom-model-id"
#   export CLAUDE_SMALL_FAST_MODEL_VERTEX="your-custom-model-id"
#
# See: https://code.claude.com/docs/en/model-config#environment-variables

# ============================================================================
# IMPLEMENTATION NOTES
# ============================================================================
# 
# Our scripts (claude-aws, claude-vertex, etc.) use the CLAUDE_MODEL_* variables
# above to SET the ANTHROPIC_MODEL environment variable that Claude Code actually
# uses at runtime.
#
# The parse_model_args function in claude-switcher-utils.sh handles:
#   --sonnet → uses CLAUDE_MODEL_SONNET_<PROVIDER>
#   --opus   → uses CLAUDE_MODEL_OPUS_<PROVIDER>
#   --haiku  → uses CLAUDE_MODEL_HAIKU_<PROVIDER>
#   --model "custom-id" → uses custom-id directly
#
# This approach provides:
#   1. Provider-specific model defaults
#   2. Easy model switching via flags
#   3. Override capability in secrets.sh
#   4. Compatibility with Claude Code's runtime expectations
