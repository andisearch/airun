#!/bin/bash

# DGX Spark Provider (Remote Ollama on VPN)
# Uses Ollama's Anthropic Messages API compatibility
# See: https://docs.ollama.com/integrations/claude-code
#
# Default host: http://DGXSPARK-A:11434
# Override with: export DGX_HOST="http://other-host:11434"

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

provider_name() {
    echo "DGX Spark"
}

provider_flag() {
    echo "dgx"
}

provider_validate_config() {
    local dgx_url="${DGX_HOST:-http://DGXSPARK-A:11434}"

    if curl -s --connect-timeout 3 "${dgx_url}/api/tags" &>/dev/null; then
        _DGX_URL="$dgx_url"
        _DGX_AUTH_METHOD="DGX Spark (Ollama)"
        return 0
    fi

    return 1
}

provider_get_auth_method() {
    echo "${_DGX_AUTH_METHOD:-Unknown}"
}

provider_get_validation_error() {
    cat << 'EOF'
DGX Spark is not reachable

Make sure:
  • VPN is connected
  • DGX Spark is powered on and running Ollama
  • The hostname DGXSPARK-A resolves correctly

Expected at:
  http://DGXSPARK-A:11434

Override with DGX_HOST:
  export DGX_HOST=http://DGXSPARK-A:11434
EOF
}

provider_setup_env() {
    local tier="${1:-mid}"
    local custom_model="$2"

    _provider_save_env
    _provider_disable_all

    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_AUTH_TOKEN

    export ANTHROPIC_BASE_URL="${DGX_HOST:-http://DGXSPARK-A:11434}"
    export ANTHROPIC_AUTH_TOKEN="ollama"
    export ANTHROPIC_API_KEY=""

    if [ -n "$custom_model" ]; then
        export ANTHROPIC_MODEL="$custom_model"
        if ! provider_model_available "$custom_model"; then
            _dgx_ensure_model_available "$custom_model" || true
            if ! provider_model_available "$ANTHROPIC_MODEL"; then
                print_error "Model '${ANTHROPIC_MODEL}' is not available on DGX Spark."
                echo "  Pull it from the DGX Spark server or use a different model." >&2
                _provider_restore_env
                return 1
            fi
        fi
    else
        export ANTHROPIC_MODEL=$(provider_get_model_id "$tier")
    fi

    if [ -z "$ANTHROPIC_MODEL" ]; then
        print_warning "No models available on DGX Spark."
        _provider_restore_env
        return 1
    fi

    export ANTHROPIC_SMALL_FAST_MODEL=$(provider_get_small_model)
    return 0
}

provider_cleanup_env() {
    _provider_restore_env
}

provider_get_model_id() {
    local tier=$(_normalize_tier "$1")

    case "$tier" in
        high)
            if [ -n "$DGX_MODEL_HIGH" ]; then
                echo "$DGX_MODEL_HIGH"
            else
                _dgx_auto_detect_model
            fi
            ;;
        mid)
            if [ -n "$DGX_MODEL_MID" ]; then
                echo "$DGX_MODEL_MID"
            else
                _dgx_auto_detect_model
            fi
            ;;
        low)
            if [ -n "$DGX_MODEL_LOW" ]; then
                echo "$DGX_MODEL_LOW"
            else
                _dgx_auto_detect_model
            fi
            ;;
        *)
            if [ -n "$DGX_MODEL_MID" ]; then
                echo "$DGX_MODEL_MID"
            else
                _dgx_auto_detect_model
            fi
            ;;
    esac
}

provider_get_small_model() {
    if [ -n "$DGX_SMALL_FAST_MODEL" ]; then
        echo "$DGX_SMALL_FAST_MODEL"
    else
        provider_get_model_id "low"
    fi
}

_dgx_auto_detect_model() {
    local models
    models=$(provider_list_models 2>/dev/null)
    if [ -z "$models" ]; then
        echo ""
        return
    fi
    echo "$models" | head -1
}

provider_supports_tool() {
    local tool="$1"
    case "$tool" in
        claude-code|cc) return 0 ;;
        opencode)       return 0 ;;
        aider)          return 0 ;;
        *)              return 1 ;;
    esac
}

provider_model_available() {
    local model="$1"
    local dgx_url="${DGX_HOST:-http://DGXSPARK-A:11434}"
    local model_name="${model%%:*}"

    curl -s --connect-timeout 5 "${dgx_url}/api/tags" 2>/dev/null | grep -qE "\"name\":\"${model_name}(\"|:)"
}

provider_list_models() {
    local dgx_url="${DGX_HOST:-http://DGXSPARK-A:11434}"
    curl -s --connect-timeout 5 "${dgx_url}/api/tags" 2>/dev/null | \
        grep -o '"name":"[^"]*"' | \
        cut -d'"' -f4
}

provider_get_url() {
    echo "${DGX_HOST:-http://DGXSPARK-A:11434}"
}

_dgx_download_model() {
    local model="$1"
    local dgx_url="${DGX_HOST:-http://DGXSPARK-A:11434}"

    echo "Pulling model: $model"
    curl -s --connect-timeout 5 -X POST "${dgx_url}/api/pull" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$model\", \"stream\": false}" 2>&1
    echo ""

    if provider_model_available "$model"; then
        print_success "Model pulled: $model"
        return 0
    else
        print_error "Failed to pull: $model"
        return 1
    fi
}

_dgx_ensure_model_available() {
    local model="$1"

    if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
        return 1
    fi

    if provider_model_available "$model"; then
        return 0
    fi

    echo ""
    print_warning "Model '$model' not found on DGX Spark."
    read -r -p "Pull it now? [Y/n]: " choice
    choice="${choice:-Y}"

    if [[ "$choice" =~ ^[Yy] ]]; then
        _dgx_download_model "$model"
        return $?
    fi

    return 1
}
