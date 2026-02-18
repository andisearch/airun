#!/bin/bash

# Microsoft Foundry on Azure Provider
# See: https://code.claude.com/docs/en/microsoft-foundry

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

provider_name() {
    echo "Microsoft Azure"
}

provider_flag() {
    echo "azure"
}

provider_validate_config() {
    # Check for resource name or base URL
    if [ -z "$ANTHROPIC_FOUNDRY_RESOURCE" ] && [ -z "$ANTHROPIC_FOUNDRY_BASE_URL" ]; then
        return 1
    fi

    # Check authentication: API key or Azure default credentials
    if [ -n "$ANTHROPIC_FOUNDRY_API_KEY" ]; then
        _AZURE_AUTH_METHOD="API Key"
        return 0
    elif command -v az &> /dev/null; then
        local az_account
        az_account=$(az account show --query name -o tsv 2>/dev/null)
        if [ -n "$az_account" ]; then
            _AZURE_AUTH_METHOD="Azure CLI ($az_account)"
            return 0
        fi
    fi

    return 1
}

provider_get_auth_method() {
    echo "${_AZURE_AUTH_METHOD:-Unknown}"
}

provider_get_validation_error() {
    cat << 'EOF'
Microsoft Foundry on Azure is not configured

To use Azure mode, configure in your secrets.sh:

Option 1: API Key authentication
  export ANTHROPIC_FOUNDRY_API_KEY="your-azure-api-key"

Option 2: Use Azure default credential chain (az login)
  az login

Required: Azure resource name or full base URL
  export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
  # Or provide the full URL:
  export ANTHROPIC_FOUNDRY_BASE_URL="https://your-resource-name.services.ai.azure.com"

See: https://code.claude.com/docs/en/microsoft-foundry
EOF
}

provider_setup_env() {
    local tier="${1:-mid}"
    local custom_model="$2"

    # Save current environment
    _provider_save_env

    # Disable other providers
    _provider_disable_all

    # Enable Foundry
    export CLAUDE_CODE_USE_FOUNDRY=1

    # Export Azure-specific variables
    if [ -n "$ANTHROPIC_FOUNDRY_RESOURCE" ]; then
        export ANTHROPIC_FOUNDRY_RESOURCE
    fi
    if [ -n "$ANTHROPIC_FOUNDRY_BASE_URL" ]; then
        export ANTHROPIC_FOUNDRY_BASE_URL
    fi
    if [ -n "$ANTHROPIC_FOUNDRY_API_KEY" ]; then
        export ANTHROPIC_FOUNDRY_API_KEY
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

    # Azure model names are deployment names (user-defined)
    case "$tier" in
        high) echo "${CLAUDE_MODEL_OPUS_AZURE:-claude-opus-4-6}" ;;
        mid)  echo "${CLAUDE_MODEL_SONNET_AZURE:-claude-sonnet-4-6}" ;;
        low)  echo "${CLAUDE_MODEL_HAIKU_AZURE:-claude-haiku-4-5}" ;;
        *)    echo "${CLAUDE_MODEL_SONNET_AZURE:-claude-sonnet-4-6}" ;;
    esac
}

provider_get_small_model() {
    echo "${CLAUDE_SMALL_FAST_MODEL_AZURE:-${CLAUDE_MODEL_HAIKU_AZURE:-claude-haiku-4-5}}"
}

provider_supports_tool() {
    local tool="$1"
    case "$tool" in
        claude-code|cc) return 0 ;;
        *)              return 1 ;;
    esac
}
