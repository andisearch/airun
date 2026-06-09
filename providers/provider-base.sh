#!/bin/bash

# Provider Base Interface
# All providers must implement these functions

# Provider Interface Functions:
#
# provider_name()              - Return human-readable provider name
# provider_flag()              - Return CLI flag name (e.g., "aws", "vertex")
# provider_validate_config()   - Validate credentials are configured (return 0=valid, 1=invalid)
# provider_setup_env()         - Export environment variables for this provider
# provider_cleanup_env()       - Restore original environment (called on exit)
# provider_get_model_id()      - Map tier (high/mid/low) to provider-specific model ID
# provider_get_small_model()   - Get the small/fast model for background operations
# provider_supports_tool()     - Check if provider supports a given tool (return 0=yes, 1=no)

# Saved environment state (populated by provider_setup_env for restoration)
# Note: Using simple assignments instead of declare -g for Bash 3.2 compatibility (macOS)
_SAVED_ANTHROPIC_MODEL=""
_SAVED_ANTHROPIC_SMALL_FAST_MODEL=""
_SAVED_ANTHROPIC_API_KEY=""
_SAVED_ANTHROPIC_BASE_URL=""
_SAVED_ANTHROPIC_AUTH_TOKEN=""
_SAVED_CLAUDE_CODE_USE_BEDROCK=""
_SAVED_CLAUDE_CODE_USE_VERTEX=""
_SAVED_CLAUDE_CODE_USE_FOUNDRY=""

# Save current environment for later restoration
_provider_save_env() {
    _SAVED_ANTHROPIC_MODEL="$ANTHROPIC_MODEL"
    _SAVED_ANTHROPIC_SMALL_FAST_MODEL="$ANTHROPIC_SMALL_FAST_MODEL"
    _SAVED_ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"
    _SAVED_ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL"
    _SAVED_ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN"
    _SAVED_CLAUDE_CODE_USE_BEDROCK="$CLAUDE_CODE_USE_BEDROCK"
    _SAVED_CLAUDE_CODE_USE_VERTEX="$CLAUDE_CODE_USE_VERTEX"
    _SAVED_CLAUDE_CODE_USE_FOUNDRY="$CLAUDE_CODE_USE_FOUNDRY"
}

# Restore saved environment
_provider_restore_env() {
    if [ -n "$_SAVED_ANTHROPIC_MODEL" ]; then
        export ANTHROPIC_MODEL="$_SAVED_ANTHROPIC_MODEL"
    else
        unset ANTHROPIC_MODEL
    fi

    if [ -n "$_SAVED_ANTHROPIC_SMALL_FAST_MODEL" ]; then
        export ANTHROPIC_SMALL_FAST_MODEL="$_SAVED_ANTHROPIC_SMALL_FAST_MODEL"
    else
        unset ANTHROPIC_SMALL_FAST_MODEL
    fi

    if [ -n "$_SAVED_ANTHROPIC_API_KEY" ]; then
        export ANTHROPIC_API_KEY="$_SAVED_ANTHROPIC_API_KEY"
    else
        unset ANTHROPIC_API_KEY
    fi

    if [ -n "$_SAVED_ANTHROPIC_BASE_URL" ]; then
        export ANTHROPIC_BASE_URL="$_SAVED_ANTHROPIC_BASE_URL"
    else
        unset ANTHROPIC_BASE_URL
    fi

    if [ -n "$_SAVED_ANTHROPIC_AUTH_TOKEN" ]; then
        export ANTHROPIC_AUTH_TOKEN="$_SAVED_ANTHROPIC_AUTH_TOKEN"
    else
        unset ANTHROPIC_AUTH_TOKEN
    fi

    if [ -n "$_SAVED_CLAUDE_CODE_USE_BEDROCK" ]; then
        export CLAUDE_CODE_USE_BEDROCK="$_SAVED_CLAUDE_CODE_USE_BEDROCK"
    else
        unset CLAUDE_CODE_USE_BEDROCK
    fi

    if [ -n "$_SAVED_CLAUDE_CODE_USE_VERTEX" ]; then
        export CLAUDE_CODE_USE_VERTEX="$_SAVED_CLAUDE_CODE_USE_VERTEX"
    else
        unset CLAUDE_CODE_USE_VERTEX
    fi

    if [ -n "$_SAVED_CLAUDE_CODE_USE_FOUNDRY" ]; then
        export CLAUDE_CODE_USE_FOUNDRY="$_SAVED_CLAUDE_CODE_USE_FOUNDRY"
    else
        unset CLAUDE_CODE_USE_FOUNDRY
    fi
}

# Helper to map tier aliases to canonical names
# Input: --opus, --sonnet, --haiku, --high, --mid, --low, --fable, --best
# Output: fable, high, mid, low
_normalize_tier() {
    local tier="$1"
    case "$tier" in
        --fable|--best|fable|best) echo "fable" ;;
        --opus|--high|high|opus)   echo "high" ;;
        --sonnet|--mid|mid|sonnet) echo "mid" ;;
        --haiku|--low|low|haiku)   echo "low" ;;
        *)                          echo "mid" ;;  # default
    esac
}

# Notice printed when --fable/--best is used on a runtime that doesn't have
# Claude Fable 5 (local providers, Codex). $1 = friendly runtime name.
_notice_fable_fallback() {
    echo "Note: Claude Fable 5 is Anthropic-only — using ${1}'s highest-tier model instead." >&2
}

# Disable all provider modes (call before enabling specific provider)
_provider_disable_all() {
    unset CLAUDE_CODE_USE_BEDROCK
    unset CLAUDE_CODE_USE_VERTEX
    unset CLAUDE_CODE_USE_FOUNDRY
    unset AWS_BEARER_TOKEN_BEDROCK
    # Clean slate for model and endpoint vars (already saved by _provider_save_env)
    unset ANTHROPIC_BASE_URL
    unset ANTHROPIC_AUTH_TOKEN
    unset ANTHROPIC_MODEL
    unset ANTHROPIC_SMALL_FAST_MODEL
}

# Default: no extra info (providers can override)
provider_print_extra_info() {
    :
}
