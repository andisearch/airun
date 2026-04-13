#!/bin/bash

# Local Provider Manager
# Supports onboarding and validation for a user-defined local provider config.

_LOCAL_PROVIDER_VALIDATION_STATUS=""
_LOCAL_PROVIDER_VALIDATION_HTTP_STATUS=""
_LOCAL_PROVIDER_DISCOVERED_MODELS=()

local_provider_config_file() {
    if [ -n "$LOCAL_PROVIDER_FILE" ]; then
        echo "$LOCAL_PROVIDER_FILE"
    else
        echo "${CONFIG_DIR}/local-provider.sh"
    fi
}

local_provider_load_config() {
    local file
    file=$(local_provider_config_file)
    [ -f "$file" ] || return 1
    source "$file"
    return 0
}

local_provider_is_configured() {
    local_provider_load_config >/dev/null 2>&1 || return 1
    [ -n "$LOCAL_PROVIDER_BASE_URL" ]
}

local_provider_name() {
    local_provider_load_config >/dev/null 2>&1 || true
    echo "${LOCAL_PROVIDER_NAME:-Local Provider}"
}

local_provider_token() {
    local_provider_load_config >/dev/null 2>&1 || true
    echo "${LOCAL_PROVIDER_AUTH_TOKEN:-}"
}

local_provider_models_endpoint() {
    local_provider_load_config >/dev/null 2>&1 || true
    echo "${LOCAL_PROVIDER_MODELS_ENDPOINT:-/v1/models}"
}

local_provider_messages_endpoint() {
    local_provider_load_config >/dev/null 2>&1 || true
    echo "${LOCAL_PROVIDER_MESSAGES_ENDPOINT:-/v1/messages}"
}

local_provider_base_url() {
    local_provider_load_config >/dev/null 2>&1 || true
    echo "${LOCAL_PROVIDER_BASE_URL:-}"
}

local_provider_resolve_url() {
    local base_url="$1"
    local endpoint="$2"

    if [[ "$endpoint" =~ ^https?:// ]]; then
        echo "$endpoint"
    else
        echo "${base_url%/}/${endpoint#/}"
    fi
}

local_provider_runtime_base_url() {
    local_provider_load_config >/dev/null 2>&1 || return 1
    local messages_url
    messages_url=$(local_provider_resolve_url "$LOCAL_PROVIDER_BASE_URL" "${LOCAL_PROVIDER_MESSAGES_ENDPOINT:-/v1/messages}")

    case "$messages_url" in
        */v1/messages)
            echo "${messages_url%/v1/messages}"
            ;;
        *)
            echo "$LOCAL_PROVIDER_BASE_URL"
            ;;
    esac
}

_local_provider_extract_model_ids() {
    grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4
}

_local_provider_collect_models() {
    local models_text="$1"
    _LOCAL_PROVIDER_DISCOVERED_MODELS=()
    while IFS= read -r _model; do
        [ -n "$_model" ] && _LOCAL_PROVIDER_DISCOVERED_MODELS+=("$_model")
    done <<< "$models_text"
}

local_provider_list_models_from() {
    local base_url="$1"
    local models_endpoint="$2"
    local auth_token="$3"
    local models_url

    models_url=$(local_provider_resolve_url "$base_url" "$models_endpoint")

    if [ -n "$auth_token" ]; then
        curl -sS \
            -H "Authorization: Bearer ${auth_token}" \
            -H "x-api-key: ${auth_token}" \
            "$models_url" 2>/dev/null | _local_provider_extract_model_ids
    else
        curl -sS "$models_url" 2>/dev/null | _local_provider_extract_model_ids
    fi
}

local_provider_list_models() {
    local_provider_load_config >/dev/null 2>&1 || return 1
    local_provider_list_models_from \
        "$LOCAL_PROVIDER_BASE_URL" \
        "${LOCAL_PROVIDER_MODELS_ENDPOINT:-/v1/models}" \
        "${LOCAL_PROVIDER_AUTH_TOKEN:-}"
}

local_provider_probe_messages_from() {
    local base_url="$1"
    local messages_endpoint="$2"
    local auth_token="$3"
    local probe_body probe_headers probe_status probe_content_type messages_url

    _LOCAL_PROVIDER_VALIDATION_STATUS=""
    _LOCAL_PROVIDER_VALIDATION_HTTP_STATUS=""

    messages_url=$(local_provider_resolve_url "$base_url" "$messages_endpoint")
    probe_body=$(mktemp) || probe_body="/tmp/.local-provider-probe-body-$$"
    probe_headers=$(mktemp) || probe_headers="/tmp/.local-provider-probe-headers-$$"

    if [ -n "$auth_token" ]; then
        probe_status=$(curl -sS --connect-timeout 2 \
            -X POST \
            -H "content-type: application/json" \
            -H "anthropic-version: 2023-06-01" \
            -H "x-api-key: ${auth_token}" \
            -H "Authorization: Bearer ${auth_token}" \
            -o "$probe_body" \
            -D "$probe_headers" \
            -w '%{http_code}' \
            -d '{"model":"__airun_local_probe_invalid_model__","max_tokens":1,"messages":[{"role":"user","content":[{"type":"text","text":"ping"}]}]}' \
            "$messages_url") || {
            rm -f "$probe_body" "$probe_headers"
            _LOCAL_PROVIDER_VALIDATION_STATUS="no_messages_api"
            return 1
        }
    else
        probe_status=$(curl -sS --connect-timeout 2 \
            -X POST \
            -H "content-type: application/json" \
            -H "anthropic-version: 2023-06-01" \
            -o "$probe_body" \
            -D "$probe_headers" \
            -w '%{http_code}' \
            -d '{"model":"__airun_local_probe_invalid_model__","max_tokens":1,"messages":[{"role":"user","content":[{"type":"text","text":"ping"}]}]}' \
            "$messages_url") || {
            rm -f "$probe_body" "$probe_headers"
            _LOCAL_PROVIDER_VALIDATION_STATUS="no_messages_api"
            return 1
        }
    fi

    probe_content_type=$(grep -i '^content-type:' "$probe_headers" | tail -1 | cut -d' ' -f2- | tr -d '\r')
    rm -f "$probe_body" "$probe_headers"

    if [[ "$probe_status" == "401" || "$probe_status" == "403" ]]; then
        _LOCAL_PROVIDER_VALIDATION_STATUS="auth_error"
        _LOCAL_PROVIDER_VALIDATION_HTTP_STATUS="$probe_status"
        return 1
    fi

    if [[ "$probe_status" == "404" || "$probe_status" == "405" ]]; then
        _LOCAL_PROVIDER_VALIDATION_STATUS="no_messages_api"
        _LOCAL_PROVIDER_VALIDATION_HTTP_STATUS="$probe_status"
        return 1
    fi

    if ! echo "$probe_content_type" | grep -qi 'application/json'; then
        _LOCAL_PROVIDER_VALIDATION_STATUS="no_messages_api"
        _LOCAL_PROVIDER_VALIDATION_HTTP_STATUS="$probe_status"
        return 1
    fi

    if [[ "$probe_status" == "400" || "$probe_status" == "422" ]]; then
        _LOCAL_PROVIDER_VALIDATION_STATUS="ready"
        return 0
    fi

    _LOCAL_PROVIDER_VALIDATION_STATUS="messages_probe_error"
    _LOCAL_PROVIDER_VALIDATION_HTTP_STATUS="$probe_status"
    return 1
}

local_provider_refresh_status() {
    local_provider_load_config >/dev/null 2>&1 || {
        _LOCAL_PROVIDER_VALIDATION_STATUS="unconfigured"
        return 1
    }

    local models_file headers_file status_code content_type models_text models_url
    local base_url="$LOCAL_PROVIDER_BASE_URL"
    local models_endpoint="${LOCAL_PROVIDER_MODELS_ENDPOINT:-/v1/models}"
    local auth_token="${LOCAL_PROVIDER_AUTH_TOKEN:-}"

    _LOCAL_PROVIDER_VALIDATION_STATUS=""
    _LOCAL_PROVIDER_VALIDATION_HTTP_STATUS=""
    _LOCAL_PROVIDER_DISCOVERED_MODELS=()

    models_url=$(local_provider_resolve_url "$base_url" "$models_endpoint")
    models_file=$(mktemp) || models_file="/tmp/.local-provider-models-$$"
    headers_file=$(mktemp) || headers_file="/tmp/.local-provider-models-headers-$$"

    if [ -n "$auth_token" ]; then
        status_code=$(curl -sS --connect-timeout 2 \
            -H "Authorization: Bearer ${auth_token}" \
            -H "x-api-key: ${auth_token}" \
            -o "$models_file" \
            -D "$headers_file" \
            -w '%{http_code}' \
            "$models_url") || {
            rm -f "$models_file" "$headers_file"
            _LOCAL_PROVIDER_VALIDATION_STATUS="unreachable"
            return 1
        }
    else
        status_code=$(curl -sS --connect-timeout 2 \
            -o "$models_file" \
            -D "$headers_file" \
            -w '%{http_code}' \
            "$models_url") || {
            rm -f "$models_file" "$headers_file"
            _LOCAL_PROVIDER_VALIDATION_STATUS="unreachable"
            return 1
        }
    fi

    content_type=$(grep -i '^content-type:' "$headers_file" | tail -1 | cut -d' ' -f2- | tr -d '\r')
    rm -f "$headers_file"

    if [[ "$status_code" == "401" || "$status_code" == "403" ]]; then
        _LOCAL_PROVIDER_VALIDATION_STATUS="auth_error"
        _LOCAL_PROVIDER_VALIDATION_HTTP_STATUS="$status_code"
        rm -f "$models_file"
        return 1
    fi

    if ! echo "$content_type" | grep -qi 'application/json'; then
        _LOCAL_PROVIDER_VALIDATION_STATUS="invalid_models"
        _LOCAL_PROVIDER_VALIDATION_HTTP_STATUS="$status_code"
        rm -f "$models_file"
        return 1
    fi

    models_text=$(_local_provider_extract_model_ids < "$models_file")
    rm -f "$models_file"
    _local_provider_collect_models "$models_text"

    if [ ${#_LOCAL_PROVIDER_DISCOVERED_MODELS[@]} -eq 0 ]; then
        _LOCAL_PROVIDER_VALIDATION_STATUS="no_models"
        _LOCAL_PROVIDER_VALIDATION_HTTP_STATUS="$status_code"
        return 1
    fi

    local_provider_probe_messages_from \
        "$LOCAL_PROVIDER_BASE_URL" \
        "${LOCAL_PROVIDER_MESSAGES_ENDPOINT:-/v1/messages}" \
        "${LOCAL_PROVIDER_AUTH_TOKEN:-}"
}

local_provider_print_validation_error() {
    local_provider_load_config >/dev/null 2>&1 || true
    local name="${LOCAL_PROVIDER_NAME:-Local Provider}"
    local base_url="${LOCAL_PROVIDER_BASE_URL:-http://localhost:3377}"
    local models_url
    local messages_url

    models_url=$(local_provider_resolve_url "$base_url" "${LOCAL_PROVIDER_MODELS_ENDPOINT:-/v1/models}")
    messages_url=$(local_provider_resolve_url "$base_url" "${LOCAL_PROVIDER_MESSAGES_ENDPOINT:-/v1/messages}")

    case "${_LOCAL_PROVIDER_VALIDATION_STATUS}" in
        unconfigured)
            cat << EOF
No local provider is configured

Run:
  ai local-onboard
EOF
            ;;
        unreachable)
            cat << EOF
${name} is not reachable

Expected local provider at:
  ${base_url}

Checked:
  ${models_url}
EOF
            ;;
        no_models)
            cat << EOF
${name} is reachable but returned no models

Checked:
  ${models_url}

Expose at least one model, then run:
  ai local-onboard
EOF
            ;;
        invalid_models)
            cat << EOF
${name} is reachable but the models endpoint did not return a usable JSON model list

Checked:
  ${models_url}
EOF
            ;;
        no_messages_api)
            cat << EOF
${name} is reachable, but it does not yet expose an Anthropic-compatible Messages API

Checked:
  ${messages_url}

Claude Code needs a working Messages API before `ai --local` can run.
EOF
            ;;
        auth_error)
            cat << EOF
${name} rejected the local provider probe with HTTP ${_LOCAL_PROVIDER_VALIDATION_HTTP_STATUS:-401}

Re-run:
  ai local-onboard
EOF
            ;;
        messages_probe_error)
            cat << EOF
${name} returned an unexpected response from the Messages API probe

Checked:
  ${messages_url}

HTTP status:
  ${_LOCAL_PROVIDER_VALIDATION_HTTP_STATUS:-unknown}
EOF
            ;;
        *)
            cat << EOF
Local provider validation failed

Provider:
  ${name}
EOF
            ;;
    esac
}

_local_provider_select_model() {
    local choice="${1:-1}"
    local idx=1
    local selected=""

    echo "" >&2
    echo "Discovered models:" >&2
    for model in "${_LOCAL_PROVIDER_DISCOVERED_MODELS[@]}"; do
        echo "  [$idx] $model" >&2
        idx=$((idx + 1))
    done
    echo "" >&2

    read -r -p "Choose default model [${choice}]: " selected
    selected="${selected:-$choice}"

    if [[ ! "$selected" =~ ^[0-9]+$ ]] || [ "$selected" -lt 1 ] || [ "$selected" -gt ${#_LOCAL_PROVIDER_DISCOVERED_MODELS[@]} ]; then
        selected="$choice"
    fi

    echo "${_LOCAL_PROVIDER_DISCOVERED_MODELS[$((selected - 1))]}"
}

run_local_provider_onboarding() {
    local name base_url token_input auth_token models_endpoint messages_endpoint
    local default_model config_file should_save choice auth_prompt_default

    if [[ ! -t 0 || ! -t 1 ]]; then
        print_error "Local provider onboarding requires an interactive terminal."
        return 1
    fi

    local_provider_load_config >/dev/null 2>&1 || true

    name="${LOCAL_PROVIDER_NAME:-Local Provider}"
    base_url="${LOCAL_PROVIDER_BASE_URL:-http://localhost:3377}"
    models_endpoint="${LOCAL_PROVIDER_MODELS_ENDPOINT:-/v1/models}"
    messages_endpoint="${LOCAL_PROVIDER_MESSAGES_ENDPOINT:-/v1/messages}"

    if [ -n "${LOCAL_PROVIDER_AUTH_TOKEN+x}" ]; then
        auth_token="$LOCAL_PROVIDER_AUTH_TOKEN"
    else
        auth_token="flow"
    fi

    if [ -n "$auth_token" ]; then
        auth_prompt_default="$auth_token"
    else
        auth_prompt_default="none"
    fi

    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  AI Runner - Local Provider Onboarding                      │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""

    read -r -p "Provider name [$name]: " choice
    [ -n "$choice" ] && name="$choice"

    read -r -p "Base URL [$base_url]: " choice
    [ -n "$choice" ] && base_url="$choice"

    read -r -p "Auth token [$auth_prompt_default, type 'none' for no token]: " token_input
    case "$token_input" in
        "") ;;
        none|NONE|None) auth_token="" ;;
        *) auth_token="$token_input" ;;
    esac

    while true; do
        _local_provider_collect_models "$(local_provider_list_models_from "$base_url" "$models_endpoint" "$auth_token")"
        if [ ${#_LOCAL_PROVIDER_DISCOVERED_MODELS[@]} -gt 0 ]; then
            break
        fi

        print_warning "No models discovered at $(local_provider_resolve_url "$base_url" "$models_endpoint")"
        read -r -p "Models endpoint [$models_endpoint] (or type 'cancel'): " choice
        case "$choice" in
            cancel|CANCEL|Cancel) return 1 ;;
            "") ;;
            *) models_endpoint="$choice" ;;
        esac
    done

    if ! local_provider_probe_messages_from "$base_url" "$messages_endpoint" "$auth_token"; then
        print_warning "Messages endpoint probe failed at $(local_provider_resolve_url "$base_url" "$messages_endpoint")"
        local_provider_print_validation_error >&2
        echo ""
        read -r -p "Alternate messages endpoint [$messages_endpoint] (press Enter to keep): " choice
        [ -n "$choice" ] && messages_endpoint="$choice"

        if ! local_provider_probe_messages_from "$base_url" "$messages_endpoint" "$auth_token"; then
            print_warning "Messages endpoint is still not ready."
            read -r -p "Save this provider anyway? [y/N]: " should_save
            [[ "$should_save" =~ ^[Yy] ]] || return 1
        fi
    fi

    default_model=$(_local_provider_select_model "1")
    config_file=$(local_provider_config_file)
    mkdir -p "$(dirname "$config_file")"

    {
        echo "#!/bin/bash"
        echo "# AI Runner local provider config"
        printf 'LOCAL_PROVIDER_NAME=%q\n' "$name"
        printf 'LOCAL_PROVIDER_BASE_URL=%q\n' "$base_url"
        printf 'LOCAL_PROVIDER_AUTH_TOKEN=%q\n' "$auth_token"
        printf 'LOCAL_PROVIDER_MODELS_ENDPOINT=%q\n' "$models_endpoint"
        printf 'LOCAL_PROVIDER_MESSAGES_ENDPOINT=%q\n' "$messages_endpoint"
        printf 'LOCAL_PROVIDER_DEFAULT_MODEL=%q\n' "$default_model"
        printf 'LOCAL_PROVIDER_SMALL_FAST_MODEL=%q\n' "$default_model"
    } > "$config_file"

    chmod 600 "$config_file" 2>/dev/null || true

    source "$config_file"

    echo ""
    print_success "Saved local provider config to $config_file"
    print_status "Provider: $LOCAL_PROVIDER_NAME"
    print_status "Base URL: $LOCAL_PROVIDER_BASE_URL"
    print_status "Default model: $LOCAL_PROVIDER_DEFAULT_MODEL"

    if [[ "$_LOCAL_PROVIDER_VALIDATION_STATUS" != "ready" ]]; then
        print_warning "Saved, but the Messages API is not ready yet. `ai --local` will fail until it is."
    fi

    return 0
}
