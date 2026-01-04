#!/bin/bash

# Claude Switcher Uninstall Script
# Removes all installed components

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "=============================================="
echo "  Claude Switcher Uninstall"
echo "=============================================="
echo ""

# Installation directory
INSTALL_DIR="/usr/local/bin"

# Config directory
CONFIG_DIR="$HOME/.claude-switcher"

# List of scripts to remove
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

# --- 1. Check for sudo if needed ---

SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Note: Removing scripts from $INSTALL_DIR requires sudo access.${NC}"
    SUDO="sudo"
fi

# --- 2. Remove installed scripts ---

echo "Removing installed scripts from $INSTALL_DIR..."
echo ""

removed_count=0
for script in "${SCRIPTS[@]}"; do
    script_path="$INSTALL_DIR/$script"
    if [ -f "$script_path" ]; then
        echo "  Removing $script..."
        $SUDO rm -f "$script_path"
        removed_count=$((removed_count + 1))
    else
        echo "  $script (not found, skipping)"
    fi
done

echo ""
if [ $removed_count -gt 0 ]; then
    echo -e "${GREEN}Removed $removed_count script(s) from $INSTALL_DIR${NC}"
else
    echo -e "${YELLOW}No scripts found to remove${NC}"
fi

# --- 3. Handle config directory ---

echo ""
if [ -d "$CONFIG_DIR" ]; then
    echo -e "${YELLOW}Configuration directory found: $CONFIG_DIR${NC}"
    echo ""
    echo "This directory contains:"
    echo "  - secrets.sh (your API keys and credentials)"
    echo "  - models.sh (model configuration)"
    echo "  - claude-api-key-helper.sh (helper script)"
    echo "  - current-mode.sh (current mode state)"
    echo "  - Any temporary state files"
    echo ""
    
    read -p "Do you want to remove this directory? [y/N] " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing $CONFIG_DIR..."
        rm -rf "$CONFIG_DIR"
        echo -e "${GREEN}Configuration directory removed${NC}"
    else
        echo -e "${YELLOW}Configuration directory preserved at $CONFIG_DIR${NC}"
        
        # Clean up temporary state files only
        if ls "$CONFIG_DIR"/apiKeyHelper-state-*.tmp 1> /dev/null 2>&1; then
            echo "Cleaning up temporary state files..."
            rm -f "$CONFIG_DIR"/apiKeyHelper-state-*.tmp
            echo -e "${GREEN}Temporary files removed${NC}"
        fi
    fi
else
    echo -e "${YELLOW}Configuration directory not found: $CONFIG_DIR${NC}"
fi

# --- 4. Check for apiKeyHelper in settings.json ---

CLAUDE_SETTINGS_FILE="$HOME/.claude/settings.json"
API_KEY_HELPER_SCRIPT="$CONFIG_DIR/claude-api-key-helper.sh"

echo ""
if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
    if grep -q "$API_KEY_HELPER_SCRIPT" "$CLAUDE_SETTINGS_FILE" 2>/dev/null; then
        echo -e "${YELLOW}Warning: Your ~/.claude/settings.json references the claude-switcher apiKeyHelper${NC}"
        echo ""
        echo "The helper script path is:"
        echo "  $API_KEY_HELPER_SCRIPT"
        echo ""
        
        if [ ! -f "$API_KEY_HELPER_SCRIPT" ]; then
            echo -e "${RED}The helper script no longer exists (removed or will be removed)${NC}"
            echo ""
            read -p "Do you want to remove the apiKeyHelper reference from settings.json? [Y/n] " -n 1 -r
            echo ""
            
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                # Backup first
                cp "$CLAUDE_SETTINGS_FILE" "$CLAUDE_SETTINGS_FILE.backup-uninstall-$(date +%Y%m%d-%H%M%S)"
                echo "Backed up settings.json"
                
                # Remove apiKeyHelper
                if command -v jq &> /dev/null; then
                    jq 'del(.apiKeyHelper)' "$CLAUDE_SETTINGS_FILE" > "$CLAUDE_SETTINGS_FILE.tmp" && \
                        mv "$CLAUDE_SETTINGS_FILE.tmp" "$CLAUDE_SETTINGS_FILE"
                    echo -e "${GREEN}Removed apiKeyHelper from settings.json${NC}"
                elif command -v python3 &> /dev/null; then
                    python3 << 'EOF'
import json
settings_file = "$CLAUDE_SETTINGS_FILE"
with open(settings_file, 'r') as f:
    settings = json.load(f)
if 'apiKeyHelper' in settings:
    del settings['apiKeyHelper']
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)
EOF
                    echo -e "${GREEN}Removed apiKeyHelper from settings.json${NC}"
                else
                    echo -e "${YELLOW}Cannot automatically remove apiKeyHelper (jq/python3 not found)${NC}"
                    echo "Please manually remove the apiKeyHelper line from:"
                    echo "  $CLAUDE_SETTINGS_FILE"
                fi
            else
                echo -e "${YELLOW}apiKeyHelper reference preserved in settings.json${NC}"
                echo -e "${YELLOW}You may want to manually update this file${NC}"
            fi
        else
            echo -e "${YELLOW}The helper script still exists, so apiKeyHelper reference is valid${NC}"
            echo "If you remove the config directory later, you may need to clean up settings.json"
        fi
    fi
fi

# --- 5. Summary ---

echo ""
echo "=============================================="
echo -e "${GREEN}Uninstall Complete!${NC}"
echo "=============================================="
echo ""
echo "What was removed:"
echo "  ✓ Installed command scripts from $INSTALL_DIR"

if [ ! -d "$CONFIG_DIR" ]; then
    echo "  ✓ Configuration directory ($CONFIG_DIR)"
else
    echo "  - Configuration directory preserved at $CONFIG_DIR"
fi

echo ""
echo "What remains:"
echo "  - Your ~/.claude/settings.json (never modified by claude-switcher)"
echo "  - Any backups in ~/.claude/settings.json.backup-*"

if [ -d "$CONFIG_DIR" ]; then
    echo "  - Your API keys and configuration in $CONFIG_DIR"
    echo ""
    echo "To completely remove all claude-switcher files, run:"
    echo "  rm -rf $CONFIG_DIR"
fi

echo ""
echo "Thank you for using Claude Switcher!"
echo ""
