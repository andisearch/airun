#!/bin/bash

# Tool Base Interface
# All tools must implement these functions

# Tool Interface Functions:
#
# tool_name()                  - Return human-readable tool name
# tool_flag()                  - Return CLI flag/shorthand (e.g., "cc", "opencode")
# tool_command()               - Return actual CLI command to execute
# tool_is_installed()          - Check if tool is installed (return 0=yes, 1=no)
# tool_supported_providers()   - Return list of compatible provider flags
# tool_execute_interactive()   - Run tool in interactive mode
# tool_execute_prompt()        - Run tool with a prompt (shebang/piped mode)
# tool_setup_env()             - Tool-specific environment setup
# tool_needs_provider()        - Does this tool need the provider system? (default: yes)
#                                Return 1 for tools that manage their own backend
# tool_get_backend_info()      - Return backend description for status display (optional)

# Helper to check if a command exists
_tool_command_exists() {
    command -v "$1" &>/dev/null
}

# Execute a tool with arguments, handling common patterns
_tool_run() {
    local cmd="$1"
    shift
    exec "$cmd" "$@"
}

# Pipe content to a tool in print/prompt mode
_tool_pipe_prompt() {
    local cmd="$1"
    local prompt="$2"
    shift 2
    echo "$prompt" | "$cmd" -p "$@"
}

# Cache tool flags from --help output for cross-interpreter flag validation
# Parses --help (and optional subcommand --help) to extract supported flags
# Cache is keyed by tool version — regenerates automatically on upgrade
# Usage: _cache_tool_flags <command> [subcommand1 ...]
# Prints: path to cache file
_cache_tool_flags() {
    local cmd="$1"; shift
    local version
    version=$("$cmd" --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+[.0-9]*' | head -1)
    [[ -z "$version" ]] && version="unknown"
    local cache_dir="${CONFIG_DIR:-$HOME/.ai-runner}/cache"
    local cache_file="$cache_dir/${cmd}-${version}-flags"
    if [[ -f "$cache_file" ]]; then
        echo "$cache_file"
        return 0
    fi
    mkdir -p "$cache_dir" 2>/dev/null
    {
        "$cmd" --help 2>&1
        local sub
        for sub in "$@"; do
            "$cmd" "$sub" --help 2>&1
        done
    } | grep -oE -- '--[a-zA-Z][-a-zA-Z0-9]*' | sort -u > "$cache_file" 2>/dev/null
    echo "$cache_file"
    return 0
}
