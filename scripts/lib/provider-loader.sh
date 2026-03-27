#!/bin/bash

# Provider Loader
# Dynamically loads and manages providers for AI Runner

# Only set PROVIDER_DIR if not already set by caller
if [ -z "$PROVIDER_DIR" ]; then
    _LOADER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROVIDER_DIR="$(cd "$_LOADER_SCRIPT_DIR/../../providers" 2>/dev/null && pwd)"
fi

# Currently loaded provider
_CURRENT_PROVIDER=""
_CURRENT_PROVIDER_FILE=""

# Get provider file for a flag name
_get_provider_file() {
    local flag="$1"
    case "$flag" in
        aws)            echo "aws.sh" ;;
        vertex)         echo "vertex.sh" ;;
        apikey)         echo "apikey.sh" ;;
        azure)          echo "azure.sh" ;;
        vercel)         echo "vercel.sh" ;;
        pro)            echo "pro.sh" ;;
        ollama)         echo "ollama.sh" ;;
        lmstudio|lm)    echo "lmstudio.sh" ;;
        *)              echo "" ;;
    esac
}

# Load a provider by flag name
load_provider() {
    local flag="$1"

    if [ -z "$flag" ]; then
        return 1
    fi

    local provider_file
    provider_file=$(_get_provider_file "$flag")
    if [ -z "$provider_file" ]; then
        print_error "Unknown provider: $flag"
        print_error "Available providers: aws, vertex, apikey, azure, vercel, pro, ollama, lmstudio"
        return 1
    fi

    local full_path="$PROVIDER_DIR/$provider_file"
    if [ ! -f "$full_path" ]; then
        print_error "Provider file not found: $full_path"
        return 1
    fi

    # Source the provider
    source "$full_path"
    _CURRENT_PROVIDER="$flag"
    _CURRENT_PROVIDER_FILE="$full_path"

    return 0
}

# Get current provider flag
get_current_provider() {
    echo "$_CURRENT_PROVIDER"
}

# Check if any provider is loaded
is_provider_loaded() {
    [ -n "$_CURRENT_PROVIDER" ]
}

# List all available provider flags
list_providers() {
    echo "aws vertex apikey azure vercel pro ollama lmstudio"
}

# Detect default provider based on available credentials
# Returns the first provider that validates successfully
#
# Priority order:
# 1. Explicit DEFAULT_PROVIDER in config
# 2. Claude Pro (if Claude Code installed AND logged in with subscription)
# 3. Ollama (if running locally)
# 4. API providers (anthropic, aws, vertex, etc.)
detect_default_provider() {
    # 1. Check explicitly configured provider in secrets.sh
    if [ -n "$DEFAULT_PROVIDER" ]; then
        if load_provider "$DEFAULT_PROVIDER" && provider_validate_config 2>/dev/null; then
            echo "$DEFAULT_PROVIDER"
            return 0
        fi
    fi

    # 2. Claude Pro (subscription) - prioritize subscription users
    # Check if Claude Code is installed AND user is logged in with subscription
    if command -v claude &>/dev/null; then
        # Check for credentials across platforms:
        # - macOS: Keychain as "Claude Code-credentials"
        # - Linux/WSL: ~/.claude/.credentials.json
        local has_credentials=false
        if command -v security &>/dev/null && security find-generic-password -s "Claude Code-credentials" &>/dev/null 2>&1; then
            has_credentials=true  # macOS keychain
        elif [ -f "$HOME/.claude/.credentials.json" ]; then
            has_credentials=true  # Linux/WSL credential file
        fi

        if [ "$has_credentials" = true ]; then
            if load_provider "pro" && provider_validate_config 2>/dev/null; then
                echo "pro"
                return 0
            fi
        fi
    fi

    # 3. Ollama (local, free, no API costs) - only if Claude not subscribed
    if load_provider "ollama" && provider_validate_config 2>/dev/null; then
        echo "ollama"
        return 0
    fi

    # 4. Anthropic API direct (--apikey)
    if load_provider "apikey" && provider_validate_config 2>/dev/null; then
        echo "apikey"
        return 0
    fi

    # 5. AWS Bedrock (--aws)
    if load_provider "aws" && provider_validate_config 2>/dev/null; then
        echo "aws"
        return 0
    fi

    # 6. Google Vertex (--vertex)
    if load_provider "vertex" && provider_validate_config 2>/dev/null; then
        echo "vertex"
        return 0
    fi

    # 7. Vercel AI Gateway
    if load_provider "vercel" && provider_validate_config 2>/dev/null; then
        echo "vercel"
        return 0
    fi

    # 8. Azure
    if load_provider "azure" && provider_validate_config 2>/dev/null; then
        echo "azure"
        return 0
    fi

    # No provider available
    echo ""
    return 1
}

# Print provider not found error with helpful message
print_no_provider_error() {
    print_error "No AI provider configured."
    print_error ""
    print_error "Quick start with Ollama (free, local):"
    print_error "  1. Install Ollama:"
    print_error "     macOS: brew install ollama"
    print_error "     Linux: curl -fsSL https://ollama.com/install.sh | sh"
    print_error "  2. Start:   ollama serve"
    print_error "  3. Pull:    ollama pull qwen3-coder"
    print_error "  4. Run:     ai task.md"
    print_error ""
    print_error "Or configure a cloud provider in ~/.ai-runner/secrets.sh"
    print_error "Available providers: aws, vertex, apikey, azure, vercel, pro, ollama, lmstudio"
}
