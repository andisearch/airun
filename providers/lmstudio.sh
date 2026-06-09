#!/bin/bash

# LM Studio Provider (Local via Anthropic API Compatible)
# As of LM Studio 0.4.1 (January 2026), supports Anthropic Messages API
# See: https://lmstudio.ai/blog/claudecode
#
# LM Studio provides an Anthropic-compatible /v1/messages endpoint that
# allows Claude Code to use any local model running in LM Studio.
#
# ADVANTAGES OVER OLLAMA:
#   - MLX model support (significantly faster on Apple Silicon)
#   - GGUF + MLX formats supported
#   - Bring your own models (download from HuggingFace, etc.)
#
# REQUIREMENTS:
#   - LM Studio 0.4.1+ with local server running
#   - At least 25K context recommended for Claude Code
#   - Start server: lms server start --port 1234
#
# MODEL NAMING:
#   Models use format: provider/model-name
#   Examples: openai/gpt-oss-20b, ibm/granite-4-micro

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

# Source shared system utilities
LIB_DIR="$(cd "$PROVIDER_DIR/../scripts/lib" 2>/dev/null && pwd)"
if [ -f "$LIB_DIR/system-utils.sh" ]; then
    source "$LIB_DIR/system-utils.sh"
fi

# Default LM Studio settings
LMSTUDIO_DEFAULT_HOST="${LMSTUDIO_HOST:-http://localhost:1234}"

#=============================================================================
# Provider Interface Implementation
#=============================================================================

provider_name() {
    echo "LM Studio"
}

provider_flag() {
    echo "lmstudio"
}

provider_validate_config() {
    local lmstudio_url="${LMSTUDIO_HOST:-http://localhost:1234}"

    # Check if LM Studio server is running
    if curl -s --connect-timeout 2 "${lmstudio_url}/v1/models" &>/dev/null; then
        _LMSTUDIO_URL="$lmstudio_url"
        _LMSTUDIO_AUTH_METHOD="LM Studio Server"
        return 0
    fi

    return 1
}

provider_get_auth_method() {
    echo "${_LMSTUDIO_AUTH_METHOD:-Unknown}"
}

provider_get_validation_error() {
    cat << 'EOF'
LM Studio server is not running

Start LM Studio server:
  lms server start --port 1234

Or start from the LM Studio app:
  1. Open LM Studio
  2. Load a model
  3. Start the local server

RECOMMENDED MODELS:
  - Models with 25K+ context for Claude Code
  - MLX models for Apple Silicon (faster)

See: https://lmstudio.ai/blog/claudecode
EOF
}

provider_setup_env() {
    local tier="${1:-mid}"
    local custom_model="$2"

    # Save current environment
    _provider_save_env

    # Disable other providers
    _provider_disable_all

    # IMPORTANT: Unset any existing Anthropic credentials first
    # This prevents Claude Code from detecting user's Anthropic API key
    # and prompting "Do you want to use this API key?"
    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_AUTH_TOKEN

    # Configure LM Studio as Anthropic API compatible endpoint
    # Per LM Studio docs: https://lmstudio.ai/blog/claudecode
    export ANTHROPIC_BASE_URL="${LMSTUDIO_HOST:-http://localhost:1234}"
    export ANTHROPIC_AUTH_TOKEN="lmstudio"
    export ANTHROPIC_API_KEY=""

    # Set model
    if [ -n "$custom_model" ]; then
        export ANTHROPIC_MODEL="$custom_model"
        # Check if custom model is available, offer to download if not
        if ! provider_model_available "$custom_model"; then
            _lmstudio_ensure_model_available "$custom_model" || true
            # Re-check: if still unavailable after prompt, fail so caller can fall back
            if ! provider_model_available "$ANTHROPIC_MODEL"; then
                print_error "Model '${ANTHROPIC_MODEL}' is not available in LM Studio."
                _provider_restore_env
                return 1
            fi
        fi
    else
        [ "$(_normalize_tier "$tier")" = "fable" ] && _notice_fable_fallback "LM Studio"
        export ANTHROPIC_MODEL=$(provider_get_model_id "$tier")
    fi

    # No model available — show guidance and fail so caller can fall back
    if [ -z "$ANTHROPIC_MODEL" ]; then
        print_warning "No models loaded in LM Studio."
        echo "" >&2
        echo "  To use LM Studio, load a model first:" >&2
        echo "    1. Open the LM Studio app and load a model" >&2
        echo "    2. Or use the CLI: lms load <model-name>" >&2
        echo "" >&2
        echo "  Tip: Use 25K+ context for best results with Claude Code" >&2
        echo "  See: https://lmstudio.ai/blog/claudecode" >&2
        _provider_restore_env
        return 1
    fi

    # Set small/fast model (for background operations)
    # Use same model as main to avoid model swapping
    export ANTHROPIC_SMALL_FAST_MODEL=$(provider_get_small_model)

    return 0
}

provider_cleanup_env() {
    _provider_restore_env
}

provider_get_model_id() {
    local tier=$(_normalize_tier "$1")

    # LM Studio model mappings - configurable via secrets.sh
    # Unlike Ollama, LM Studio has no standardized model naming
    # Users download arbitrary models, so we default to first available
    case "$tier" in
        fable|high)
            # Fable 5 is Anthropic-only; --fable/--best falls back to the highest local tier
            if [ -n "$LMSTUDIO_MODEL_HIGH" ]; then
                echo "$LMSTUDIO_MODEL_HIGH"
                return
            fi
            ;;
        mid)
            if [ -n "$LMSTUDIO_MODEL_MID" ]; then
                echo "$LMSTUDIO_MODEL_MID"
                return
            fi
            ;;
        low)
            if [ -n "$LMSTUDIO_MODEL_LOW" ]; then
                echo "$LMSTUDIO_MODEL_LOW"
                return
            fi
            ;;
    esac

    # Fallback: use first available model (same for all tiers)
    _lmstudio_get_first_model
}

provider_get_small_model() {
    # For LM Studio, default to using the SAME model for background operations
    # to avoid costly model swapping. Users can override via LMSTUDIO_SMALL_FAST_MODEL
    if [ -n "$LMSTUDIO_SMALL_FAST_MODEL" ]; then
        echo "$LMSTUDIO_SMALL_FAST_MODEL"
    else
        # Use same model as main to avoid swapping
        provider_get_model_id "mid"
    fi
}

# Get first available model from LM Studio
# Returns empty string if no models are loaded (caller handles messaging)
_lmstudio_get_first_model() {
    local models
    models=$(provider_list_models 2>/dev/null)
    [ -n "$models" ] && echo "$models" | head -1
}

provider_supports_tool() {
    local tool="$1"
    # LM Studio supports any tool that uses Anthropic API
    case "$tool" in
        claude-code|cc) return 0 ;;
        opencode)       return 0 ;;
        aider)          return 0 ;;
        *)              return 1 ;;
    esac
}

# Print extra provider-specific info during startup (interactive mode only)
provider_print_extra_info() {
    # Use shared system utilities if available
    if type _print_capabilities_line &>/dev/null; then
        _print_capabilities_line "LM Studio"
    fi

    # Remind about context window
    echo "[AI Runner] - Tip: Configure 25K+ context in LM Studio for best results"
}

# List available models in LM Studio
provider_list_models() {
    local lmstudio_url="${LMSTUDIO_HOST:-http://localhost:1234}"
    curl -s "${lmstudio_url}/v1/models" 2>/dev/null | \
        grep -o '"id" *: *"[^"]*"' | \
        cut -d'"' -f4
}

# Check if a specific model is available in LM Studio
provider_model_available() {
    local model="$1"
    local models
    models=$(provider_list_models 2>/dev/null)
    echo "$models" | grep -q "^${model}$"
}

# Get LM Studio server URL
provider_get_url() {
    echo "${LMSTUDIO_HOST:-http://localhost:1234}"
}

#=============================================================================
# Model Management (Download, Load, Unload)
#=============================================================================

# Download a model from LM Studio's model library
# Usage: _lmstudio_download_model "publisher/model-name"
_lmstudio_download_model() {
    local model="$1"
    local lmstudio_url="${LMSTUDIO_HOST:-http://localhost:1234}"

    echo "Downloading model: $model"
    echo "This may take a while depending on model size..."
    echo ""

    # Start the download
    local response
    response=$(curl -s -X POST "${lmstudio_url}/api/v1/models/download" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$model\"}" 2>&1)

    if [ $? -ne 0 ]; then
        print_error "Failed to start download: $response"
        return 1
    fi

    # Poll download status
    local status="downloading"
    while [ "$status" = "downloading" ]; do
        sleep 2
        local status_response
        status_response=$(curl -s "${lmstudio_url}/api/v1/download-status" 2>/dev/null)

        # Check if download is complete
        if echo "$status_response" | grep -q '"status":"complete"'; then
            status="complete"
        elif echo "$status_response" | grep -q '"status":"error"'; then
            status="error"
        else
            # Show progress if available
            local progress
            progress=$(echo "$status_response" | grep -o '"progress":[0-9.]*' | cut -d: -f2)
            if [ -n "$progress" ]; then
                printf "\rProgress: %.1f%%" "$progress"
            fi
        fi
    done

    echo ""

    if [ "$status" = "complete" ]; then
        print_success "Model downloaded successfully: $model"
        return 0
    else
        print_error "Download failed"
        return 1
    fi
}

# Load a model into memory
# Usage: _lmstudio_load_model "publisher/model-name"
_lmstudio_load_model() {
    local model="$1"
    local lmstudio_url="${LMSTUDIO_HOST:-http://localhost:1234}"

    echo "Loading model: $model"

    local response
    response=$(curl -s -X POST "${lmstudio_url}/api/v1/models/load" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$model\"}" 2>&1)

    if echo "$response" | grep -q '"success":true\|"status":"loaded"'; then
        print_success "Model loaded: $model"
        return 0
    else
        print_error "Failed to load model: $response"
        return 1
    fi
}

# Unload a model from memory
# Usage: _lmstudio_unload_model "publisher/model-name"
_lmstudio_unload_model() {
    local model="$1"
    local lmstudio_url="${LMSTUDIO_HOST:-http://localhost:1234}"

    curl -s -X POST "${lmstudio_url}/api/v1/models/unload" \
        -H "Content-Type: application/json" \
        -d "{\"model\": \"$model\"}" &>/dev/null
}

# Check if model is loaded (in memory) vs just downloaded
# Returns: "loaded", "downloaded", or "not_found"
_lmstudio_get_model_state() {
    local model="$1"
    local lmstudio_url="${LMSTUDIO_HOST:-http://localhost:1234}"

    local response
    response=$(curl -s "${lmstudio_url}/api/v1/models" 2>/dev/null)

    # Check if model is in the response
    if echo "$response" | grep -q "\"id\" *: *\"$model\""; then
        # Check state field if available
        if echo "$response" | grep -A5 "\"id\" *: *\"$model\"" | grep -q '"state" *: *"loaded"'; then
            echo "loaded"
        else
            echo "downloaded"
        fi
    else
        echo "not_found"
    fi
}

# Interactive prompt to download/load a model if not available
# Called during provider_setup_env when model is missing
_lmstudio_ensure_model_available() {
    local model="$1"

    # Skip if not interactive
    if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
        return 1
    fi

    local state
    state=$(_lmstudio_get_model_state "$model")

    case "$state" in
        loaded)
            # Model is ready
            return 0
            ;;
        downloaded)
            # Model downloaded but not loaded
            echo ""
            print_warning "Model '$model' is downloaded but not loaded."
            read -r -p "Load it now? [Y/n]: " choice
            choice="${choice:-Y}"
            if [[ "$choice" =~ ^[Yy] ]]; then
                _lmstudio_load_model "$model"
                return $?
            fi
            return 1
            ;;
        not_found)
            # Model not available
            echo ""
            print_warning "Model '$model' not found in LM Studio."
            read -r -p "Download it? [Y/n]: " choice
            choice="${choice:-Y}"
            if [[ "$choice" =~ ^[Yy] ]]; then
                if _lmstudio_download_model "$model"; then
                    read -r -p "Load it now? [Y/n]: " load_choice
                    load_choice="${load_choice:-Y}"
                    if [[ "$load_choice" =~ ^[Yy] ]]; then
                        _lmstudio_load_model "$model"
                        return $?
                    fi
                fi
            fi
            return 1
            ;;
    esac
}
