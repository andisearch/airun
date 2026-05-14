#!/bin/bash

# Claude Code Tool
# Anthropic's official CLI for Claude

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TOOL_DIR/tool-base.sh"

tool_name() {
    echo "Claude Code"
}

tool_flag() {
    echo "cc"
}

tool_command() {
    echo "claude"
}

tool_is_installed() {
    _tool_command_exists "claude"
}

tool_supported_providers() {
    # Claude Code supports all providers
    echo "aws vertex apikey azure vercel pro ollama lmstudio local dgx"
}

tool_setup_env() {
    # Claude Code doesn't require additional tool-specific setup
    # Provider setup handles environment variables
    return 0
}

tool_execute_interactive() {
    local args=("$@")
    exec claude "${args[@]}"
}

tool_execute_prompt() {
    local prompt="$1"
    shift
    local args=("$@")
    if [[ "$AI_LIVE_OUTPUT" == true ]]; then
        # Signal file for heartbeat coordination (bash 3.2 compatible)
        local _hb_signal
        _hb_signal=$(mktemp) || _hb_signal="/tmp/.ai-hb-$$"

        if [[ ! -t 1 && -t 2 ]]; then
            # stdout redirected (file or pipe) — narration to stderr, clean content to stdout
            # Strategy: intermediate turns → stderr in real-time
            #           last turn → split at first content marker (frontmatter --- or heading #):
            #             preamble → stderr, content → stdout (file)
            local _sys_prompt="Output is being captured. Begin your final response directly with the requested content. Do not include introductory text or preamble."

            _start_heartbeat "$_hb_signal" &
            local _hb_pid=$!
            disown "$_hb_pid" 2>/dev/null

            # local assignment masks non-zero exit (safe under set -e)
            local _output=$(echo "$prompt" | claude -p --append-system-prompt "$_sys_prompt" "${args[@]}" | \
                jq --unbuffered -c 'select(.type == "assistant")' 2>/dev/null | {
                _prev=""
                while IFS= read -r _event; do
                    date +%s > "$_hb_signal"
                    printf "\r\033[K" >&2
                    if [[ -n "$_prev" ]]; then
                        # Intermediate turn — full text to stderr
                        printf '%s\n' "$_prev" | jq -r '.message.content[] | select(.type == "text") | .text' >&2 2>/dev/null
                    fi
                    _prev="$_event"
                done
                # Last turn — split at first content marker (frontmatter --- or heading #)
                printf "\r\033[K" >&2
                if [[ -n "$_prev" ]]; then
                    _text=$(printf '%s\n' "$_prev" | jq -r '.message.content[] | select(.type == "text") | .text' 2>/dev/null)
                    _split_pat='^(---|#)'
                    if printf '%s\n' "$_text" | grep -qEm1 "$_split_pat"; then
                        printf '%s\n' "$_text" | sed -E '/^(---|#)/,$d' >&2   # preamble → stderr
                        printf '%s\n' "$_text" | sed -En '/^(---|#)/,$p'      # content → stdout
                    else
                        printf '%s\n' "$_text"                                  # no marker → stdout
                    fi
                fi
            })
            _stop_heartbeat "$_hb_pid"
            rm -f "$_hb_signal"

            if [[ -n "$_output" ]]; then
                printf '%s\n' "$_output"
                local _lines=$(printf '%s\n' "$_output" | wc -l | tr -d ' ')
                print_status "Done ($_lines lines written)"
            fi
        else
            # Terminal mode — stream directly
            _start_heartbeat "$_hb_signal" &
            local _hb_pid=$!
            disown "$_hb_pid" 2>/dev/null

            echo "$prompt" | claude -p "${args[@]}" | \
                jq --unbuffered -r 'select(.type == "assistant") | .message.content[] | select(.type == "text") | .text' 2>/dev/null | {
                while IFS= read -r _line; do
                    date +%s > "$_hb_signal"
                    printf "\r\033[K" >&2
                    printf '%s\n' "$_line"
                done
            }
            _stop_heartbeat "$_hb_pid"
            rm -f "$_hb_signal"
        fi
    else
        echo "$prompt" | claude -p "${args[@]}"
    fi
}

# Smart heartbeat — shows elapsed time on stderr, auto-hides during output.
# Uses a signal file: when the main loop writes a timestamp, the heartbeat
# hides for 3 seconds. Resumes automatically during silent gaps (tool calls,
# model thinking). Compatible with bash 3.2 (no read -t needed).
_start_heartbeat() {
    local signal_file="$1"
    local elapsed=0
    local showing=false
    while true; do
        sleep 1
        local last_activity
        last_activity=$(cat "$signal_file" 2>/dev/null)
        local now
        now=$(date +%s)
        if [[ -n "$last_activity" ]] && [[ $((now - last_activity)) -lt 3 ]]; then
            # Recent output — hide heartbeat, reset counter
            if [[ "$showing" == true ]]; then
                printf "\r\033[K" >&2
                showing=false
            fi
            elapsed=0
            continue
        fi
        # No recent output — show heartbeat
        ((elapsed++))
        showing=true
        printf "\r\033[1;34m[AI Runner]\033[0m Working... %ds" "$elapsed" >&2
    done
}

# Stop heartbeat and clear the line
_stop_heartbeat() {
    local pid="$1"
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    printf "\r\033[K" >&2
}

tool_get_install_instructions() {
    cat << 'EOF'
Claude Code is not installed

Install with:
  curl -fsSL https://claude.ai/install.sh | bash

Or see: https://code.claude.com/docs/en/setup
EOF
}

# Claude Code specific: check if user is logged in (for Pro mode)
tool_is_logged_in() {
    # Check for session file
    [ -f "$HOME/.claude/session.json" ] || [ -f "$HOME/.claude/.credentials" ]
}
