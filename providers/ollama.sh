#!/bin/bash

# Ollama Provider (Local + Cloud via Anthropic API Compatible)
# As of Ollama 0.14.0 (January 2026), supports Anthropic Messages API
# See: https://ollama.com/blog/claude
#
# CLOUD MODELS: Use :cloud suffix (e.g., glm-5:cloud, minimax-m2.5:cloud)
#   - Requires: ollama signin (one-time browser auth)
#   - No GPU needed - models run on Ollama's infrastructure
#   - See: https://ollama.com/search?c=cloud
#
# MEMORY NOTE: Ollama loads models on-demand and keeps them in memory for 5min.
# Claude Code uses two models (main + background). If these differ, Ollama may
# swap models on each request, causing delays. By default we use the same model
# for both. Users with 24GB+ VRAM can set OLLAMA_SMALL_FAST_MODEL for a separate
# background model. See: https://github.com/ollama/ollama/issues/4681
#
# REQUIREMENTS: Claude Code needs 64K+ context. Ollama-recommended models:
#   - qwen3-coder (coding optimized, 30B, needs 24GB VRAM)
#   - gpt-oss:20b (strong general-purpose)
#   - glm-5:cloud (MIT license, strong reasoning, 198K context)
#   - minimax-m2.5:cloud (fastest frontier, 198K context)
# See: https://docs.ollama.com/integrations/claude-code

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

# Default Ollama settings
OLLAMA_DEFAULT_HOST="${OLLAMA_HOST:-http://localhost:11434}"

#=============================================================================
# System Detection Helpers
#=============================================================================

# Get available disk space in GB (for Ollama models directory)
# Safe: read-only, uses standard df command
_ollama_get_disk_space_gb() {
    local ollama_dir="${OLLAMA_MODELS:-$HOME/.ollama}"
    local mount_point

    # Find the mount point for ollama directory (or home if doesn't exist yet)
    if [ -d "$ollama_dir" ]; then
        mount_point="$ollama_dir"
    else
        mount_point="$HOME"
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: df outputs in 512-byte blocks by default, use -g for GB
        df -g "$mount_point" 2>/dev/null | awk 'NR==2 {print $4}' || echo ""
    else
        # Linux: df -BG for GB
        df -BG "$mount_point" 2>/dev/null | awk 'NR==2 {gsub(/G/,""); print $4}' || echo ""
    fi
}

# Get system RAM in GB
# Safe: read-only, uses sysctl (macOS) or /proc/meminfo (Linux)
_ollama_get_ram_gb() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        local bytes
        bytes=$(sysctl -n hw.memsize 2>/dev/null) || return
        if [ -n "$bytes" ] && [ "$bytes" -gt 0 ] 2>/dev/null; then
            echo $((bytes / 1024 / 1024 / 1024))
        fi
    else
        # Linux
        local kb
        kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}') || return
        if [ -n "$kb" ] && [ "$kb" -gt 0 ] 2>/dev/null; then
            echo $((kb / 1024 / 1024))
        fi
    fi
}

# Detect GPU and VRAM (best effort, read-only)
# Safe: only reads system info, no modifications
_ollama_get_gpu_info() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - check for Apple Silicon unified memory
        local chip
        chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null) || true
        if [[ "$chip" == *"Apple"* ]]; then
            local ram
            ram=$(_ollama_get_ram_gb) || ram=0
            echo "apple_silicon:${ram:-0}GB_unified"
            return
        fi
    fi

    # NVIDIA GPU (read-only query)
    if command -v nvidia-smi &>/dev/null; then
        local vram
        vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1) || true
        if [ -n "$vram" ] && [ "$vram" -gt 0 ] 2>/dev/null; then
            echo "nvidia:$((vram / 1024))GB"
            return
        fi
    fi

    # AMD GPU (Linux, read-only from sysfs)
    if [ -r /sys/class/drm/card0/device/mem_info_vram_total ]; then
        local vram
        vram=$(cat /sys/class/drm/card0/device/mem_info_vram_total 2>/dev/null) || true
        if [ -n "$vram" ] && [ "$vram" -gt 0 ] 2>/dev/null; then
            echo "amd:$((vram / 1024 / 1024 / 1024))GB"
            return
        fi
    fi

    echo "unknown"
}

# Get model recommendations based on system specs
_ollama_get_model_recommendations() {
    local ram=$(_ollama_get_ram_gb)
    local disk=$(_ollama_get_disk_space_gb)
    local gpu=$(_ollama_get_gpu_info)
    local vram=0

    # Parse VRAM from GPU info
    if [[ "$gpu" == "apple_silicon:"* ]]; then
        # Apple Silicon uses unified memory - can use ~75% for models
        vram=$((ram * 3 / 4))
    elif [[ "$gpu" == *"GB" ]]; then
        vram=$(echo "$gpu" | grep -oE '[0-9]+GB' | tr -d 'GB')
    fi

    echo "SYSTEM_RAM=${ram:-unknown}"
    echo "DISK_SPACE=${disk:-unknown}"
    echo "GPU_INFO=$gpu"
    echo "EFFECTIVE_VRAM=${vram:-0}"

    # Recommend models based on available resources
    # VRAM requirements (model + KV cache + overhead):
    #   qwen3-coder:30b → needs ~28GB
    #   qwen2.5-coder:14b → needs ~12GB
    #   qwen2.5-coder:7b → needs ~8GB
    if [ "${vram:-0}" -ge 28 ]; then
        echo "RECOMMENDED=qwen3-coder,gpt-oss:20b"
        echo "TIER=high"
    elif [ "${vram:-0}" -ge 20 ]; then
        echo "RECOMMENDED=gpt-oss:20b,qwen2.5-coder:14b"
        echo "TIER=mid"
    elif [ "${vram:-0}" -ge 12 ]; then
        echo "RECOMMENDED=qwen2.5-coder:14b,glm-5:cloud"
        echo "TIER=low"
        echo "NOTE=Consider using Ollama Cloud for better performance."
    else
        echo "RECOMMENDED=qwen2.5-coder:7b,glm-5:cloud"
        echo "TIER=minimal"
        echo "NOTE=Limited VRAM. Recommend Ollama Cloud for coding tasks."
    fi
}

# Get effective VRAM for model selection
_ollama_get_effective_vram() {
    local gpu=$(_ollama_get_gpu_info)
    local ram=$(_ollama_get_ram_gb)
    local vram=0

    if [[ "$gpu" == "apple_silicon:"* ]]; then
        # Apple Silicon uses unified memory - can use ~75% for models
        vram=$((ram * 3 / 4))
    elif [[ "$gpu" == "nvidia:"* ]] || [[ "$gpu" == "amd:"* ]]; then
        vram=$(echo "$gpu" | grep -oE '[0-9]+' | head -1)
    fi

    echo "${vram:-0}"
}

# Check if system should prefer cloud models
# Thresholds based on actual model requirements:
#   qwen3-coder:30b = 19GB model + overhead → needs ~28GB
#   qwen2.5-coder:14b = ~9GB model + overhead → needs ~12GB
#   qwen2.5-coder:7b = ~5GB model + overhead → needs ~8GB
_ollama_should_prefer_cloud() {
    local vram=$(_ollama_get_effective_vram)
    # Systems with < 20GB effective VRAM will struggle with coding models
    # (need headroom for KV cache, context, and macOS overhead)
    [ "${vram:-0}" -lt 20 ]
}

# Print system capabilities line for startup (only in interactive mode)
_ollama_print_capabilities_line() {
    local ram=$(_ollama_get_ram_gb)
    local vram=$(_ollama_get_effective_vram)
    local gpu=$(_ollama_get_gpu_info)
    local gpu_label=""

    if [[ "$gpu" == "apple_silicon:"* ]]; then
        gpu_label="Apple Silicon"
    elif [[ "$gpu" == "nvidia:"* ]]; then
        gpu_label="NVIDIA ${gpu#nvidia:}"
    elif [[ "$gpu" == "amd:"* ]]; then
        gpu_label="AMD ${gpu#amd:}"
    else
        gpu_label="CPU only"
    fi

    echo "[AI Runner] - System: ${ram}GB RAM, ~${vram}GB for models ($gpu_label)"
}

# Interactive prompt to switch to cloud models (only called in interactive mode)
# Returns 0 if user wants cloud, 1 if user wants to continue with local
_ollama_prompt_cloud_switch() {
    local vram=$(_ollama_get_effective_vram)

    echo ""
    print_warning "Your system has ~${vram}GB usable VRAM - local models may be slow."
    echo ""
    echo "Ollama Cloud runs models on Ollama's servers (fast on any hardware)."
    echo ""
    echo "  1) Switch to cloud (recommended) - pulls glm-5:cloud (~1MB manifest)"
    echo "  2) Continue with local model anyway"
    echo ""

    local choice
    read -r -p "Choice [1]: " choice
    choice="${choice:-1}"

    case "$choice" in
        1|"")
            echo ""
            print_status "Pulling glm-5:cloud..."
            if ollama pull glm-5:cloud 2>&1; then
                print_success "Cloud model ready!"
                return 0
            else
                print_error "Failed to pull cloud model. Continuing with local."
                return 1
            fi
            ;;
        2)
            echo ""
            print_status "Continuing with local model..."
            return 1
            ;;
        *)
            print_status "Continuing with local model..."
            return 1
            ;;
    esac
}

# Print system info and recommendations for user
_ollama_print_system_recommendations() {
    local ram=$(_ollama_get_ram_gb)
    local disk=$(_ollama_get_disk_space_gb)
    local gpu=$(_ollama_get_gpu_info)
    local vram=$(_ollama_get_effective_vram)

    echo ""
    echo "System detected:"
    [ -n "$ram" ] && echo "  RAM: ${ram}GB"
    [ -n "$disk" ] && echo "  Disk available: ${disk}GB"

    if [[ "$gpu" == "apple_silicon:"* ]]; then
        echo "  GPU: Apple Silicon (unified memory, ~${vram}GB usable)"
    elif [[ "$gpu" == "nvidia:"* ]]; then
        echo "  GPU: NVIDIA ${gpu#nvidia:} VRAM"
    elif [[ "$gpu" == "amd:"* ]]; then
        echo "  GPU: AMD ${gpu#amd:} VRAM"
    else
        echo "  GPU: Not detected"
    fi

    echo ""

    # Thresholds based on actual model requirements:
    #   qwen3-coder:30b needs ~28GB
    #   qwen2.5-coder:14b needs ~12GB, qwen2.5-coder:7b needs ~8GB
    if [ "${vram:-0}" -lt 20 ]; then
        echo "RECOMMENDED: Use Ollama Cloud (your system has limited VRAM)"
        echo ""
        echo "  Cloud models run on Ollama's servers - fast on any hardware:"
        echo "  ollama pull glm-5:cloud         # MIT license, strong reasoning (recommended)"
        echo "  ollama pull minimax-m2.5:cloud  # Fastest frontier, 198K context"
        echo "  ai --ollama --model glm-5:cloud"
        echo ""
        echo "  Or use quick setup:  ollama launch claude"
        if [ "${vram:-0}" -ge 12 ]; then
            echo ""
            echo "Local alternatives (may be slow):"
            echo "  ollama pull qwen2.5-coder:14b  # 14B coding model (~9GB)"
        elif [ "${vram:-0}" -ge 8 ]; then
            echo ""
            echo "Local alternatives (limited):"
            echo "  ollama pull qwen2.5-coder:7b   # 7B coding model (~5GB)"
        fi
    elif [ "${vram:-0}" -ge 28 ]; then
        echo "Your system can run large local models:"
        echo "  ollama pull qwen3-coder    # 30B, coding optimized (~19GB)"
        echo "  ollama pull gpt-oss:20b    # Strong general-purpose (~12GB)"
        echo "  ai --ollama"
    else
        # 20-28GB range
        echo "Your system can run mid-size local models:"
        echo "  ollama pull gpt-oss:20b    # Strong general-purpose (~12GB)"
        echo "  ai --ollama"
        echo ""
        echo "Note: qwen3-coder:30b (~19GB) may be slow on your system."
        echo "For best performance, consider cloud:"
        echo "  ollama pull glm-5:cloud"
    fi

    if [ "${disk:-0}" -lt 20 ]; then
        echo ""
        echo "  ⚠ Low disk space (${disk}GB). Consider cloud models instead."
    fi
}

provider_name() {
    echo "Ollama"
}

provider_flag() {
    echo "ollama"
}

provider_validate_config() {
    local ollama_url="${OLLAMA_HOST:-http://localhost:11434}"

    # Check if Ollama is running (required for both local and cloud models)
    # Cloud models (e.g., glm-5:cloud) are proxied through the local server
    if curl -s --connect-timeout 2 "${ollama_url}/api/tags" &>/dev/null; then
        _OLLAMA_URL="$ollama_url"
        _OLLAMA_AUTH_METHOD="Ollama Server"
        return 0
    fi

    return 1
}

provider_get_auth_method() {
    echo "${_OLLAMA_AUTH_METHOD:-Unknown}"
}

provider_get_validation_error() {
    cat << 'EOF'
Ollama is not running

Start Ollama:
  ollama serve

QUICK SETUP (Ollama 0.15+):
  ollama launch claude       # Auto-configure and launch

LOCAL MODELS (free, requires GPU):
  ollama pull qwen3-coder    # Coding optimized (24GB VRAM)
  ai --ollama

CLOUD MODELS (no GPU needed):
  ollama pull glm-5:cloud         # Tiny download, runs remotely
  ai --ollama --model glm-5:cloud

See: https://docs.ollama.com/api/anthropic-compatibility
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

    # Configure Ollama as Anthropic API compatible endpoint
    # Per Ollama docs: https://docs.ollama.com/api/anthropic-compatibility
    #
    # IMPORTANT: Cloud models (e.g., glm-5:cloud) are accessed through your
    # LOCAL Ollama server, which proxies to Ollama's cloud. The :cloud suffix
    # tells Ollama to run the model on their infrastructure, but the API
    # endpoint is always your local server (localhost:11434).
    #
    # The OLLAMA_API_KEY is used by Ollama for cloud model authentication,
    # but Claude Code connects to the local server with ANTHROPIC_AUTH_TOKEN=ollama.
    export ANTHROPIC_BASE_URL="${OLLAMA_HOST:-http://localhost:11434}"
    export ANTHROPIC_AUTH_TOKEN="ollama"
    export ANTHROPIC_API_KEY=""

    # Set model
    if [ -n "$custom_model" ]; then
        export ANTHROPIC_MODEL="$custom_model"
        # Check if custom model is available, offer to pull if not
        if ! provider_model_available "$custom_model"; then
            _ollama_ensure_model_available "$custom_model" || true
            # Re-check: if still unavailable after prompt, fail so caller can fall back
            if ! provider_model_available "$ANTHROPIC_MODEL"; then
                print_error "Model '${ANTHROPIC_MODEL}' is not available in Ollama."
                echo "  Pull it with: ollama pull ${ANTHROPIC_MODEL}" >&2
                _provider_restore_env
                return 1
            fi
        fi
    else
        [ "$(_normalize_tier "$tier")" = "fable" ] && _notice_fable_fallback "Ollama"
        export ANTHROPIC_MODEL=$(provider_get_model_id "$tier")
    fi

    # No model available — show guidance and fail so caller can fall back
    if [ -z "$ANTHROPIC_MODEL" ]; then
        print_warning "No Ollama models installed."
        _ollama_print_system_recommendations >&2
        _provider_restore_env
        return 1
    fi

    # Set small/fast model (for background operations)
    export ANTHROPIC_SMALL_FAST_MODEL=$(provider_get_small_model)

    # Warn if no coding-optimized model detected (skip for cloud models)
    if [[ "$ANTHROPIC_MODEL" != *":cloud"* ]]; then
        _ollama_check_model_suitability "$ANTHROPIC_MODEL"
    fi

    return 0
}

provider_cleanup_env() {
    _provider_restore_env
}

provider_get_model_id() {
    local tier=$(_normalize_tier "$1")

    # Ollama model mappings - configurable via secrets.sh
    # First check explicit config, then auto-detect from available models
    case "$tier" in
        fable|high)
            # Fable 5 is Anthropic-only; --fable/--best falls back to the highest local tier
            if [ -n "$OLLAMA_MODEL_HIGH" ]; then
                echo "$OLLAMA_MODEL_HIGH"
            else
                _ollama_auto_detect_model "high"
            fi
            ;;
        mid)
            if [ -n "$OLLAMA_MODEL_MID" ]; then
                echo "$OLLAMA_MODEL_MID"
            else
                _ollama_auto_detect_model "mid"
            fi
            ;;
        low)
            if [ -n "$OLLAMA_MODEL_LOW" ]; then
                echo "$OLLAMA_MODEL_LOW"
            else
                _ollama_auto_detect_model "low"
            fi
            ;;
        *)
            if [ -n "$OLLAMA_MODEL_MID" ]; then
                echo "$OLLAMA_MODEL_MID"
            else
                _ollama_auto_detect_model "mid"
            fi
            ;;
    esac
}

provider_get_small_model() {
    # For Ollama, default to using the SAME model for background operations
    # to avoid costly model swapping (each model needs full VRAM).
    # Users with 24GB+ VRAM can override via OLLAMA_SMALL_FAST_MODEL in secrets.sh
    if [ -n "$OLLAMA_SMALL_FAST_MODEL" ]; then
        echo "$OLLAMA_SMALL_FAST_MODEL"
    else
        # Use same model as main to avoid swapping
        provider_get_model_id "mid"
    fi
}

# Auto-detect best available model for tier
_ollama_auto_detect_model() {
    local tier="$1"
    local models
    local prefer_cloud=false

    # Check if system should prefer cloud (< 16GB effective VRAM)
    if _ollama_should_prefer_cloud; then
        prefer_cloud=true
    fi

    models=$(provider_list_models 2>/dev/null)

    if [ -z "$models" ]; then
        # No models installed — return empty so caller can handle (fallback/messaging)
        echo ""
        return
    fi

    # Model preference patterns (per Ollama docs recommendations)
    # See: https://docs.ollama.com/integrations/claude-code
    # Cloud models have :cloud suffix and run on Ollama's infrastructure
    #
    # VRAM requirements (model + KV cache overhead):
    #   qwen3-coder:30b = 19GB → needs ~28GB effective
    #   gpt-oss:20b = ~12GB → needs ~16GB effective
    #   qwen2.5-coder:14b = ~9GB → needs ~12GB effective
    #   qwen2.5-coder:7b = ~5GB → needs ~8GB effective
    local cloud_patterns=("glm-5:cloud" "minimax-m2.5:cloud" "gpt-oss:120b:cloud")
    # High tier: needs 28GB+ effective VRAM for qwen3-coder:30b
    local high_local=("qwen3-coder" "gpt-oss:20b")
    # Mid tier: needs 16-24GB effective VRAM - avoid qwen3-coder:30b
    local mid_local=("gpt-oss:20b" "qwen2.5-coder:14b" "qwen2.5-coder")
    # Low tier: needs 8-16GB effective VRAM
    local low_local=("qwen2.5-coder:7b" "gemma3")

    # For underpowered systems, try cloud models FIRST (before local)
    if [ "$prefer_cloud" = true ]; then
        # Try cloud patterns
        for pattern in "${cloud_patterns[@]}"; do
            local match
            match=$(echo "$models" | grep -i "$pattern" | head -1)
            if [ -n "$match" ]; then
                echo "$match"
                return
            fi
        done

        # Try any cloud model
        local cloud_match
        cloud_match=$(echo "$models" | grep -i ":cloud" | head -1)
        if [ -n "$cloud_match" ]; then
            echo "$cloud_match"
            return
        fi

        # No cloud models available on underpowered system
        # Interactive mode: prompt user to switch to cloud
        # Script mode: continue silently with local model
        if [[ -t 0 ]] && [[ -t 1 ]]; then
            _ollama_prompt_cloud_switch
            local prompt_result=$?
            if [ $prompt_result -eq 0 ]; then
                # User chose to use cloud - return cloud model
                echo "glm-5:cloud"
                return
            fi
            # User chose to continue with local - fall through
        fi
    fi

    # Build local patterns based on tier
    local patterns=()
    case "$tier" in
        high)
            # High tier can include cloud for capable systems
            if [ "$prefer_cloud" != true ]; then
                patterns+=("gpt-oss:120b:cloud" "glm-5:cloud" "minimax-m2.5:cloud")
            fi
            patterns+=("${high_local[@]}")
            ;;
        low)
            patterns+=("${low_local[@]}")
            ;;
        *)
            patterns+=("${mid_local[@]}")
            ;;
    esac

    # Try each local pattern in order
    for pattern in "${patterns[@]}"; do
        local match
        match=$(echo "$models" | grep -i "$pattern" | head -1)
        if [ -n "$match" ]; then
            echo "$match"
            return
        fi
    done

    # Final fallback to first available model
    local fallback
    fallback=$(echo "$models" | head -1)
    echo "$fallback"
}

# Check if selected model is suitable for coding with Claude Code
_ollama_check_model_suitability() {
    local model="$1"

    # Ollama-recommended models for Claude Code
    # See: https://docs.ollama.com/integrations/claude-code
    local recommended_models="qwen3-coder|glm-5|gpt-oss|qwen2.5-coder|minimax-m2.5"

    if ! echo "$model" | grep -qiE "$recommended_models"; then
        print_warning "Model '$model' may not be optimized for Claude Code."
        print_warning "Ollama recommends these models (64K+ context):"
        print_warning "  ollama pull qwen3-coder    # Coding optimized"
        print_warning "  ollama pull gpt-oss:20b    # Strong general-purpose"
    fi
}

provider_supports_tool() {
    local tool="$1"
    # Ollama supports any tool that uses Anthropic API
    case "$tool" in
        claude-code|cc) return 0 ;;
        opencode)       return 0 ;;
        aider)          return 0 ;;
        *)              return 1 ;;
    esac
}

# Print extra provider-specific info during startup (interactive mode only)
provider_print_extra_info() {
    _ollama_print_capabilities_line
}

# Check if a specific model is available in Ollama
provider_model_available() {
    local model="$1"
    local ollama_url="${OLLAMA_HOST:-http://localhost:11434}"

    # Strip tag if present for matching
    local model_name="${model%%:*}"

    curl -s "${ollama_url}/api/tags" 2>/dev/null | grep -q "\"name\":\"${model_name}"
}

# List available models in Ollama
provider_list_models() {
    local ollama_url="${OLLAMA_HOST:-http://localhost:11434}"
    curl -s "${ollama_url}/api/tags" 2>/dev/null | \
        grep -o '"name":"[^"]*"' | \
        cut -d'"' -f4
}

# Get Ollama server URL
provider_get_url() {
    echo "${OLLAMA_HOST:-http://localhost:11434}"
}

#=============================================================================
# Model Management (Download/Pull)
#=============================================================================

# Download/pull a model from Ollama library
# Usage: _ollama_download_model "model-name"
_ollama_download_model() {
    local model="$1"
    local ollama_url="${OLLAMA_HOST:-http://localhost:11434}"

    echo "Pulling model: $model"
    echo "This may take a while depending on model size..."
    echo ""

    # Use the REST API with streaming
    curl -s -X POST "${ollama_url}/api/pull" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"$model\", \"stream\": true}" 2>&1 | \
    while IFS= read -r line; do
        # Parse streaming JSON response
        local status
        status=$(echo "$line" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

        if [ -n "$status" ]; then
            case "$status" in
                "pulling manifest"|"pulling"*)
                    # Show download progress
                    local completed total
                    completed=$(echo "$line" | grep -o '"completed":[0-9]*' | cut -d: -f2)
                    total=$(echo "$line" | grep -o '"total":[0-9]*' | cut -d: -f2)
                    if [ -n "$completed" ] && [ -n "$total" ] && [ "$total" -gt 0 ]; then
                        local pct=$((completed * 100 / total))
                        printf "\r[%-50s] %d%%" "$(printf '#%.0s' $(seq 1 $((pct / 2))))" "$pct"
                    fi
                    ;;
                "verifying sha256 digest"|"writing manifest"|"success")
                    printf "\r%-60s\n" "$status"
                    ;;
            esac
        fi
    done

    # Verify the model was pulled
    if provider_model_available "$model"; then
        echo ""
        print_success "Model pulled successfully: $model"
        return 0
    else
        echo ""
        print_error "Failed to pull model: $model"
        return 1
    fi
}

# Interactive prompt to download a model if not available
# Called when user specifies a model that doesn't exist
# Always offers choice between local and cloud versions
_ollama_ensure_model_available() {
    local model="$1"

    # Skip if not interactive
    if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
        return 1
    fi

    # Check if model is already available
    if provider_model_available "$model"; then
        return 0
    fi

    # Check if this is already a cloud model
    local is_cloud=false
    if [[ "$model" == *":cloud"* ]]; then
        is_cloud=true
    fi

    echo ""
    print_warning "Model '$model' not found locally."

    # For non-cloud models, offer both local and cloud options
    if [ "$is_cloud" = false ]; then
        local vram=$(_ollama_get_effective_vram)
        local base_model="${model%%:*}"
        local cloud_version="${base_model}:cloud"
        local recommend_cloud=false

        # Determine recommendation based on system capabilities
        if _ollama_should_prefer_cloud; then
            recommend_cloud=true
        fi

        echo ""
        if [ "$recommend_cloud" = true ]; then
            echo "Your system has ~${vram}GB usable VRAM - cloud is recommended."
        else
            echo "Your system has ~${vram}GB usable VRAM."
        fi
        echo ""
        echo "Options:"
        if [ "$recommend_cloud" = true ]; then
            echo "  1) Use cloud version (recommended) - ${cloud_version}"
            echo "     Runs on Ollama's servers, fast on any hardware"
            echo "  2) Pull local version - $model"
            echo "     Runs on your hardware"
        else
            echo "  1) Pull local version (recommended) - $model"
            echo "     Runs on your hardware"
            echo "  2) Use cloud version - ${cloud_version}"
            echo "     Runs on Ollama's servers"
        fi
        echo ""
        read -r -p "Choice [1]: " choice
        choice="${choice:-1}"

        case "$choice" in
            1|"")
                if [ "$recommend_cloud" = true ]; then
                    echo ""
                    print_status "Pulling cloud model: $cloud_version"
                    if _ollama_download_model "$cloud_version"; then
                        export ANTHROPIC_MODEL="$cloud_version"
                        return 0
                    else
                        print_error "Failed to pull cloud model."
                        return 1
                    fi
                else
                    echo ""
                    print_status "Pulling local model: $model"
                    _ollama_download_model "$model"
                    return $?
                fi
                ;;
            2)
                if [ "$recommend_cloud" = true ]; then
                    echo ""
                    print_status "Pulling local model: $model"
                    _ollama_download_model "$model"
                    return $?
                else
                    echo ""
                    print_status "Pulling cloud model: $cloud_version"
                    if _ollama_download_model "$cloud_version"; then
                        export ANTHROPIC_MODEL="$cloud_version"
                        return 0
                    else
                        print_error "Failed to pull cloud model."
                        return 1
                    fi
                fi
                ;;
            *)
                # Default to option 1
                if [ "$recommend_cloud" = true ]; then
                    echo ""
                    print_status "Pulling cloud model: $cloud_version"
                    if _ollama_download_model "$cloud_version"; then
                        export ANTHROPIC_MODEL="$cloud_version"
                        return 0
                    else
                        print_error "Failed to pull cloud model."
                        return 1
                    fi
                else
                    echo ""
                    print_status "Pulling local model: $model"
                    _ollama_download_model "$model"
                    return $?
                fi
                ;;
        esac
    else
        # Already a cloud model - just offer to pull it
        read -r -p "Pull it from Ollama library? [Y/n]: " choice
        choice="${choice:-Y}"

        if [[ "$choice" =~ ^[Yy] ]]; then
            _ollama_download_model "$model"
            return $?
        fi
    fi

    return 1
}
