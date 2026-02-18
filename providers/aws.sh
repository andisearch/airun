#!/bin/bash

# AWS Bedrock Provider
# See: https://code.claude.com/docs/en/amazon-bedrock

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

provider_name() {
    echo "AWS Bedrock"
}

provider_flag() {
    echo "aws"
}

provider_validate_config() {
    # Support three authentication methods:
    # 1. AWS_BEARER_TOKEN_BEDROCK (API key)
    # 2. AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY
    # 3. AWS_PROFILE

    if [ -n "$AWS_BEARER_TOKEN_BEDROCK" ]; then
        _AWS_AUTH_METHOD="AWS Bearer Token"
        return 0
    elif [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
        _AWS_AUTH_METHOD="AWS Access Keys"
        return 0
    elif [ -n "$AWS_PROFILE" ]; then
        _AWS_AUTH_METHOD="AWS Profile ($AWS_PROFILE)"
        return 0
    fi

    return 1
}

provider_get_auth_method() {
    echo "${_AWS_AUTH_METHOD:-Unknown}"
}

provider_get_validation_error() {
    cat << 'EOF'
No AWS credentials configured

To use AWS Bedrock mode, configure one of the following in your secrets.sh:

Option 1: AWS Bedrock API Key (recommended for simplicity)
  export AWS_BEARER_TOKEN_BEDROCK="your-bedrock-api-key"

Option 2: AWS Access Keys
  export AWS_ACCESS_KEY_ID="your_access_key"
  export AWS_SECRET_ACCESS_KEY="your_secret_key"
  export AWS_SESSION_TOKEN="your_session_token"  # Optional

Option 3: AWS Profile
  export AWS_PROFILE="your-profile-name"

All options require:
  export AWS_REGION="us-west-2"  # or your preferred region

See: https://code.claude.com/docs/en/amazon-bedrock
EOF
}

provider_setup_env() {
    local tier="${1:-mid}"
    local custom_model="$2"

    # Save current environment
    _provider_save_env

    # Disable other providers
    _provider_disable_all

    # Enable Bedrock
    export CLAUDE_CODE_USE_BEDROCK=1

    # Validate AWS_REGION
    if [ -z "$AWS_REGION" ]; then
        print_error "AWS_REGION is not set"
        print_error "Please set AWS_REGION in your secrets.sh: export AWS_REGION=\"us-west-2\""
        return 1
    fi

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
        high) echo "${CLAUDE_MODEL_OPUS_AWS:-global.anthropic.claude-opus-4-6-v1}" ;;
        mid)  echo "${CLAUDE_MODEL_SONNET_AWS:-global.anthropic.claude-sonnet-4-6}" ;;
        low)  echo "${CLAUDE_MODEL_HAIKU_AWS:-us.anthropic.claude-haiku-4-5-20251001-v1:0}" ;;
        *)    echo "${CLAUDE_MODEL_SONNET_AWS:-global.anthropic.claude-sonnet-4-6}" ;;
    esac
}

provider_get_small_model() {
    echo "${CLAUDE_SMALL_FAST_MODEL_AWS:-${CLAUDE_MODEL_HAIKU_AWS:-us.anthropic.claude-haiku-4-5-20251001-v1:0}}"
}

provider_supports_tool() {
    local tool="$1"
    case "$tool" in
        claude-code|cc) return 0 ;;
        *)              return 1 ;;  # Only Claude Code supported for now
    esac
}

provider_get_region() {
    echo "${AWS_REGION:-us-west-2}"
}
