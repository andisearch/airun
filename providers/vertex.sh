#!/bin/bash

# Google Vertex AI Provider
# See: https://code.claude.com/docs/en/google-vertex-ai

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

provider_name() {
    echo "Google Vertex AI"
}

provider_flag() {
    echo "vertex"
}

provider_validate_config() {
    # Require project ID
    if [ -z "$ANTHROPIC_VERTEX_PROJECT_ID" ]; then
        return 1
    fi

    # Require region
    if [ -z "$CLOUD_ML_REGION" ]; then
        return 1
    fi

    # Check authentication methods (in precedence order)
    # 1. GOOGLE_APPLICATION_CREDENTIALS (service account key file)
    # 2. gcloud auth application-default credentials
    # 3. gcloud auth login (user credentials)

    if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        if [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
            _VERTEX_AUTH_METHOD="Service Account Key File"
            return 0
        else
            return 1  # File not found
        fi
    elif [ -f "$HOME/.config/gcloud/application_default_credentials.json" ]; then
        _VERTEX_AUTH_METHOD="Application Default Credentials"
        return 0
    elif command -v gcloud &> /dev/null; then
        local gcloud_account
        gcloud_account=$(gcloud config get-value account 2>/dev/null)
        if [ -n "$gcloud_account" ]; then
            _VERTEX_AUTH_METHOD="gcloud User Credentials ($gcloud_account)"
            return 0
        fi
    fi

    return 1
}

provider_get_auth_method() {
    echo "${_VERTEX_AUTH_METHOD:-Unknown}"
}

provider_get_validation_error() {
    cat << 'EOF'
Google Vertex AI is not configured

To use Vertex AI mode, you need to:
  1. Set ANTHROPIC_VERTEX_PROJECT_ID in your secrets.sh file
  2. Set CLOUD_ML_REGION (e.g., global or us-east5) in your secrets.sh file
  3. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install
  4. Authenticate with: gcloud auth application-default login
  5. Enable Claude models in Vertex AI Model Garden

Example secrets.sh:
  export ANTHROPIC_VERTEX_PROJECT_ID="your-gcp-project-id"
  export CLOUD_ML_REGION="global"

See: https://code.claude.com/docs/en/google-vertex-ai
EOF
}

provider_setup_env() {
    local tier="${1:-mid}"
    local custom_model="$2"

    # Save current environment
    _provider_save_env

    # Disable other providers
    _provider_disable_all

    # Enable Vertex AI
    export CLAUDE_CODE_USE_VERTEX=1

    # Export Vertex-specific variables
    export ANTHROPIC_VERTEX_PROJECT_ID
    export CLOUD_ML_REGION

    # Export region overrides if they exist
    for var in VERTEX_REGION_CLAUDE_3_5_SONNET VERTEX_REGION_CLAUDE_3_5_HAIKU \
               VERTEX_REGION_CLAUDE_3_7_SONNET VERTEX_REGION_CLAUDE_4_0_OPUS \
               VERTEX_REGION_CLAUDE_4_0_SONNET VERTEX_REGION_CLAUDE_4_1_OPUS \
               VERTEX_REGION_CLAUDE_4_5_SONNET VERTEX_REGION_CLAUDE_4_5_OPUS \
               VERTEX_REGION_CLAUDE_4_6_OPUS; do
        if [ -n "${!var}" ]; then
            export $var
        fi
    done

    # Set model
    if [ -n "$custom_model" ]; then
        export ANTHROPIC_MODEL="$custom_model"
    else
        export ANTHROPIC_MODEL=$(provider_get_model_id "$tier")
    fi

    # Set small/fast model
    export ANTHROPIC_SMALL_FAST_MODEL=$(provider_get_small_model)

    # Unset ANTHROPIC_API_KEY to prevent auth conflict
    unset ANTHROPIC_API_KEY

    return 0
}

provider_cleanup_env() {
    _provider_restore_env
}

provider_get_model_id() {
    local tier=$(_normalize_tier "$1")

    case "$tier" in
        high) echo "${CLAUDE_MODEL_OPUS_VERTEX:-claude-opus-4-6}" ;;
        mid)  echo "${CLAUDE_MODEL_SONNET_VERTEX:-claude-sonnet-4-6}" ;;
        low)  echo "${CLAUDE_MODEL_HAIKU_VERTEX:-claude-haiku-4-5@20251001}" ;;
        *)    echo "${CLAUDE_MODEL_SONNET_VERTEX:-claude-sonnet-4-6}" ;;
    esac
}

provider_get_small_model() {
    echo "${CLAUDE_SMALL_FAST_MODEL_VERTEX:-${CLAUDE_MODEL_HAIKU_VERTEX:-claude-haiku-4-5@20251001}}"
}

provider_supports_tool() {
    local tool="$1"
    case "$tool" in
        claude-code|cc) return 0 ;;
        *)              return 1 ;;
    esac
}

provider_get_region() {
    echo "${CLOUD_ML_REGION:-global}"
}

provider_get_project() {
    echo "${ANTHROPIC_VERTEX_PROJECT_ID:-}"
}
