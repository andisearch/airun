#!/bin/bash

# Codex CLI Tool
# OpenAI's coding agent CLI

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TOOL_DIR/tool-base.sh"

# Codex-specific state (set by tool_setup_env, used by execute functions)
_CODEX_MODEL=""
_CODEX_FLAGS=()

tool_name() {
    echo "Codex CLI"
}

tool_flag() {
    echo "codex"
}

tool_command() {
    echo "codex"
}

tool_is_installed() {
    _tool_command_exists "codex"
}

tool_needs_provider() {
    # Codex manages its own backend (OpenAI API, Ollama, LM Studio, config.toml profiles)
    return 1
}

tool_supported_providers() {
    # Providers that have Codex equivalents:
    # - ollama/lmstudio: local models via --oss
    # - azure: Azure OpenAI (requires ~/.codex/config.toml setup)
    # - apikey: default OpenAI API key (no-op, same as no provider)
    echo "ollama lmstudio azure apikey"
}

# Providers that should be validated through AI Runner's provider loader
# (others are handled entirely by the tool)
tool_validated_providers() {
    echo "ollama lmstudio"
}

tool_get_backend_info() {
    if [[ " ${_CODEX_FLAGS[*]} " == *" --oss "* ]]; then
        # Check which local provider
        local i=0
        while [[ $i -lt ${#_CODEX_FLAGS[@]} ]]; do
            if [[ "${_CODEX_FLAGS[$i]}" == "--local-provider" ]]; then
                local lp="${_CODEX_FLAGS[$((i+1))]}"
                case "$lp" in
                    lmstudio) echo "LM Studio (local)"; return 0 ;;
                    *)        echo "Ollama (local)"; return 0 ;;
                esac
            fi
            i=$((i + 1))
        done
        echo "Ollama (local)"
    elif [[ "$PROVIDER_FLAG" == "azure" ]]; then
        echo "Azure OpenAI"
    elif [[ -n "$TOOL_PROFILE" ]]; then
        echo "Profile: $TOOL_PROFILE"
    else
        echo "OpenAI API"
    fi
    return 0
}

tool_setup_env() {
    # Reads from script-scope variables: MODEL_TIER, CUSTOM_MODEL, PROVIDER_FLAG,
    # EFFORT_LEVEL, TOOL_PROFILE
    _CODEX_MODEL=""
    _CODEX_FLAGS=()

    # Profile mode: delegate everything to Codex's config.toml profile
    if [[ -n "$TOOL_PROFILE" ]]; then
        _CODEX_FLAGS+=("-p" "$TOOL_PROFILE")
        # Custom model still overrides profile default
        if [[ -n "$CUSTOM_MODEL" ]]; then
            _CODEX_MODEL="$CUSTOM_MODEL"
        elif [[ -n "$MODEL_TIER" ]]; then
            _map_codex_model_tier
        fi
        return 0
    fi

    # Local provider mode (Ollama / LM Studio)
    if [[ "$PROVIDER_FLAG" == "ollama" ]]; then
        _CODEX_FLAGS+=("--oss" "--local-provider" "ollama")
        # For local providers, only set model if explicitly requested
        if [[ -n "$CUSTOM_MODEL" ]]; then
            _CODEX_MODEL="$CUSTOM_MODEL"
        fi
        # Don't map tier to OpenAI model IDs for local providers
        return 0
    fi

    if [[ "$PROVIDER_FLAG" == "lmstudio" ]]; then
        _CODEX_FLAGS+=("--oss" "--local-provider" "lmstudio")
        if [[ -n "$CUSTOM_MODEL" ]]; then
            _CODEX_MODEL="$CUSTOM_MODEL"
        fi
        return 0
    fi

    # Azure OpenAI mode (requires ~/.codex/config.toml setup)
    if [[ "$PROVIDER_FLAG" == "azure" ]]; then
        _CODEX_FLAGS+=("-c" "model_provider=azure")
        if [[ -n "$CUSTOM_MODEL" ]]; then
            _CODEX_MODEL="$CUSTOM_MODEL"
        elif [[ -n "$MODEL_TIER" ]]; then
            _map_codex_model_tier
        fi
        # Skip API key check — Azure uses its own key via config.toml
        return 0
    fi

    # --apikey with Codex = force API key auth (for CI/CD or explicit key usage)
    if [[ "$PROVIDER_FLAG" == "apikey" ]]; then
        local api_key="${CODEX_API_KEY:-$OPENAI_API_KEY}"
        if [[ -z "$api_key" ]]; then
            print_error "Codex --apikey requires OPENAI_API_KEY or CODEX_API_KEY in environment or ~/.ai-runner/secrets.sh"
            return 1
        fi
        [[ -n "$CODEX_API_KEY" ]] && export CODEX_API_KEY || export OPENAI_API_KEY
    fi
    # Without --apikey: Codex uses its own auth (browser login, stored key, or env var)

    # Map model tier to Codex model IDs
    if [[ -n "$CUSTOM_MODEL" ]]; then
        _CODEX_MODEL="$CUSTOM_MODEL"
    elif [[ -n "$MODEL_TIER" ]]; then
        _map_codex_model_tier
    fi

    return 0
}

# Map MODEL_TIER to Codex model IDs (overridable via secrets.sh)
_map_codex_model_tier() {
    case "$MODEL_TIER" in
        high) _CODEX_MODEL="${CODEX_MODEL_HIGH:-gpt-5.4}" ;;
        mid)  _CODEX_MODEL="${CODEX_MODEL_MID:-gpt-5.3-codex}" ;;
        low)  _CODEX_MODEL="${CODEX_MODEL_LOW:-gpt-5.4-mini}" ;;
    esac
    return 0
}

tool_execute_interactive() {
    _CODEX_RESUME=false
    local args=()
    [[ -n "$_CODEX_MODEL" ]] && args+=("-m" "$_CODEX_MODEL")
    args+=("${_CODEX_FLAGS[@]}")
    _apply_effort_flag args

    # Pass through any remaining CLAUDE_ARGS that Codex can handle
    local mapped=()
    _remap_passthrough_args "$@"
    args+=("${mapped[@]}")

    # --resume maps to Codex's 'resume --last' subcommand
    if [[ "$_CODEX_RESUME" == true ]]; then
        exec codex resume --last "${args[@]}"
    fi
    exec codex "${args[@]}"
}

tool_execute_prompt() {
    local prompt="$1"
    shift
    local passthrough=("$@")

    # Build codex exec args
    local codex_args=("exec")
    [[ -n "$_CODEX_MODEL" ]] && codex_args+=("-m" "$_CODEX_MODEL")
    codex_args+=("${_CODEX_FLAGS[@]}")
    _apply_effort_flag codex_args

    # Script execution framing — Codex defaults to "build this" interpretation;
    # AI Runner scripts need "do this" interpretation
    codex_args+=("-c" 'developer_instructions=CRITICAL: The user prompt below is a RUNNABLE SCRIPT. You must execute it step by step — do NOT implement it as code, do NOT treat it as a feature request, and do NOT modify the script file itself. Read the instructions, run the bash blocks, use your tools as directed, and produce the requested output. You are the runtime, not the developer.')

    # Map passthrough args
    local mapped=()
    _remap_passthrough_args "${passthrough[@]}"
    codex_args+=("${mapped[@]}")

    if [[ "$AI_LIVE_OUTPUT" == true ]]; then
        # Remove --output-format stream-json --verbose from passthrough (already handled)
        # Add --json for Codex streaming
        codex_args+=("--json")

        # Signal file for heartbeat coordination (bash 3.2 compatible)
        local _hb_signal
        _hb_signal=$(mktemp) || _hb_signal="/tmp/.ai-hb-$$"

        if [[ ! -t 1 && -t 2 ]]; then
            # stdout redirected — narration to stderr, content to stdout
            _start_heartbeat "$_hb_signal" &
            local _hb_pid=$!
            disown "$_hb_pid" 2>/dev/null

            local _output=$(echo "$prompt" | codex "${codex_args[@]}" - | \
                jq --unbuffered -c 'select(.type == "item.completed" and .item.type == "agent_message")' 2>/dev/null | {
                _prev=""
                while IFS= read -r _event; do
                    date +%s > "$_hb_signal"
                    printf "\r\033[K" >&2
                    if [[ -n "$_prev" ]]; then
                        printf '%s\n' "$_prev" | jq -r '.item.text // empty' >&2 2>/dev/null
                    fi
                    _prev="$_event"
                done
                printf "\r\033[K" >&2
                if [[ -n "$_prev" ]]; then
                    _text=$(printf '%s\n' "$_prev" | jq -r '.item.text // empty' 2>/dev/null)
                    _split_pat='^(---|#)'
                    if printf '%s\n' "$_text" | grep -qEm1 "$_split_pat"; then
                        printf '%s\n' "$_text" | sed -E '/^(---|#)/,$d' >&2
                        printf '%s\n' "$_text" | sed -En '/^(---|#)/,$p'
                    else
                        printf '%s\n' "$_text"
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

            echo "$prompt" | codex "${codex_args[@]}" - | \
                jq --unbuffered -r 'select(.type == "item.completed" and .item.type == "agent_message") | .item.text // empty' 2>/dev/null | {
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
        # Simple prompt mode — pipe to codex exec
        echo "$prompt" | codex "${codex_args[@]}" -
    fi
}

# Map AI Runner effort levels to Codex reasoning effort
# Usage: _apply_effort_flag array_name
_apply_effort_flag() {
    local arr_name="$1"
    if [[ -n "$EFFORT_LEVEL" ]]; then
        local codex_effort="$EFFORT_LEVEL"
        # Map AI Runner's "max" to Codex's "xhigh"
        [[ "$codex_effort" == "max" ]] && codex_effort="xhigh"
        eval "${arr_name}+=(\"-c\" \"model_reasoning_effort=\$codex_effort\")"
    fi
    return 0
}

# Remap Claude Code passthrough args to Codex equivalents
# Sets: mapped[] array
_remap_passthrough_args() {
    mapped=()

    # Cache Codex's known flags for the flag firewall
    local _codex_flags_file=""
    _codex_flags_file=$(_cache_tool_flags "codex" "exec") 2>/dev/null || true

    local i=0
    local args=("$@")
    while [[ $i -lt ${#args[@]} ]]; do
        case "${args[$i]}" in
            # Known mappings (handled explicitly)
            --dangerously-skip-permissions)
                mapped+=("--dangerously-bypass-approvals-and-sandbox")
                ;;
            --permission-mode)
                i=$((i + 1))
                case "${args[$i]}" in
                    bypassPermissions|auto) mapped+=("--full-auto") ;;
                esac
                ;;
            --output-format)
                # Skip --output-format and its value (handled by --live or not needed)
                i=$((i + 1))
                ;;
            --verbose)
                ;; # No Codex equivalent — skip silently
            --effort)
                # Already handled via _apply_effort_flag — skip flag and value
                i=$((i + 1))
                ;;
            --resume)
                _CODEX_RESUME=true
                ;;
            *)
                # Flag firewall: check if flag is recognized by Codex
                if [[ "${args[$i]}" == --* ]] && [[ -f "$_codex_flags_file" ]] && \
                   ! grep -qxF -- "${args[$i]}" "$_codex_flags_file"; then
                    print_warning "${args[$i]} is not supported by Codex CLI, ignoring"
                    # Skip value too if next arg doesn't start with --
                    if [[ $((i + 1)) -lt ${#args[@]} ]] && [[ "${args[$((i + 1))]}" != --* ]]; then
                        i=$((i + 1))
                    fi
                else
                    mapped+=("${args[$i]}")
                fi
                ;;
        esac
        i=$((i + 1))
    done
    return 0
}

# Heartbeat functions (same pattern as claude-code.sh)
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
            if [[ "$showing" == true ]]; then
                printf "\r\033[K" >&2
                showing=false
            fi
            elapsed=0
            continue
        fi
        ((elapsed++))
        showing=true
        printf "\r\033[1;34m[AI Runner]\033[0m Working... %ds" "$elapsed" >&2
    done
}

_stop_heartbeat() {
    local pid="$1"
    kill "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    printf "\r\033[K" >&2
}

tool_get_install_instructions() {
    cat << 'EOF'
Codex CLI is not installed

Install with:
  npm install -g @openai/codex

Or on macOS:
  brew install --cask codex

See: https://developers.openai.com/codex/cli
EOF
}
