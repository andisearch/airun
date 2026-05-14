#!/bin/bash

# Generic Local Provider (User-configured local Anthropic-compatible backend)

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

LIB_DIR="$(cd "$PROVIDER_DIR/../scripts/lib" 2>/dev/null && pwd)"
[ -f "$LIB_DIR/local-provider-manager.sh" ] || LIB_DIR="$(cd "$PROVIDER_DIR/../lib" 2>/dev/null && pwd)"
source "$LIB_DIR/local-provider-manager.sh"

provider_name() {
    local_provider_name
}

provider_flag() {
    echo "local"
}

provider_validate_config() {
    local_provider_refresh_status
}

provider_get_auth_method() {
    local_provider_load_config >/dev/null 2>&1 || true
    if [ -n "${LOCAL_PROVIDER_AUTH_TOKEN:-}" ]; then
        echo "Local Token"
    else
        echo "No Auth"
    fi
}

provider_get_validation_error() {
    local_provider_print_validation_error
}

provider_setup_env() {
    local custom_model="$2"
    local resolved_model=""
    local runtime_base=""

    local_provider_load_config >/dev/null 2>&1 || {
        print_error "No local provider is configured. Run: ai local-onboard"
        return 1
    }

    _provider_save_env
    _provider_disable_all

    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_AUTH_TOKEN

    runtime_base=$(local_provider_runtime_base_url)
    export ANTHROPIC_BASE_URL="$runtime_base"
    export ANTHROPIC_AUTH_TOKEN="${LOCAL_PROVIDER_AUTH_TOKEN:-}"
    export ANTHROPIC_API_KEY=""

    if [ -n "$custom_model" ]; then
        if ! provider_model_available "$custom_model"; then
            print_error "Model '$custom_model' is not available from the configured local provider."
            _provider_restore_env
            return 1
        fi
        resolved_model="$custom_model"
    else
        resolved_model=$(provider_get_model_id "mid")
    fi

    if [ -z "$resolved_model" ]; then
        print_error "No models are available from the configured local provider."
        _provider_restore_env
        return 1
    fi

    export ANTHROPIC_MODEL="$resolved_model"
    export ANTHROPIC_SMALL_FAST_MODEL="${LOCAL_PROVIDER_SMALL_FAST_MODEL:-$resolved_model}"
    return 0
}

provider_cleanup_env() {
    _provider_restore_env
}

provider_get_model_id() {
    local_provider_load_config >/dev/null 2>&1 || return 1
    if [ -n "${LOCAL_PROVIDER_DEFAULT_MODEL:-}" ]; then
        echo "$LOCAL_PROVIDER_DEFAULT_MODEL"
    else
        provider_list_models | head -1
    fi
}

provider_get_small_model() {
    local_provider_load_config >/dev/null 2>&1 || return 1
    echo "${LOCAL_PROVIDER_SMALL_FAST_MODEL:-${LOCAL_PROVIDER_DEFAULT_MODEL:-$(provider_list_models | head -1)}}"
}

provider_supports_tool() {
    local tool="$1"
    case "$tool" in
        claude-code|cc) return 0 ;;
        *)              return 1 ;;
    esac
}

provider_list_models() {
    local_provider_list_models
}

provider_model_available() {
    local model="$1"
    provider_list_models | grep -qx "$model"
}

provider_get_url() {
    local_provider_runtime_base_url
}
