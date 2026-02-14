#!/bin/bash

# AI Runner Core Utilities
# Shared utilities for AI Runner and backward-compatible Claude Switcher commands

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Branding - can be set by caller before sourcing
# Defaults to "AI Runner" for new commands, "Claude Switcher" for legacy
AI_RUNNER_BRAND="${AI_RUNNER_BRAND:-AI Runner}"

# Determine if stdout is connected to a terminal (interactive mode)
is_interactive() {
    [[ -t 1 ]]
}

# Configuration Paths
# Support both new (~/.ai-runner/) and legacy (~/.claude-switcher/) locations
if [ -n "$AI_RUNNER_CONFIG_DIR" ]; then
    CONFIG_DIR="$AI_RUNNER_CONFIG_DIR"
elif [ -d "$HOME/.ai-runner" ]; then
    CONFIG_DIR="$HOME/.ai-runner"
else
    CONFIG_DIR="$HOME/.claude-switcher"
fi

SECRETS_FILE="${CONFIG_DIR}/secrets.sh"
MODELS_FILE="${CONFIG_DIR}/models.sh"
BANNER_FILE="${CONFIG_DIR}/banner.sh"
SESSIONS_DIR="${CONFIG_DIR}/sessions"

# Version Detection
_detect_version() {
    local script_dir=""
    local project_root=""

    if [ -n "${BASH_SOURCE[0]}" ]; then
        script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        project_root="$(cd "$script_dir/../.." 2>/dev/null && pwd)"
    fi

    # Check multiple locations for VERSION file
    if [ -f "$project_root/VERSION" ]; then
        cat "$project_root/VERSION"
    elif [ -f "/usr/local/share/ai-runner/VERSION" ]; then
        cat "/usr/local/share/ai-runner/VERSION"
    elif [ -f "/usr/local/share/claude-switcher/VERSION" ]; then
        cat "/usr/local/share/claude-switcher/VERSION"
    else
        echo "unknown"
    fi
}

AI_RUNNER_VERSION=$(_detect_version)
SWITCHER_VERSION="$AI_RUNNER_VERSION"  # Backward compatibility

# Print functions with configurable branding
# AI_QUIET suppresses status/success/info but NOT error/warning
print_status() {
    [[ "$AI_QUIET" == true ]] && return
    echo -e "${BLUE}[${AI_RUNNER_BRAND}]${NC} $1" >&2
}

print_success() {
    [[ "$AI_QUIET" == true ]] && return
    echo -e "${GREEN}[${AI_RUNNER_BRAND}]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[${AI_RUNNER_BRAND}]${NC} $1" >&2
}

print_error() {
    echo -e "${RED}[${AI_RUNNER_BRAND}]${NC} $1" >&2
}

print_info() {
    [[ "$AI_QUIET" == true ]] && return
    echo -e "${CYAN}[${AI_RUNNER_BRAND}]${NC} $1" >&2
}

# Display banner function
display_banner() {
    if ! is_interactive; then
        return
    fi
    if [ -f "$BANNER_FILE" ]; then
        source "$BANNER_FILE"
        if declare -f show_banner &>/dev/null; then
            show_banner
        fi
    fi
}

# Load configuration (secrets and models)
load_config() {
    # Load models configuration
    if [ -f "$MODELS_FILE" ]; then
        source "$MODELS_FILE"
    fi

    # Load secrets
    if [ -f "$SECRETS_FILE" ]; then
        source "$SECRETS_FILE"
        print_status "Loaded secrets from $SECRETS_FILE"
    fi
}

# Load config silently (no output)
load_config_quiet() {
    if [ -f "$MODELS_FILE" ]; then
        source "$MODELS_FILE"
    fi
    if [ -f "$SECRETS_FILE" ]; then
        source "$SECRETS_FILE"
    fi
}

# Defaults file for persistent user preferences (set by --set-default)
DEFAULTS_FILE="${CONFIG_DIR}/defaults.sh"

load_defaults() {
    [ -f "$DEFAULTS_FILE" ] && source "$DEFAULTS_FILE" || true
}

save_defaults() {
    local provider="$1" model_tier="$2" custom_model="$3" team_mode="${4:-}" teammate_mode="${5:-}"
    mkdir -p "$CONFIG_DIR"
    cat > "$DEFAULTS_FILE" << EOF
# AI Runner defaults (set by: ai --set-default)
AI_DEFAULT_PROVIDER="$provider"
AI_DEFAULT_MODEL_TIER="$model_tier"
AI_DEFAULT_CUSTOM_MODEL="$custom_model"
AI_DEFAULT_TEAM_MODE="$team_mode"
AI_DEFAULT_TEAMMATE_MODE="$teammate_mode"
EOF
    local desc="${provider}"
    [[ -n "$model_tier" ]] && desc+=" --${model_tier}"
    [[ -n "$custom_model" ]] && desc+=" --model ${custom_model}"
    [[ -n "$team_mode" ]] && desc+=" --team"
    [[ -n "$teammate_mode" ]] && desc+=" --teammate-mode ${teammate_mode}"
    print_success "Saved default: ${desc}"
}

clear_defaults() {
    rm -f "$DEFAULTS_FILE"
    print_success "Defaults cleared. 'ai' will use your Claude subscription (same as 'claude')."
}

format_defaults() {
    if [ ! -f "$DEFAULTS_FILE" ]; then return 1; fi
    local desc="${AI_DEFAULT_PROVIDER}"
    [[ -z "$desc" ]] && return 1
    [[ -n "$AI_DEFAULT_MODEL_TIER" ]] && desc+=" --${AI_DEFAULT_MODEL_TIER}"
    [[ -n "$AI_DEFAULT_CUSTOM_MODEL" ]] && desc+=" --model ${AI_DEFAULT_CUSTOM_MODEL}"
    [[ -n "$AI_DEFAULT_TEAM_MODE" ]] && desc+=" --team"
    [[ -n "$AI_DEFAULT_TEAMMATE_MODE" ]] && desc+=" --teammate-mode ${AI_DEFAULT_TEAMMATE_MODE}"
    echo "$desc"
}

# Helper to parse model arguments
# Usage: parse_model_args "PROVIDER_SUFFIX" "$@"
# Sets ANTHROPIC_MODEL and ANTHROPIC_SMALL_FAST_MODEL
parse_model_args() {
    local provider="$1"
    shift

    local selected_model="SONNET"
    local custom_model_id=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --opus|--high)
                selected_model="OPUS"
                shift
                ;;
            --sonnet|--mid)
                selected_model="SONNET"
                shift
                ;;
            --haiku|--low)
                selected_model="HAIKU"
                shift
                ;;
            --model)
                selected_model="CUSTOM"
                custom_model_id="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done

    if [ "$selected_model" == "CUSTOM" ]; then
        export ANTHROPIC_MODEL="$custom_model_id"
        print_status "Selected Custom Model: $ANTHROPIC_MODEL"
    else
        local model_var="CLAUDE_MODEL_${selected_model}_${provider}"

        if [ -n "${!model_var}" ]; then
            export ANTHROPIC_MODEL="${!model_var}"
            print_status "Selected ${selected_model} Model: $ANTHROPIC_MODEL"
        else
            print_warning "No model configuration found for ${selected_model} on ${provider}"
        fi
    fi

    # Set the small/fast model for background operations
    local small_fast_var="CLAUDE_SMALL_FAST_MODEL_${provider}"
    if [ -n "${!small_fast_var}" ]; then
        export ANTHROPIC_SMALL_FAST_MODEL="${!small_fast_var}"
        print_status "Small/Fast Model: $ANTHROPIC_SMALL_FAST_MODEL"
    fi
}

# Session Management

# Write session information to tracking file
write_session_info() {
    local provider="$1"
    local mode="$2"
    local model="$3"
    local small_model="$4"
    local region="$5"
    local project="$6"
    local auth_method="$7"
    local tool="${8:-claude-code}"
    local teams="${9:-}"

    mkdir -p "$SESSIONS_DIR"

    local session_file="$SESSIONS_DIR/$$"
    cat > "$session_file" <<EOF
AI_SESSION_ID="${tool}-${provider}-$$-$(date +%s)"
AI_SESSION_TOOL="${tool}"
AI_SESSION_PROVIDER="${provider}"
AI_SESSION_MODE="${mode}"
AI_SESSION_MODEL="${model}"
AI_SESSION_SMALL_MODEL="${small_model}"
AI_SESSION_REGION="${region}"
AI_SESSION_PROJECT="${project}"
AI_SESSION_AUTH_METHOD="${auth_method}"
AI_SESSION_TEAMS="${teams}"
AI_SESSION_START_TIME="$(date +%s)"
AI_SESSION_PID="$$"
EOF

    # Backward compatibility: also write with CLAUDE_ prefix
    cat >> "$session_file" <<EOF
CLAUDE_SESSION_ID="${AI_SESSION_ID:-}"
CLAUDE_SESSION_PROVIDER="${provider}"
CLAUDE_SESSION_MODE="${mode}"
CLAUDE_SESSION_MODEL="${model}"
CLAUDE_SESSION_SMALL_MODEL="${small_model}"
CLAUDE_SESSION_REGION="${region}"
CLAUDE_SESSION_PROJECT="${project}"
CLAUDE_SESSION_AUTH_METHOD="${auth_method}"
CLAUDE_SESSION_START_TIME="$(date +%s)"
CLAUDE_SESSION_PID="$$"
EOF
}

# Clean up session info file when session exits
cleanup_session_info() {
    local session_file="$SESSIONS_DIR/$$"
    if [ -f "$session_file" ]; then
        rm -f "$session_file"
    fi
}

# Clean up stale session files (PIDs that no longer exist)
cleanup_stale_sessions() {
    if [ ! -d "$SESSIONS_DIR" ]; then
        return
    fi

    for session_file in "$SESSIONS_DIR"/*; do
        if [ ! -f "$session_file" ]; then
            continue
        fi

        local pid=$(basename "$session_file")

        # Check if process exists
        if ! ps -p "$pid" > /dev/null 2>&1; then
            rm -f "$session_file"
        elif ! ps -p "$pid" -o command= 2>/dev/null | grep -qE "claude|ai|airun"; then
            # PID exists but is not a related process (PID got reused)
            rm -f "$session_file"
        fi
    done
}

# Config Migration (for ai command)

# Check if migration is needed
needs_config_migration() {
    # Skip if explicitly disabled
    [ "$AI_RUNNER_SKIP_MIGRATION" = "1" ] && return 1

    # Skip if already using ai-runner config
    [ -d "$HOME/.ai-runner" ] && return 1

    # Migration needed if claude-switcher config exists
    [ -d "$HOME/.claude-switcher" ]
}

# Perform config migration interactively
migrate_config_interactive() {
    if ! is_interactive; then
        # Non-interactive: use claude-switcher directory without copying
        CONFIG_DIR="$HOME/.claude-switcher"
        return 0
    fi

    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  AI Runner - Configuration Migration                        │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│  Found existing config at ~/.claude-switcher/               │"
    echo "│                                                             │"
    echo "│  How would you like to proceed?                             │"
    echo "│                                                             │"
    echo "│  [1] Copy to ~/.ai-runner/ (recommended)                    │"
    echo "│      - Creates new config directory                         │"
    echo "│      - Keeps original ~/.claude-switcher/ intact            │"
    echo "│                                                             │"
    echo "│  [2] Symlink ~/.ai-runner/ → ~/.claude-switcher/            │"
    echo "│      - Single config location                               │"
    echo "│                                                             │"
    echo "│  [3] Keep using ~/.claude-switcher/ only                    │"
    echo "│      - No new directory created                             │"
    echo "│                                                             │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    read -p "  Choice [1/2/3]: " choice

    case "$choice" in
        1)
            mkdir -p "$HOME/.ai-runner"
            cp -r "$HOME/.claude-switcher/"* "$HOME/.ai-runner/" 2>/dev/null
            CONFIG_DIR="$HOME/.ai-runner"
            echo ""
            print_success "Configuration copied to ~/.ai-runner/"
            ;;
        2)
            ln -s "$HOME/.claude-switcher" "$HOME/.ai-runner"
            CONFIG_DIR="$HOME/.ai-runner"
            echo ""
            print_success "Symlink created: ~/.ai-runner/ → ~/.claude-switcher/"
            ;;
        3|*)
            CONFIG_DIR="$HOME/.claude-switcher"
            echo ""
            print_status "Using existing ~/.claude-switcher/"
            ;;
    esac

    # Update paths
    SECRETS_FILE="${CONFIG_DIR}/secrets.sh"
    MODELS_FILE="${CONFIG_DIR}/models.sh"
    BANNER_FILE="${CONFIG_DIR}/banner.sh"
    SESSIONS_DIR="${CONFIG_DIR}/sessions"
}

# Common cleanup/restore function (can be extended by scripts)
restore_env() {
    :
}

#=============================================================================
# First-Time Setup
#=============================================================================

# Check if first-time setup is needed
needs_first_time_setup() {
    # Skip if setup already done
    [ -f "$CONFIG_DIR/.setup-complete" ] && return 1

    # Skip if DEFAULT_PROVIDER is already set in config
    if [ -f "$SECRETS_FILE" ]; then
        source "$SECRETS_FILE" 2>/dev/null
        [ -n "$DEFAULT_PROVIDER" ] && return 1

        # Skip wizard for migrated users with API keys configured
        # They already have credentials, just auto-detect for them
        if [ -n "$ANTHROPIC_API_KEY" ] || [ -n "$AWS_PROFILE" ] || \
           [ -n "$ANTHROPIC_VERTEX_PROJECT_ID" ] || [ -n "$VERCEL_AI_GATEWAY_TOKEN" ]; then
            return 1
        fi
    fi

    # Setup needed for fresh installs
    return 0
}

# Detect system capabilities
detect_system_capabilities() {
    local caps=""

    # Check Claude Code
    if command -v claude &>/dev/null; then
        caps="${caps}claude-code,"
        # Check for credentials across platforms:
        # - macOS: Keychain as "Claude Code-credentials"
        # - Linux/WSL: ~/.claude/.credentials.json
        if command -v security &>/dev/null && security find-generic-password -s "Claude Code-credentials" &>/dev/null 2>&1; then
            caps="${caps}claude-subscribed,"  # macOS keychain
        elif [ -f "$HOME/.claude/.credentials.json" ]; then
            caps="${caps}claude-subscribed,"  # Linux/WSL credential file
        fi
    fi

    # Check Ollama
    if command -v ollama &>/dev/null; then
        caps="${caps}ollama-installed,"
        if curl -s --connect-timeout 2 "http://localhost:11434/api/tags" &>/dev/null; then
            caps="${caps}ollama-running,"
        fi
    fi

    # Check for API keys in environment
    [ -n "$ANTHROPIC_API_KEY" ] && caps="${caps}anthropic-api,"
    [ -n "$AWS_PROFILE" ] || [ -n "$AWS_ACCESS_KEY_ID" ] && caps="${caps}aws,"
    [ -n "$ANTHROPIC_VERTEX_PROJECT_ID" ] && caps="${caps}vertex,"

    echo "$caps"
}

# Interactive first-time setup
run_first_time_setup() {
    local caps
    caps=$(detect_system_capabilities)

    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  AI Runner - First Time Setup                               │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""

    # Show what's detected
    echo "Detected:"
    [[ "$caps" == *"claude-code"* ]] && echo "  ✓ Claude Code installed"
    [[ "$caps" == *"claude-subscribed"* ]] && echo "  ✓ Claude Pro/Max subscription active"
    [[ "$caps" == *"ollama-installed"* ]] && echo "  ✓ Ollama installed"
    [[ "$caps" == *"ollama-running"* ]] && echo "  ✓ Ollama server running"
    echo ""

    # Determine recommended default
    local recommended=""

    # Case 1: Both Claude subscription AND Ollama available - ask user
    if [[ "$caps" == *"claude-subscribed"* ]] && [[ "$caps" == *"ollama-running"* ]]; then
        echo "You have multiple AI options available!"
        echo ""
        echo "  [1] Claude Pro subscription (paid, cloud-based)"
        echo "  [2] Ollama (free, runs locally)"
        echo ""
        read -p "Choose your default provider [1/2]: " choice
        case "$choice" in
            2) recommended="ollama"; _setup_ollama_models ;;
            *) recommended="pro" ;;
        esac

    # Case 2: Only Claude subscription
    elif [[ "$caps" == *"claude-subscribed"* ]]; then
        recommended="pro"
        echo "Using Claude Pro subscription as default."

    # Case 3: Only Ollama running
    elif [[ "$caps" == *"ollama-running"* ]]; then
        recommended="ollama"
        echo "Using Ollama (free, local) as default."
        _setup_ollama_models

    # Case 4: Claude Code installed but not logged in
    elif [[ "$caps" == *"claude-code"* ]]; then
        echo "Claude Code is installed but no subscription detected."
        echo ""
        echo "Options:"
        echo "  1. Run 'claude login' to sign in with Claude Pro/Max"
        echo "  2. Install Ollama for free local use:"
        echo "     macOS: brew install ollama"
        echo "     Linux: curl -fsSL https://ollama.com/install.sh | sh"
        echo "  3. Configure API keys in ~/.ai-runner/secrets.sh"
        return 1

    # Case 5: Nothing available
    else
        echo "No AI tool detected."
        echo ""
        echo "To get started, install Claude Code:"
        echo "  curl -fsSL https://claude.ai/install.sh | bash"
        echo ""
        echo "Or install Ollama for free local AI:"
        echo "  macOS: brew install ollama && ollama serve"
        echo "  Linux: curl -fsSL https://ollama.com/install.sh | sh && ollama serve"
        return 1
    fi

    # Save preference
    _save_default_provider "$recommended"
}

# Helper: Setup Ollama models
_setup_ollama_models() {
    local models
    models=$(curl -s "http://localhost:11434/api/tags" 2>/dev/null | grep -o '"name":"[^"]*"' | cut -d'"' -f4)

    if [ -z "$models" ]; then
        echo ""
        echo "No models installed in Ollama."
        echo ""
        read -p "Pull recommended model (qwen3-coder:32b)? [Y/n] " choice
        if [[ ! "$choice" =~ ^[Nn] ]]; then
            echo "Pulling qwen3-coder:32b (this may take a while)..."
            ollama pull qwen3-coder:32b
        fi
    else
        echo ""
        echo "Available Ollama models:"
        echo "$models" | while read -r model; do echo "  - $model"; done
    fi
}

# Helper: Save default provider to config
_save_default_provider() {
    local provider="$1"
    mkdir -p "$CONFIG_DIR"

    if [ -f "$SECRETS_FILE" ]; then
        # Append or update DEFAULT_PROVIDER
        if grep -q "^DEFAULT_PROVIDER=" "$SECRETS_FILE"; then
            # Cross-platform sed -i (macOS uses -i '', Linux uses -i)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s/^DEFAULT_PROVIDER=.*/DEFAULT_PROVIDER=\"$provider\"/" "$SECRETS_FILE"
            else
                sed -i "s/^DEFAULT_PROVIDER=.*/DEFAULT_PROVIDER=\"$provider\"/" "$SECRETS_FILE"
            fi
        else
            echo "" >> "$SECRETS_FILE"
            echo "# Default provider (set by first-time setup)" >> "$SECRETS_FILE"
            echo "DEFAULT_PROVIDER=\"$provider\"" >> "$SECRETS_FILE"
        fi
    else
        # Create minimal secrets file
        cat > "$SECRETS_FILE" << EOF
#!/bin/bash
# AI Runner Configuration
# Created by first-time setup

# Default provider
DEFAULT_PROVIDER="$provider"
EOF
    fi

    touch "$CONFIG_DIR/.setup-complete"
    print_success "Default provider set to: $provider"
}
