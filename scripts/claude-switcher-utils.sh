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
MODELS_FILE="${CONFIG_DIR}/models.sh"
BANNER_FILE="${CONFIG_DIR}/banner.sh"

# Display banner function - sources and calls the show_banner function from banner.sh
display_banner() {
    if [ -f "$BANNER_FILE" ]; then
        source "$BANNER_FILE"
        show_banner
    fi
}


# Version Detection
# Try to find project root (where VERSION file lives)
if [ -n "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    PROJECT_ROOT="/usr/local/share/claude-switcher"
fi

# Read version from VERSION file
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    SWITCHER_VERSION=$(cat "$PROJECT_ROOT/VERSION")
elif [ -f "/usr/local/share/claude-switcher/VERSION" ]; then
    SWITCHER_VERSION=$(cat "/usr/local/share/claude-switcher/VERSION")
else
    SWITCHER_VERSION="unknown"
fi

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
# Sets ANTHROPIC_MODEL (main model) and ANTHROPIC_SMALL_FAST_MODEL (for background operations)
# Per Claude Code docs, the small/fast model is used for:
#   - Background file operations
#   - Sub-agent operations  
#   - Other auxiliary tasks
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
        # Use provider-specific model variable
        # These are defined in config/models.sh and can be overridden in secrets.sh
        local model_var="CLAUDE_MODEL_${selected_model}_${provider}"
        
        if [ -n "${!model_var}" ]; then
            export ANTHROPIC_MODEL="${!model_var}"
            print_status "Selected ${selected_model} Model: $ANTHROPIC_MODEL"
        else
            print_warning "No model configuration found for ${selected_model} on ${provider}"
            print_warning "Set ${model_var} in secrets.sh"
        fi
    fi
    
    # Set the small/fast model for background operations (sub-agents, file ops, etc.)
    # Uses CLAUDE_SMALL_FAST_MODEL_{PROVIDER} which defaults to Haiku but can be overridden
    local small_fast_var="CLAUDE_SMALL_FAST_MODEL_${provider}"
    if [ -n "${!small_fast_var}" ]; then
        export ANTHROPIC_SMALL_FAST_MODEL="${!small_fast_var}"
        print_status "Small/Fast Model (background ops): $ANTHROPIC_SMALL_FAST_MODEL"
    else
        print_warning "No small/fast model configured for ${provider}"
        print_warning "Background operations may use Claude Code defaults"
    fi
}


# Common cleanup/restore function
restore_env() {
    # This should be called by trap
    # It restores variables that were modified
    # Implementation depends on what was saved by the calling script
    :
}
