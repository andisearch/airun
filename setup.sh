#!/bin/bash

# Claude Switcher Setup Script
# Installs Claude Switcher scripts to /usr/local/bin for system-wide access.

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Claude Switcher Setup ===${NC}"

# Configuration
CONFIG_DIR="$HOME/.claude-switcher"
SECRETS_FILE="$CONFIG_DIR/secrets.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
INSTALL_DIR="/usr/local/bin"

# --- 1. Configuration Setup ---

# Create config directory
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Creating config directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
else
    echo "Config directory exists: $CONFIG_DIR"
fi

# Copy secrets template if not exists
if [ ! -f "$SECRETS_FILE" ]; then
    echo "Creating secrets file from template..."
    cp "$PROJECT_ROOT/secrets.example.sh" "$SECRETS_FILE"
    echo -e "${GREEN}Created $SECRETS_FILE${NC}"
    echo "Please edit this file to add your API keys."
else
    echo "Secrets file already exists: $SECRETS_FILE (skipping overwrite)"
fi

# Copy models configuration (always update to get latest model definitions)
MODELS_FILE="$CONFIG_DIR/models.sh"
echo "Copying models configuration..."
cp "$PROJECT_ROOT/config/models.sh" "$MODELS_FILE"
echo -e "${GREEN}Updated $MODELS_FILE${NC}"

# Copy banner configuration
BANNER_FILE="$CONFIG_DIR/banner.sh"
echo "Copying banner configuration..."
cp "$PROJECT_ROOT/config/banner.sh" "$BANNER_FILE"
echo -e "${GREEN}Updated $BANNER_FILE${NC}"


# --- 1b. API Key Helper Setup ---

# Copy API key helper script
API_KEY_HELPER="$CONFIG_DIR/claude-api-key-helper.sh"
echo "Installing API key helper script..."
cp "$PROJECT_ROOT/scripts/claude-api-key-helper.sh" "$API_KEY_HELPER"
chmod +x "$API_KEY_HELPER"
echo -e "${GREEN}Installed $API_KEY_HELPER${NC}"

# Initialize current mode file
CURRENT_MODE_FILE="$CONFIG_DIR/current-mode.sh"
if [ ! -f "$CURRENT_MODE_FILE" ]; then
    echo "Initializing mode configuration..."
    cat > "$CURRENT_MODE_FILE" << 'EOF'
# Current claude-switcher mode
# Used by apiKeyHelper to determine authentication method
# Valid modes: pro, anthropic, aws, vertex, azure
export CLAUDE_SWITCHER_MODE="pro"
EOF
    echo -e "${GREEN}Created $CURRENT_MODE_FILE (default: pro)${NC}"
else
    echo "Mode configuration already exists: $CURRENT_MODE_FILE (preserving)"
fi

# Configure Claude Code settings.json with apiKeyHelper
CLAUDE_SETTINGS_DIR="$HOME/.claude"
CLAUDE_SETTINGS_FILE="$CLAUDE_SETTINGS_DIR/settings.json"

# Note: We do NOT automatically add apiKeyHelper to settings.json
# This would be destructive to the user's existing Claude setup
# Instead, claude-apikey will add it when first run
# And claude-pro will remove it when run

echo ""
echo -e "${GREEN}API Key Helper installed to $API_KEY_HELPER${NC}"
echo ""
echo -e "${YELLOW}Note: apiKeyHelper will be configured in settings.json when you first run 'claude-apikey'${NC}"
echo -e "${YELLOW}It will be removed when you run 'claude-pro' to restore default Claude behavior${NC}"
echo -e "${YELLOW}Plain 'claude' command will always work as it did before installation${NC}"

# --- 2. Script Installation ---

echo ""
echo "Installing scripts to $INSTALL_DIR..."

# Check for sudo access if needed
if [ ! -w "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Note: $INSTALL_DIR is not writable by current user. Sudo access required.${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

# List of scripts to install
SCRIPTS=(
    "claude-run"
    "claude-pro"
    "claude-aws"
    "claude-vertex"
    "claude-apikey"
    "claude-azure"
    "claude-vercel"
    "claude-status"
    "claude-sessions"
    "claude-switcher-utils.sh"
    "claude-settings-manager.sh"
)

# Install each script
for script in "${SCRIPTS[@]}"; do
    source_path="$PROJECT_ROOT/scripts/$script"
    dest_path="$INSTALL_DIR/$script"
    
    if [ -f "$source_path" ]; then
        echo "Installing $script..."
        $SUDO cp "$source_path" "$dest_path"
        $SUDO chmod +x "$dest_path"
    else
        echo -e "${RED}Warning: Source file $source_path not found.${NC}"
    fi
done

# --- 3. Completion ---

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "The following commands are now available system-wide:"
echo "  claude-run          - Unified entry point (recommended)"
echo "  claude-pro          - Switch to Claude Pro Plan mode"
echo "  claude-aws          - Switch to AWS Bedrock mode"
echo "  claude-vertex       - Switch to Google Vertex AI mode"
echo "  claude-apikey       - Switch to Anthropic API mode"
echo "  claude-azure        - Switch to Microsoft Foundry on Azure mode"
echo "  claude-vercel       - Switch to Vercel AI Gateway mode"
echo "  claude-status       - Show current configuration"
echo "  claude-sessions     - List active Claude sessions"
echo ""
echo "Quick start: claude-run --aws --opus"
echo "Run 'claude-run --help' for usage information."
echo ""
echo "You can run this script again at any time to update the installed commands."
