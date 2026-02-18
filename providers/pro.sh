#!/bin/bash

# Claude Pro Subscription Provider
# Uses native Claude Code authentication (no BYOK)

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

provider_name() {
    echo "Claude Pro"
}

provider_flag() {
    echo "pro"
}

provider_validate_config() {
    # Claude Pro uses native authentication - always valid if claude is installed
    if command -v claude &> /dev/null; then
        _PRO_AUTH_METHOD="Claude Pro Subscription"
        return 0
    fi
    return 1
}

provider_get_auth_method() {
    echo "${_PRO_AUTH_METHOD:-Unknown}"
}

provider_get_validation_error() {
    cat << 'EOF'
Claude Code is not installed

To use Claude Pro mode:
  1. Install Claude Code: curl -fsSL https://claude.ai/install.sh | bash
  2. Sign in with: claude login

See: https://code.claude.com/docs/en/setup
EOF
}

provider_setup_env() {
    local tier="$1"
    local custom_model="$2"

    # Save current environment
    _provider_save_env

    # Disable all BYOK providers to use native authentication
    _provider_disable_all

    # Unset any API keys or custom base URLs
    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_BASE_URL
    unset ANTHROPIC_AUTH_TOKEN

    # Set model based on tier or custom model
    # If neither is specified, leave ANTHROPIC_MODEL unset so Claude Code uses its own default
    if [ -n "$custom_model" ]; then
        export ANTHROPIC_MODEL="$custom_model"
    elif [ -n "$tier" ]; then
        export ANTHROPIC_MODEL=$(provider_get_model_id "$tier")
    fi

    return 0
}

provider_cleanup_env() {
    _provider_restore_env
}

provider_get_model_id() {
    local tier=$(_normalize_tier "$1")

    # Use Anthropic API model names for Claude Pro
    case "$tier" in
        high) echo "claude-opus-4-6" ;;
        mid)  echo "claude-sonnet-4-6" ;;
        low)  echo "claude-haiku-4-5" ;;
        *)    echo "claude-sonnet-4-6" ;;
    esac
}

provider_get_small_model() {
    echo "claude-haiku-4-5"
}

provider_supports_tool() {
    local tool="$1"
    case "$tool" in
        claude-code|cc) return 0 ;;
        *)              return 1 ;;
    esac
}
