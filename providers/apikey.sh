#!/bin/bash

# Anthropic API Provider (Direct)
# See: https://docs.anthropic.com/
#
# NOTE: If you're also logged into Claude Pro, you'll see an "Auth conflict"
# warning from Claude Code. This is normal - Claude Code will use the API key
# for billing. The warning is just informational.
# See: https://github.com/anthropics/claude-code/issues/9515

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

provider_name() {
    echo "Anthropic API"
}

provider_flag() {
    echo "apikey"
}

provider_validate_config() {
    if [ -n "$ANTHROPIC_API_KEY" ]; then
        _APIKEY_AUTH_METHOD="API Key"
        return 0
    fi
    return 1
}

provider_get_auth_method() {
    echo "${_APIKEY_AUTH_METHOD:-Unknown}"
}

provider_get_validation_error() {
    cat << 'EOF'
Anthropic API key is not configured

To use Anthropic API mode, you need to:
  1. Set ANTHROPIC_API_KEY in your secrets.sh file
  2. Get an API key from: https://console.anthropic.com/

Example secrets.sh:
  export ANTHROPIC_API_KEY="sk-ant-..."

See: https://docs.anthropic.com/
EOF
}

provider_setup_env() {
    local tier="${1:-mid}"
    local custom_model="$2"

    # Save current environment
    _provider_save_env

    # Disable other providers
    _provider_disable_all

    # Set model
    if [ -n "$custom_model" ]; then
        export ANTHROPIC_MODEL="$custom_model"
    else
        export ANTHROPIC_MODEL=$(provider_get_model_id "$tier")
    fi

    # Set small/fast model
    export ANTHROPIC_SMALL_FAST_MODEL=$(provider_get_small_model)

    # KEEP ANTHROPIC_API_KEY set - it was loaded from secrets.sh by load_config
    # Claude Code will use it directly for authentication.
    # If the user is also logged into Claude Pro, they'll see an "auth conflict"
    # warning - this is informational only and Claude uses the API key for billing.
    # This approach is SESSION ISOLATED via environment variables - no files modified,
    # other Claude sessions are unaffected, and crashes leave no stale state.

    return 0
}

provider_cleanup_env() {
    _provider_restore_env
}

provider_get_model_id() {
    local tier=$(_normalize_tier "$1")

    case "$tier" in
        high) echo "${CLAUDE_MODEL_OPUS_ANTHROPIC:-claude-opus-4-6}" ;;
        mid)  echo "${CLAUDE_MODEL_SONNET_ANTHROPIC:-claude-sonnet-4-6}" ;;
        low)  echo "${CLAUDE_MODEL_HAIKU_ANTHROPIC:-claude-haiku-4-5}" ;;
        *)    echo "${CLAUDE_MODEL_SONNET_ANTHROPIC:-claude-sonnet-4-6}" ;;
    esac
}

provider_get_small_model() {
    echo "${CLAUDE_SMALL_FAST_MODEL_ANTHROPIC:-${CLAUDE_MODEL_HAIKU_ANTHROPIC:-claude-haiku-4-5}}"
}

provider_supports_tool() {
    local tool="$1"
    case "$tool" in
        claude-code|cc) return 0 ;;
        aider)          return 0 ;;
        opencode)       return 0 ;;
        *)              return 1 ;;
    esac
}
