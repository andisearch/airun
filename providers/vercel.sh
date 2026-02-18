#!/bin/bash

# Vercel AI Gateway Provider
# See: https://vercel.com/ai-gateway

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

provider_name() {
    echo "Vercel AI Gateway"
}

provider_flag() {
    echo "vercel"
}

provider_validate_config() {
    if [ -n "$VERCEL_AI_GATEWAY_TOKEN" ]; then
        _VERCEL_AUTH_METHOD="Vercel Token"
        return 0
    fi
    return 1
}

provider_get_auth_method() {
    echo "${_VERCEL_AUTH_METHOD:-Unknown}"
}

provider_get_validation_error() {
    cat << 'EOF'
Vercel AI Gateway is not configured

To use Vercel AI Gateway mode, configure in your secrets.sh:

  export VERCEL_AI_GATEWAY_TOKEN="vck_..."
  export VERCEL_AI_GATEWAY_URL="https://ai-gateway.vercel.sh"  # Optional

Get your token from: https://vercel.com/dashboard/~/ai
See: https://vercel.com/ai-gateway
EOF
}

provider_setup_env() {
    local tier="${1:-mid}"
    local custom_model="$2"

    # Save current environment
    _provider_save_env

    # Disable other providers
    _provider_disable_all

    # Configure Vercel AI Gateway
    export ANTHROPIC_BASE_URL="${VERCEL_AI_GATEWAY_URL:-https://ai-gateway.vercel.sh}"
    export ANTHROPIC_AUTH_TOKEN="$VERCEL_AI_GATEWAY_TOKEN"
    export ANTHROPIC_API_KEY=""  # Must be empty to avoid auth conflicts

    # Set model
    if [ -n "$custom_model" ]; then
        export ANTHROPIC_MODEL="$custom_model"
        # For non-Anthropic models, use the same model for background operations
        # to avoid mixing providers (e.g., xAI main + Anthropic background)
        if [[ "$custom_model" != anthropic/* ]]; then
            export ANTHROPIC_SMALL_FAST_MODEL="$custom_model"
        else
            export ANTHROPIC_SMALL_FAST_MODEL=$(provider_get_small_model)
        fi
    else
        export ANTHROPIC_MODEL=$(provider_get_model_id "$tier")
        export ANTHROPIC_SMALL_FAST_MODEL=$(provider_get_small_model)
    fi

    return 0
}

provider_cleanup_env() {
    _provider_restore_env
}

provider_get_model_id() {
    local tier=$(_normalize_tier "$1")

    case "$tier" in
        high) echo "${CLAUDE_MODEL_OPUS_VERCEL:-anthropic/claude-opus-4.6}" ;;
        mid)  echo "${CLAUDE_MODEL_SONNET_VERCEL:-anthropic/claude-sonnet-4.6}" ;;
        low)  echo "${CLAUDE_MODEL_HAIKU_VERCEL:-anthropic/claude-haiku-4.5}" ;;
        *)    echo "${CLAUDE_MODEL_SONNET_VERCEL:-anthropic/claude-sonnet-4.6}" ;;
    esac
}

provider_get_small_model() {
    echo "${CLAUDE_SMALL_FAST_MODEL_VERCEL:-${CLAUDE_MODEL_HAIKU_VERCEL:-anthropic/claude-haiku-4.5}}"
}

provider_supports_tool() {
    local tool="$1"
    case "$tool" in
        claude-code|cc) return 0 ;;
        *)              return 1 ;;
    esac
}

provider_get_gateway_url() {
    echo "${VERCEL_AI_GATEWAY_URL:-https://ai-gateway.vercel.sh}"
}
