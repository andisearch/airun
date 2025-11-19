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
    "claude-pro"
    "claude-aws"
    "claude-vertex"
    "claude-anthropic"
    "claude-status"
    "claude-sessions"
    "claude-switcher-utils.sh"
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
echo "  claude-pro          - Switch to Claude Pro Plan mode"
echo "  claude-aws          - Switch to AWS Bedrock mode"
echo "  claude-vertex       - Switch to Google Vertex AI mode"
echo "  claude-anthropic    - Switch to Anthropic API mode"
echo "  claude-status       - Show current configuration"
echo "  claude-sessions     - List active Claude sessions"
echo ""
echo "You can run this script again at any time to update the installed commands."
