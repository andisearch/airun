#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration Paths
CONFIG_DIR="${HOME}/.claude-switcher"
SECRETS_FILE="${CONFIG_DIR}/secrets.sh"
# Get the directory where this script resides (scripts/) and go up one level to find config/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_FILE="${PROJECT_ROOT}/config/models.sh"

print_status() {
    echo -e "${BLUE}[Claude Switcher]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[Claude Switcher]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[Claude Switcher]${NC} $1"
}

print_error() {
    echo -e "${RED}[Claude Switcher]${NC} $1"
}

load_config() {
    # Load models configuration
    if [ -f "$MODELS_FILE" ]; then
        source "$MODELS_FILE"
    else
        print_warning "Models configuration not found at $MODELS_FILE. Using defaults if available."
    fi

    # Load secrets
    if [ -f "$SECRETS_FILE" ]; then
        source "$SECRETS_FILE"
        print_status "Loaded secrets from $SECRETS_FILE"
    else
        print_warning "Secrets file not found at $SECRETS_FILE."
        print_warning "Please copy config/secrets.example.sh to $SECRETS_FILE and configure your keys."
    fi
}

# Helper to parse model arguments
# Usage: parse_model_args "PROVIDER_SUFFIX" "$@"
# Sets ANTHROPIC_MODEL based on flags
parse_model_args() {
    local provider="$1"
    shift
    local model_var_name=""
    
    # Default to Sonnet if no specific model flag is passed
    local selected_model="SONNET"
    local custom_model_id=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --opus)
                selected_model="OPUS"
                shift
                ;;
            --sonnet)
                selected_model="SONNET"
                shift
                ;;
            --haiku)
                selected_model="HAIKU"
                shift
                ;;
            --model)
                selected_model="CUSTOM"
                custom_model_id="$2"
                shift 2
                ;;
            *)
                # Pass through other arguments to claude
                break
                ;;
        esac
    done

    if [ "$selected_model" == "CUSTOM" ]; then
        export ANTHROPIC_MODEL="$custom_model_id"
        print_status "Selected Custom Model: $ANTHROPIC_MODEL"
    else
        # Construct variable name like CLAUDE_MODEL_SONNET_AWS
        local config_var="CLAUDE_MODEL_${selected_model}_${provider}"
        export ANTHROPIC_MODEL="${!config_var}"
        print_status "Selected ${selected_model} Model: $ANTHROPIC_MODEL"
    fi
}

# Common cleanup/restore function
restore_env() {
    # This should be called by trap
    # It restores variables that were modified
    # Implementation depends on what was saved by the calling script
    :
}
