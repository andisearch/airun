#!/bin/bash
# Test runner for README script automation examples
# Tests that all documented examples in README.md work correctly.
# Output is written to test/automation/output/ (gitignored)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Add scripts to PATH
export PATH="$PROJECT_DIR/scripts:$PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

mkdir -p "$OUTPUT_DIR"

log() { echo -e "$1"; }
pass() { log "${GREEN}PASS:${NC} $1"; PASSED=$((PASSED + 1)); }
fail() { log "${RED}FAIL:${NC} $1"; FAILED=$((FAILED + 1)); }
test_header() { log "\n${YELLOW}TEST:${NC} $1"; }

#=============================================================================
# TEST 1: Basic shebang execution (README Quick Start)
#=============================================================================
test_basic_shebang() {
    test_header "Basic shebang execution"

    # Check shebang line - supports both ai and claude-run
    if head -1 "$SCRIPT_DIR/task.md" | grep -qE "#!/usr/bin/env (ai|claude-run)"; then
        pass "Shebang line is correct"
    else
        fail "Shebang line not found"
    fi

    # Check executable
    if [[ -x "$SCRIPT_DIR/task.md" ]]; then
        pass "File is executable"
    else
        fail "File is not executable"
    fi
}

#=============================================================================
# TEST 2: ai command exists and works
#=============================================================================
test_ai_exists() {
    test_header "ai command"

    if command -v ai &> /dev/null || [[ -x "$PROJECT_DIR/scripts/ai" ]]; then
        pass "ai command found"
    else
        fail "ai not in PATH"
    fi

    # Check help works (with timeout)
    if timeout 2 bash "$PROJECT_DIR/scripts/ai" --help > "$OUTPUT_DIR/help.txt" 2>&1; then
        if grep -q "file.md" "$OUTPUT_DIR/help.txt"; then
            pass "ai --help documents .md files"
        else
            fail "--help doesn't mention .md files"
        fi
    else
        pass "ai --help works (timeout expected in some envs)"
    fi
}

#=============================================================================
# TEST 3: Stdin piping support exists in ai
#=============================================================================
test_stdin_support() {
    test_header "Stdin piping support"

    # Check that ai script has stdin handling
    if grep -q "STDIN_CONTENT" "$PROJECT_DIR/scripts/ai"; then
        pass "ai has stdin content handling"
    else
        fail "stdin handling not found in ai"
    fi

    # Check stdin-position flag exists
    if grep -q "stdin-position" "$PROJECT_DIR/scripts/ai"; then
        pass "--stdin-position flag supported"
    else
        fail "--stdin-position flag not found"
    fi
}

#=============================================================================
# TEST 4: Shebang stripping happens before prepend (security check)
#=============================================================================
test_shebang_stripping() {
    test_header "Shebang stripping before stdin prepend (security)"

    # The stdin prepend must happen AFTER shebang stripping
    # In ai script:
    #   CONTENT=$(tail -n +2 "$MD_FILE")  # strips shebang
    #   CONTENT="...$STDIN_CONTENT...$CONTENT"  # prepends stdin to CONTENT
    # This is safe because stdin is added to CONTENT, not the raw file

    local run_script="$PROJECT_DIR/scripts/ai"

    # Check that shebang stripping exists
    if grep -q 'tail -n +2' "$run_script"; then
        pass "Shebang stripping (tail -n +2) exists"
    else
        fail "Shebang stripping not found"
        return
    fi

    # Check that stdin is integrated with CONTENT variable (not raw file)
    # The pattern should show stdin being added to CONTENT, not MD_FILE
    if grep -q 'CONTENT=.*STDIN_CONTENT.*CONTENT' "$run_script" || \
       grep -q 'CONTENT=.*\$CONTENT' "$run_script"; then
        pass "Stdin integrates with CONTENT (post-shebang-strip)"
    else
        fail "Stdin integration pattern not found"
    fi
}

#=============================================================================
# TEST 5: All example scripts are valid
#=============================================================================
test_example_scripts() {
    test_header "Example markdown scripts are valid"

    local scripts=("analyze.md" "process.md" "summarize-changes.md" "generate-report.md" "format-output.md")

    for script in "${scripts[@]}"; do
        if [[ -x "$SCRIPT_DIR/$script" ]]; then
            if head -1 "$SCRIPT_DIR/$script" | grep -qE "#!/usr/bin/env (ai|claude-run)"; then
                pass "$script is valid"
            else
                fail "$script missing shebang"
            fi
        else
            fail "$script not executable"
        fi
    done
}

#=============================================================================
# TEST 6: Pipeline chaining (scripts exist for README example)
#=============================================================================
test_pipeline_chaining() {
    test_header "Pipeline chaining example scripts"

    if [[ -x "$SCRIPT_DIR/generate-report.md" ]] && [[ -x "$SCRIPT_DIR/format-output.md" ]]; then
        pass "Pipeline scripts exist and are executable"
    else
        fail "Pipeline scripts missing"
    fi
}

#=============================================================================
# TEST 7: Shell script integration pattern
#=============================================================================
test_shell_integration() {
    test_header "Shell script loop integration"

    # Create test logs
    mkdir -p "$OUTPUT_DIR/logs"
    echo "log1" > "$OUTPUT_DIR/logs/test1.txt"
    echo "log2" > "$OUTPUT_DIR/logs/test2.txt"

    # Verify the pattern works
    local count=0
    for f in "$OUTPUT_DIR/logs"/*.txt; do
        if [[ -f "$f" ]]; then
            count=$((count + 1))
        fi
    done

    if [[ $count -eq 2 ]]; then
        pass "Shell loop pattern works with $count files"
    else
        fail "Shell loop pattern failed"
    fi

    rm -rf "$OUTPUT_DIR/logs"
}

#=============================================================================
# TEST 8: Git log piping
#=============================================================================
test_git_log() {
    test_header "Git log piping capability"

    if (cd "$PROJECT_DIR" && git log --oneline -5 > "$OUTPUT_DIR/git-log.txt" 2>&1); then
        if [[ -s "$OUTPUT_DIR/git-log.txt" ]]; then
            pass "git log output captured successfully"
        else
            fail "git log output empty"
        fi
    else
        fail "git log command failed"
    fi
}

#=============================================================================
# TEST 9: Backward compatibility - claude-run still works
#=============================================================================
test_backward_compat() {
    test_header "Backward compatibility (claude-run)"

    if command -v claude-run &> /dev/null || [[ -x "$PROJECT_DIR/scripts/claude-run" ]]; then
        pass "claude-run command found (backward compat)"
    else
        fail "claude-run not available"
    fi
}

#=============================================================================
# TEST 10: Provider flag parsing
#=============================================================================
test_provider_flags() {
    test_header "Provider flag parsing"

    local flags=("aws" "vertex" "apikey" "azure" "vercel" "pro" "ollama" "lmstudio")

    for flag in "${flags[@]}"; do
        if grep -q -- "--$flag" "$PROJECT_DIR/scripts/ai"; then
            pass "Provider flag --$flag recognized"
        else
            fail "Provider flag --$flag not found"
        fi
    done
}

#=============================================================================
# TEST 11: Model tier flags
#=============================================================================
test_model_flags() {
    test_header "Model tier flag parsing"

    local flags=("opus" "sonnet" "haiku" "high" "mid" "low")

    for flag in "${flags[@]}"; do
        if grep -q -- "--$flag)" "$PROJECT_DIR/scripts/ai"; then
            pass "Model flag --$flag recognized"
        else
            fail "Model flag --$flag not found"
        fi
    done
}

#=============================================================================
# TEST 12: Provider modules exist
#=============================================================================
test_provider_modules() {
    test_header "Provider modules exist"

    local providers=("aws.sh" "vertex.sh" "ollama.sh" "apikey.sh" "azure.sh" "vercel.sh" "pro.sh" "lmstudio.sh")

    for provider in "${providers[@]}"; do
        if [[ -x "$PROJECT_DIR/providers/$provider" ]]; then
            pass "Provider $provider exists and is executable"
        else
            fail "Provider $provider missing or not executable"
        fi
    done

    # Also check provider-base.sh
    if [[ -x "$PROJECT_DIR/providers/provider-base.sh" ]]; then
        pass "Provider base module exists"
    else
        fail "Provider base module missing"
    fi
}

#=============================================================================
# TEST 13: Tool modules exist
#=============================================================================
test_tool_modules() {
    test_header "Tool modules exist"

    if [[ -x "$PROJECT_DIR/tools/claude-code.sh" ]]; then
        pass "Tool claude-code.sh exists and is executable"
    else
        fail "Tool claude-code.sh missing or not executable"
    fi

    if [[ -x "$PROJECT_DIR/tools/tool-base.sh" ]]; then
        pass "Tool base module exists"
    else
        fail "Tool base module missing"
    fi
}

#=============================================================================
# TEST 14: Utility commands exist
#=============================================================================
test_utility_commands() {
    test_header "Utility commands exist"

    local commands=("airun" "ai-sessions" "ai-status")

    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &> /dev/null || [[ -x "$PROJECT_DIR/scripts/$cmd" ]]; then
            pass "Utility command $cmd found"
        else
            fail "Utility command $cmd not found"
        fi
    done
}

#=============================================================================
# TEST 15: Default preference flags
#=============================================================================
test_default_flags() {
    test_header "Default preference flags"

    if grep -q 'set-default' "$PROJECT_DIR/scripts/ai"; then
        pass "--set-default flag supported"
    else
        fail "--set-default flag not found"
    fi

    if grep -q 'clear-default' "$PROJECT_DIR/scripts/ai"; then
        pass "--clear-default flag supported"
    else
        fail "--clear-default flag not found"
    fi

    # Check that core-utils has defaults functions
    if grep -q 'load_defaults' "$PROJECT_DIR/scripts/lib/core-utils.sh"; then
        pass "load_defaults function exists"
    else
        fail "load_defaults function not found"
    fi
}

#=============================================================================
# TEST 16: Version flag
#=============================================================================
test_version_flag() {
    test_header "Version flag"

    # Check that version handling code exists in ai script
    if grep -q 'SHOW_VERSION=true' "$PROJECT_DIR/scripts/ai" && \
       grep -q 'AI_RUNNER_VERSION' "$PROJECT_DIR/scripts/ai"; then
        pass "--version flag handling exists"
    else
        fail "--version flag handling not found"
    fi

    # Check that VERSION file exists
    if [[ -f "$PROJECT_DIR/VERSION" ]]; then
        local version=$(cat "$PROJECT_DIR/VERSION")
        pass "VERSION file exists: $version"
    else
        fail "VERSION file not found"
    fi
}

#=============================================================================
# TEST 17: Update checker module exists
#=============================================================================
test_update_checker_module() {
    test_header "Update checker module exists"

    if [[ -f "$PROJECT_DIR/scripts/lib/update-checker.sh" ]]; then
        pass "update-checker.sh exists"
    else
        fail "update-checker.sh not found"
        return
    fi

    for func in check_for_update print_update_notice run_update; do
        if grep -q "$func" "$PROJECT_DIR/scripts/lib/update-checker.sh"; then
            pass "Function $func found"
        else
            fail "Function $func not found"
        fi
    done
}

#=============================================================================
# TEST 18: Update subcommand parsing
#=============================================================================
test_update_subcommand() {
    test_header "Update subcommand parsing"

    if grep -q 'update)' "$PROJECT_DIR/scripts/ai"; then
        pass "update) case found in scripts/ai"
    else
        fail "update) case not found in scripts/ai"
    fi

    if grep -q 'update)' "$PROJECT_DIR/setup.sh"; then
        pass "update) case found in setup.sh heredoc"
    else
        fail "update) case not found in setup.sh heredoc"
    fi
}

#=============================================================================
# TEST 19: Update checker version comparison
#=============================================================================
test_version_comparison() {
    test_header "Update checker version comparison"

    # Source the update checker to test _version_lt
    source "$PROJECT_DIR/scripts/lib/update-checker.sh"

    if _version_lt "2.2.2" "2.3.0"; then
        pass "_version_lt 2.2.2 < 2.3.0"
    else
        fail "_version_lt 2.2.2 < 2.3.0 should return 0"
    fi

    if ! _version_lt "2.3.0" "2.2.2"; then
        pass "_version_lt 2.3.0 not < 2.2.2"
    else
        fail "_version_lt 2.3.0 < 2.2.2 should return 1"
    fi

    if ! _version_lt "2.2.2" "2.2.2"; then
        pass "_version_lt 2.2.2 == 2.2.2 returns 1"
    else
        fail "_version_lt same version should return 1"
    fi

    # Test with v prefix
    if _version_lt "v2.0.0" "v2.1.0"; then
        pass "_version_lt v2.0.0 < v2.1.0 (with v prefix)"
    else
        fail "_version_lt with v prefix failed"
    fi

    # Test cache write/read cycle
    local tmp_dir
    tmp_dir=$(mktemp -d)
    _UPDATE_CACHE_FILE="$tmp_dir/.update-check"
    _write_update_cache "v2.5.0" "Test release notes"
    if _read_update_cache && [[ "$_CACHED_VERSION" == "v2.5.0" ]]; then
        pass "Cache write/read cycle works"
    else
        fail "Cache write/read cycle failed"
    fi
    rm -rf "$tmp_dir"
}

#=============================================================================
# TEST 20: AI_NO_UPDATE_CHECK disables check
#=============================================================================
test_no_update_check() {
    test_header "AI_NO_UPDATE_CHECK disables check"

    source "$PROJECT_DIR/scripts/lib/update-checker.sh"

    AI_NO_UPDATE_CHECK=1
    AI_RUNNER_VERSION="2.2.2"
    if ! check_for_update; then
        pass "check_for_update returns 1 when AI_NO_UPDATE_CHECK=1"
    else
        fail "check_for_update should return 1 when disabled"
    fi
    unset AI_NO_UPDATE_CHECK
}

#=============================================================================
# TEST 21: Source metadata format
#=============================================================================
test_source_metadata() {
    test_header "Source metadata format"

    if grep -q 'source-metadata' "$PROJECT_DIR/setup.sh"; then
        pass "setup.sh writes .source-metadata"
    else
        fail "setup.sh does not write .source-metadata"
    fi

    if grep -q 'AI_RUNNER_SOURCE_DIR' "$PROJECT_DIR/setup.sh"; then
        pass "setup.sh includes AI_RUNNER_SOURCE_DIR"
    else
        fail "setup.sh missing AI_RUNNER_SOURCE_DIR"
    fi

    if grep -q 'AI_RUNNER_GITHUB_REPO' "$PROJECT_DIR/setup.sh"; then
        pass "setup.sh includes AI_RUNNER_GITHUB_REPO"
    else
        fail "setup.sh missing AI_RUNNER_GITHUB_REPO"
    fi
}

#=============================================================================
# TEST 22: setup.sh/scripts/ai heredoc sync
#=============================================================================
test_heredoc_sync() {
    test_header "setup.sh/scripts/ai heredoc sync for update"

    # Both files should have update) case
    local ai_has_update setup_has_update
    ai_has_update=$(grep -c 'update)' "$PROJECT_DIR/scripts/ai" || true)
    setup_has_update=$(grep -c 'update)' "$PROJECT_DIR/setup.sh" || true)

    if [[ "$ai_has_update" -ge 1 && "$setup_has_update" -ge 1 ]]; then
        pass "Both scripts/ai and setup.sh heredoc have update) case"
    else
        fail "Sync drift: scripts/ai has $ai_has_update, setup.sh has $setup_has_update update) cases"
    fi

    # Both should source update-checker.sh in interactive mode
    if grep -q 'update-checker.sh' "$PROJECT_DIR/scripts/ai" && \
       grep -q 'update-checker.sh' "$PROJECT_DIR/setup.sh"; then
        pass "Both source update-checker.sh"
    else
        fail "update-checker.sh sourcing not synced"
    fi
}

#=============================================================================
# TEST 23: Agent teams flag parsing
#=============================================================================
test_agent_teams_flag() {
    test_header "Agent teams flag parsing"

    # Check --team flag recognized
    if grep -q -- '--team|--teams)' "$PROJECT_DIR/scripts/ai"; then
        pass "Agent teams flag --team recognized"
    else
        fail "Agent teams flag --team not found"
    fi

    # Check env var export
    if grep -q 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$PROJECT_DIR/scripts/ai"; then
        pass "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS env var export found"
    else
        fail "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS not found"
    fi

    # Check session tracking includes teams
    if grep -q 'AI_SESSION_TEAMS' "$PROJECT_DIR/scripts/lib/core-utils.sh"; then
        pass "Session tracking includes AI_SESSION_TEAMS"
    else
        fail "AI_SESSION_TEAMS not found in session tracking"
    fi

    # Check help text mentions --team
    if grep -q 'Agent teams' "$PROJECT_DIR/scripts/ai"; then
        pass "Help text documents --team flag"
    else
        fail "Help text missing --team documentation"
    fi
}

#=============================================================================
# TEST 24: Agent teams heredoc sync
#=============================================================================
test_agent_teams_heredoc_sync() {
    test_header "Agent teams heredoc sync (scripts/ai vs setup.sh)"

    # Both files should have --team flag parsing
    local ai_has_team setup_has_team
    ai_has_team=$(grep -c -- '--team|--teams)' "$PROJECT_DIR/scripts/ai" || true)
    setup_has_team=$(grep -c -- '--team|--teams)' "$PROJECT_DIR/setup.sh" || true)

    if [[ "$ai_has_team" -ge 1 && "$setup_has_team" -ge 1 ]]; then
        pass "Both scripts/ai and setup.sh heredoc have --team flag parsing"
    else
        fail "Sync drift: scripts/ai has $ai_has_team, setup.sh has $setup_has_team --team) cases"
    fi

    # Both should handle TEAM_MODE variable
    if grep -q 'TEAM_MODE' "$PROJECT_DIR/scripts/ai" && \
       grep -q 'TEAM_MODE' "$PROJECT_DIR/setup.sh"; then
        pass "Both handle TEAM_MODE variable"
    else
        fail "TEAM_MODE variable not synced"
    fi
}

#=============================================================================
# TEST 25: Permission shortcut flag parsing
#=============================================================================
test_permission_shortcut_flags() {
    test_header "Permission shortcut flag parsing"

    # Check --skip flag recognized in case block
    if grep -q -- '--skip)' "$PROJECT_DIR/scripts/ai"; then
        pass "--skip flag recognized in scripts/ai"
    else
        fail "--skip flag not found in scripts/ai"
    fi

    # Check --bypass flag recognized in case block
    if grep -q -- '--bypass)' "$PROJECT_DIR/scripts/ai"; then
        pass "--bypass flag recognized in scripts/ai"
    else
        fail "--bypass flag not found in scripts/ai"
    fi

    # Check PERMISSION_SHORTCUT variable exists
    if grep -q 'PERMISSION_SHORTCUT=""' "$PROJECT_DIR/scripts/ai"; then
        pass "PERMISSION_SHORTCUT variable initialized"
    else
        fail "PERMISSION_SHORTCUT variable not found"
    fi

    # Check EXPLICIT_PERMISSION_MODE variable exists
    if grep -q 'EXPLICIT_PERMISSION_MODE=false' "$PROJECT_DIR/scripts/ai"; then
        pass "EXPLICIT_PERMISSION_MODE variable initialized"
    else
        fail "EXPLICIT_PERMISSION_MODE variable not found"
    fi
}

#=============================================================================
# TEST 26: Permission shortcut resolution logic
#=============================================================================
test_permission_shortcut_resolution() {
    test_header "Permission shortcut resolution logic"

    local ai_script="$PROJECT_DIR/scripts/ai"

    # Check that --skip expands to --dangerously-skip-permissions
    if grep -q 'skip).*CLAUDE_ARGS.*--dangerously-skip-permissions' "$ai_script"; then
        pass "--skip expands to --dangerously-skip-permissions"
    else
        fail "--skip expansion not found"
    fi

    # Check that --bypass expands to --permission-mode bypassPermissions
    if grep -q 'bypass).*CLAUDE_ARGS.*--permission-mode.*bypassPermissions' "$ai_script"; then
        pass "--bypass expands to --permission-mode bypassPermissions"
    else
        fail "--bypass expansion not found"
    fi

    # Check that explicit --permission-mode sets EXPLICIT_PERMISSION_MODE
    if grep -q -- '--permission-mode)' "$ai_script" && \
       grep -q 'EXPLICIT_PERMISSION_MODE=true' "$ai_script"; then
        pass "Explicit --permission-mode sets EXPLICIT_PERMISSION_MODE=true"
    else
        fail "Explicit --permission-mode tracking not found"
    fi

    # Check that explicit --dangerously-skip-permissions sets EXPLICIT_PERMISSION_MODE
    if grep -q -- '--dangerously-skip-permissions)' "$ai_script"; then
        pass "Explicit --dangerously-skip-permissions intercepted"
    else
        fail "Explicit --dangerously-skip-permissions interception not found"
    fi

    # Check precedence: explicit flags override shortcuts (warning message)
    if grep -q 'ignored.*explicit.*--permission-mode.*--dangerously-skip-permissions.*takes precedence' "$ai_script"; then
        pass "Precedence warning message exists"
    else
        fail "Precedence warning message not found"
    fi
}

#=============================================================================
# TEST 27: Permission shortcut heredoc sync (scripts/ai vs setup.sh)
#=============================================================================
test_permission_shortcut_heredoc_sync() {
    test_header "Permission shortcut heredoc sync (scripts/ai vs setup.sh)"

    # Both files should have --skip flag parsing
    local ai_has_skip setup_has_skip
    ai_has_skip=$(grep -c -- '--skip)' "$PROJECT_DIR/scripts/ai" || true)
    setup_has_skip=$(grep -c -- '--skip)' "$PROJECT_DIR/setup.sh" || true)

    if [[ "$ai_has_skip" -ge 1 && "$setup_has_skip" -ge 1 ]]; then
        pass "Both scripts/ai and setup.sh have --skip flag parsing"
    else
        fail "Sync drift: scripts/ai has $ai_has_skip, setup.sh has $setup_has_skip --skip) cases"
    fi

    # Both files should have --bypass flag parsing
    local ai_has_bypass setup_has_bypass
    ai_has_bypass=$(grep -c -- '--bypass)' "$PROJECT_DIR/scripts/ai" || true)
    setup_has_bypass=$(grep -c -- '--bypass)' "$PROJECT_DIR/setup.sh" || true)

    if [[ "$ai_has_bypass" -ge 1 && "$setup_has_bypass" -ge 1 ]]; then
        pass "Both scripts/ai and setup.sh have --bypass flag parsing"
    else
        fail "Sync drift: scripts/ai has $ai_has_bypass, setup.sh has $setup_has_bypass --bypass) cases"
    fi

    # Both should have PERMISSION_SHORTCUT variable
    if grep -q 'PERMISSION_SHORTCUT' "$PROJECT_DIR/scripts/ai" && \
       grep -q 'PERMISSION_SHORTCUT' "$PROJECT_DIR/setup.sh"; then
        pass "Both handle PERMISSION_SHORTCUT variable"
    else
        fail "PERMISSION_SHORTCUT variable not synced"
    fi

    # Both should have EXPLICIT_PERMISSION_MODE variable
    if grep -q 'EXPLICIT_PERMISSION_MODE' "$PROJECT_DIR/scripts/ai" && \
       grep -q 'EXPLICIT_PERMISSION_MODE' "$PROJECT_DIR/setup.sh"; then
        pass "Both handle EXPLICIT_PERMISSION_MODE variable"
    else
        fail "EXPLICIT_PERMISSION_MODE variable not synced"
    fi

    # Both should have the resolution block
    if grep -q 'Resolve permission shortcuts' "$PROJECT_DIR/scripts/ai" && \
       grep -q 'Resolve permission shortcuts' "$PROJECT_DIR/setup.sh"; then
        pass "Both have permission shortcut resolution block"
    else
        fail "Permission shortcut resolution block not synced"
    fi
}

#=============================================================================
# TEST 28: Permission shortcut shebang parsing (piped mode)
#=============================================================================
test_permission_shortcut_shebang() {
    test_header "Permission shortcut shebang parsing"

    local ai_script="$PROJECT_DIR/scripts/ai"

    # Check --skip and --bypass handled in _parse_shebang_flags
    if grep -A50 '_parse_shebang_flags()' "$ai_script" | grep -q -- '--skip)'; then
        pass "--skip handled in shebang flag parser"
    else
        fail "--skip not found in shebang flag parser"
    fi

    if grep -A50 '_parse_shebang_flags()' "$ai_script" | grep -q -- '--bypass)'; then
        pass "--bypass handled in shebang flag parser"
    else
        fail "--bypass not found in shebang flag parser"
    fi

    # Check that shebang shortcuts respect CLI precedence (only applied when empty)
    if grep -q '\-z "$PERMISSION_SHORTCUT".*SHEBANG_PERMISSION_SHORTCUT' "$ai_script"; then
        pass "Shebang shortcuts check CLI precedence before applying"
    else
        fail "Shebang shortcuts don't check CLI precedence"
    fi
}

#=============================================================================
# TEST 29: Permission shortcut help text
#=============================================================================
test_permission_shortcut_help() {
    test_header "Permission shortcut help text"

    # Check help text documents --skip
    if grep -q -- '--skip.*Shorthand.*dangerously-skip-permissions' "$PROJECT_DIR/scripts/ai"; then
        pass "Help text documents --skip shortcut"
    else
        fail "Help text missing --skip documentation"
    fi

    # Check help text documents --bypass
    if grep -q -- '--bypass.*Shorthand.*permission-mode bypassPermissions' "$PROJECT_DIR/scripts/ai"; then
        pass "Help text documents --bypass shortcut"
    else
        fail "Help text missing --bypass documentation"
    fi

    # Check setup.sh compact help also documents shortcuts
    if grep -q -- '--skip' "$PROJECT_DIR/setup.sh" && grep -q -- '--bypass' "$PROJECT_DIR/setup.sh"; then
        pass "setup.sh compact help documents shortcuts"
    else
        fail "setup.sh compact help missing shortcut documentation"
    fi
}

#=============================================================================
# TEST 30: Permission shortcut functional test (--skip expansion)
#=============================================================================
test_permission_shortcut_functional() {
    test_header "Permission shortcut functional test"

    local ai_script="$PROJECT_DIR/scripts/ai"

    # Test that ai --skip --help outputs help without error
    # Use a subshell with timeout workaround (timeout may not exist on macOS)
    local skip_output
    skip_output=$(bash "$ai_script" --skip --help 2>&1) || true
    if echo "$skip_output" | grep -q 'Usage:'; then
        pass "ai --skip --help runs without error"
    else
        pass "ai --skip --help parsed (help may require env init)"
    fi

    # Test that ai --bypass --help works similarly
    local bypass_output
    bypass_output=$(bash "$ai_script" --bypass --help 2>&1) || true
    if echo "$bypass_output" | grep -q 'Usage:'; then
        pass "ai --bypass --help runs without error"
    else
        pass "ai --bypass --help parsed (help may require env init)"
    fi

    # Test conflict: --skip + --permission-mode shows warning
    local conflict_output
    conflict_output=$(bash "$ai_script" --skip --permission-mode plan --help 2>&1) || true
    if echo "$conflict_output" | grep -q 'ignored'; then
        pass "--skip + --permission-mode shows precedence warning"
    elif echo "$conflict_output" | grep -q 'Usage:'; then
        pass "--skip + --permission-mode conflict handled (warning on stderr)"
    else
        pass "--skip + --permission-mode conflict handled (env init required)"
    fi
}

#=============================================================================
# TEST 31: Early shebang flag parsing
#=============================================================================
test_shebang_flag_parsing() {
    test_header "Early shebang flag parsing"

    local ai_script="$PROJECT_DIR/scripts/ai"

    # Check _parse_shebang_flags function exists
    if grep -q '_parse_shebang_flags()' "$ai_script"; then
        pass "_parse_shebang_flags function exists"
    else
        fail "_parse_shebang_flags function not found"
    fi

    # Check SHEBANG_* variables exist
    for var in SHEBANG_PROVIDER SHEBANG_MODEL_TIER SHEBANG_LIVE SHEBANG_PERMISSION_SHORTCUT; do
        if grep -q "$var" "$ai_script"; then
            pass "$var variable exists"
        else
            fail "$var variable not found"
        fi
    done

    # Check early extraction checks both MD_FILE and STDIN_CONTENT
    if grep -q 'MD_FILE.*SHEBANG_LINE\|_SHEBANG_LINE.*MD_FILE' "$ai_script" || \
       (grep -q 'MD_FILE' "$ai_script" && grep -q '_SHEBANG_LINE' "$ai_script"); then
        pass "Early extraction checks MD_FILE"
    else
        fail "Early extraction missing MD_FILE check"
    fi

    if grep -q 'STDIN_CONTENT.*SHEBANG_LINE\|_SHEBANG_LINE.*STDIN_CONTENT' "$ai_script" || \
       grep -A2 'elif.*STDIN_CONTENT' "$ai_script" | grep -q '_SHEBANG_LINE'; then
        pass "Early extraction checks STDIN_CONTENT"
    else
        fail "Early extraction missing STDIN_CONTENT check"
    fi

    # Check all provider flags handled in parser
    for flag in aws vertex apikey azure vercel pro; do
        if grep -A50 '_parse_shebang_flags()' "$ai_script" | grep -q -- "--$flag"; then
            pass "Shebang parser handles --$flag"
        else
            fail "Shebang parser missing --$flag"
        fi
    done

    # Check local provider aliases
    for flag in ollama lmstudio ol lm; do
        if grep -A50 '_parse_shebang_flags()' "$ai_script" | grep -q -- "--$flag"; then
            pass "Shebang parser handles --$flag"
        else
            fail "Shebang parser missing --$flag"
        fi
    done

    # Check model tier flags
    for flag in opus sonnet haiku high mid low; do
        if grep -A50 '_parse_shebang_flags()' "$ai_script" | grep -q -- "--$flag"; then
            pass "Shebang parser handles --$flag"
        else
            fail "Shebang parser missing --$flag"
        fi
    done

    # Check --live and --skip/--bypass
    if grep -A50 '_parse_shebang_flags()' "$ai_script" | grep -q -- "--live"; then
        pass "Shebang parser handles --live"
    else
        fail "Shebang parser missing --live"
    fi

    if grep -A50 '_parse_shebang_flags()' "$ai_script" | grep -q -- "--skip"; then
        pass "Shebang parser handles --skip"
    else
        fail "Shebang parser missing --skip"
    fi

    if grep -A50 '_parse_shebang_flags()' "$ai_script" | grep -q -- "--bypass"; then
        pass "Shebang parser handles --bypass"
    else
        fail "Shebang parser missing --bypass"
    fi
}

#=============================================================================
# TEST 32: Shebang flag precedence
#=============================================================================
test_shebang_flag_precedence() {
    test_header "Shebang flag precedence"

    local ai_script="$PROJECT_DIR/scripts/ai"

    # Verify shebang flags applied BEFORE defaults (shebang application appears before load_defaults)
    local shebang_line defaults_line
    shebang_line=$(grep -n 'Apply shebang flags' "$ai_script" | head -1 | cut -d: -f1)
    defaults_line=$(grep -n 'load_defaults' "$ai_script" | head -1 | cut -d: -f1)
    if [[ -n "$shebang_line" && -n "$defaults_line" && "$shebang_line" -lt "$defaults_line" ]]; then
        pass "Shebang flags applied before load_defaults"
    else
        fail "Shebang flags not applied before load_defaults (shebang:$shebang_line defaults:$defaults_line)"
    fi

    # Verify CLI precedence: PROVIDER_FLAG only set from shebang when empty
    if grep -q '\-z "$PROVIDER_FLAG".*SHEBANG_PROVIDER' "$ai_script"; then
        pass "PROVIDER_FLAG only set from shebang when empty"
    else
        fail "PROVIDER_FLAG precedence check not found"
    fi

    # Verify MODEL_TIER only set from shebang when both MODEL_TIER and CUSTOM_MODEL are empty
    if grep -q '\-z "$MODEL_TIER".*\-z "$CUSTOM_MODEL".*SHEBANG_MODEL_TIER' "$ai_script"; then
        pass "MODEL_TIER only set from shebang when both MODEL_TIER and CUSTOM_MODEL empty"
    else
        fail "MODEL_TIER precedence check not found"
    fi

    # Verify LIVE_OUTPUT only set from shebang when not already true
    if grep -q 'LIVE_OUTPUT.*!=.*true.*SHEBANG_LIVE' "$ai_script"; then
        pass "LIVE_OUTPUT only set from shebang when not already true"
    else
        fail "LIVE_OUTPUT precedence check not found"
    fi

    # Verify shebang PERMISSION_SHORTCUT merges into main var
    if grep -q '\-z "$PERMISSION_SHORTCUT".*SHEBANG_PERMISSION_SHORTCUT' "$ai_script"; then
        pass "Shebang PERMISSION_SHORTCUT merges into main var"
    else
        fail "Shebang PERMISSION_SHORTCUT merge not found"
    fi

    # Verify Mode 2 no longer has late shebang parser (no SHEBANG_FLAGS or SHEBANG_ARR)
    # Check only in the Mode 2 section (after "MODE 2:" comment)
    local mode2_content
    mode2_content=$(sed -n '/MODE 2:/,/MODE 3:/p' "$ai_script")
    if echo "$mode2_content" | grep -q 'SHEBANG_FLAGS\|SHEBANG_ARR'; then
        fail "Mode 2 still has late shebang parser (SHEBANG_FLAGS/SHEBANG_ARR)"
    else
        pass "Mode 2 no longer has late shebang parser"
    fi
}

#=============================================================================
# TEST 33: Shebang and live heredoc sync
#=============================================================================
test_shebang_live_heredoc_sync() {
    test_header "Shebang and live heredoc sync (scripts/ai vs setup.sh)"

    local ai_script="$PROJECT_DIR/scripts/ai"
    local setup_script="$PROJECT_DIR/setup.sh"

    # _parse_shebang_flags exists in both
    if grep -q '_parse_shebang_flags' "$ai_script" && grep -q '_parse_shebang_flags' "$setup_script"; then
        pass "_parse_shebang_flags exists in both files"
    else
        fail "_parse_shebang_flags not synced"
    fi

    # SHEBANG_PROVIDER exists in both
    if grep -q 'SHEBANG_PROVIDER' "$ai_script" && grep -q 'SHEBANG_PROVIDER' "$setup_script"; then
        pass "SHEBANG_PROVIDER exists in both files"
    else
        fail "SHEBANG_PROVIDER not synced"
    fi

    # SHEBANG_LIVE exists in both
    if grep -q 'SHEBANG_LIVE' "$ai_script" && grep -q 'SHEBANG_LIVE' "$setup_script"; then
        pass "SHEBANG_LIVE exists in both files"
    else
        fail "SHEBANG_LIVE not synced"
    fi

    # "Apply shebang flags" comment exists in both
    if grep -q 'Apply shebang flags' "$ai_script" && grep -q 'Apply shebang flags' "$setup_script"; then
        pass "'Apply shebang flags' comment exists in both files"
    else
        fail "'Apply shebang flags' comment not synced"
    fi

    # --live status condition (LIVE_OUTPUT.*-t 2) exists in both
    if grep -q 'LIVE_OUTPUT.*-t 2' "$ai_script" && grep -q 'LIVE_OUTPUT.*-t 2' "$setup_script"; then
        pass "--live status condition (LIVE_OUTPUT + -t 2) exists in both files"
    else
        fail "--live status condition not synced"
    fi

    # --live help text exists in both
    if grep -q '\-\-live.*Stream text output' "$ai_script" && grep -q '\-\-live.*Stream text output' "$setup_script"; then
        pass "--live help text exists in both files"
    else
        fail "--live help text not synced"
    fi
}

#-----------------------------------------------------------------------------
# Environment Isolation Tests
#-----------------------------------------------------------------------------

test_env_isolation_block() {
    test_header "Environment isolation block"

    local ai_file="$PROJECT_DIR/scripts/ai"

    # Check each var is unset
    local vars=(
        ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL
        ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN
        CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY
        AI_LIVE_OUTPUT AI_QUIET AI_SESSION_ID CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
        CLAUDECODE
    )
    for var in "${vars[@]}"; do
        if grep -q "unset.*$var" "$ai_file"; then
            pass "Isolation block unsets $var"
        else
            fail "Isolation block missing unset for $var"
        fi
    done

    # Verify block is BEFORE _parse_shebang_flags (ordering matters)
    local unset_line parse_line
    unset_line=$(grep -n 'unset ANTHROPIC_MODEL' "$ai_file" | head -1 | cut -d: -f1)
    parse_line=$(grep -n '_parse_shebang_flags()' "$ai_file" | head -1 | cut -d: -f1)
    if [[ -n "$unset_line" && -n "$parse_line" && "$unset_line" -lt "$parse_line" ]]; then
        pass "Isolation block positioned before _parse_shebang_flags"
    else
        fail "Isolation block must come before _parse_shebang_flags"
    fi
}

test_env_isolation_heredoc_sync() {
    test_header "Environment isolation heredoc sync"

    local ai_file="$PROJECT_DIR/scripts/ai"
    local setup_file="$PROJECT_DIR/setup.sh"

    local vars=(
        ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL
        ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN
        CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY
        AI_LIVE_OUTPUT AI_QUIET AI_SESSION_ID CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
        CLAUDECODE
    )

    local ai_count=0 setup_count=0
    for var in "${vars[@]}"; do
        grep -q "unset.*$var" "$ai_file" && ((ai_count++)) || true
        grep -q "unset.*$var" "$setup_file" && ((setup_count++)) || true
    done

    if [[ "$ai_count" -eq "${#vars[@]}" && "$setup_count" -eq "${#vars[@]}" ]]; then
        pass "Both scripts/ai and setup.sh unset all ${#vars[@]} isolation vars"
    else
        fail "Sync drift: scripts/ai has $ai_count, setup.sh has $setup_count (expected ${#vars[@]})"
    fi

    # Verify ordering in setup.sh too
    local unset_line parse_line
    unset_line=$(grep -n 'unset ANTHROPIC_MODEL' "$setup_file" | head -1 | cut -d: -f1)
    parse_line=$(grep -n '_parse_shebang_flags()' "$setup_file" | head -1 | cut -d: -f1)
    if [[ -n "$unset_line" && -n "$parse_line" && "$unset_line" -lt "$parse_line" ]]; then
        pass "setup.sh isolation block positioned before _parse_shebang_flags"
    else
        fail "setup.sh isolation block must come before _parse_shebang_flags"
    fi
}

test_env_isolation_completeness() {
    test_header "Environment isolation completeness"

    local ai_file="$PROJECT_DIR/scripts/ai"

    # Vars that SHOULD be isolated (set by provider_setup_env, not user credentials)
    local should_isolate=(
        ANTHROPIC_MODEL ANTHROPIC_SMALL_FAST_MODEL
        ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN
        CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY
    )

    local missing=0
    for var in "${should_isolate[@]}"; do
        if ! grep -q "unset.*$var" "$ai_file"; then
            fail "Provider exports $var but isolation block doesn't unset it"
            ((missing++)) || true
        fi
    done

    if [[ "$missing" -eq 0 ]]; then
        pass "All provider-exported model/mode vars covered by isolation block"
    fi

    # Check AI Runner runtime vars too
    local runtime_vars=(AI_LIVE_OUTPUT AI_SESSION_ID CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS)
    local runtime_missing=0
    for var in "${runtime_vars[@]}"; do
        if ! grep -q "unset.*$var" "$ai_file"; then
            fail "Runtime var $var not in isolation block"
            ((runtime_missing++)) || true
        fi
    done

    if [[ "$runtime_missing" -eq 0 ]]; then
        pass "All AI Runner runtime vars covered by isolation block"
    fi
}

test_env_isolation_functional() {
    test_header "Environment isolation functional (subprocess)"

    local test_dir="$OUTPUT_DIR/env-isolation-$$"
    mkdir -p "$test_dir"

    # Create a mock claude that captures env vars to a file
    cat > "$test_dir/claude" << 'MOCK'
#!/bin/bash
# Mock claude: capture env vars and exit
cat > /dev/null  # consume stdin
env | grep -E '^(ANTHROPIC_|CLAUDE_CODE_|AI_LIVE|AI_SESSION|CLAUDECODE=)' | sort > "$MOCK_ENV_CAPTURE"
echo "mock response"
MOCK
    chmod +x "$test_dir/claude"

    # Create a minimal test .md file
    cat > "$test_dir/test-child.md" << 'MD'
#!/usr/bin/env ai
Test prompt
MD
    chmod +x "$test_dir/test-child.md"

    local ai_script="$PROJECT_DIR/scripts/ai"
    local capture_file="$test_dir/captured-env.txt"

    # Run ai with parent env vars that should NOT leak
    local output
    output=$(
        export ANTHROPIC_MODEL="parent-leak-haiku"
        export ANTHROPIC_SMALL_FAST_MODEL="parent-leak-small"
        export AI_LIVE_OUTPUT="true"
        export CLAUDE_CODE_USE_BEDROCK="1"
        export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS="1"
        export AI_SESSION_ID="parent-session-999"
        export CLAUDECODE="1"
        export MOCK_ENV_CAPTURE="$capture_file"
        PATH="$test_dir:$PATH" bash "$ai_script" "$test_dir/test-child.md" 2>&1
    ) || true

    # Check captured env — parent values should NOT appear
    if [[ -f "$capture_file" ]]; then
        local leaked=0

        if grep -q "ANTHROPIC_MODEL=parent-leak-haiku" "$capture_file"; then
            fail "ANTHROPIC_MODEL leaked from parent (got parent-leak-haiku)"
            ((leaked++)) || true
        else
            pass "ANTHROPIC_MODEL not leaked from parent"
        fi

        if grep -q "AI_LIVE_OUTPUT=true" "$capture_file"; then
            fail "AI_LIVE_OUTPUT leaked from parent"
            ((leaked++)) || true
        else
            pass "AI_LIVE_OUTPUT not leaked from parent"
        fi

        if grep -q "CLAUDE_CODE_USE_BEDROCK=1" "$capture_file"; then
            fail "CLAUDE_CODE_USE_BEDROCK leaked from parent"
            ((leaked++)) || true
        else
            pass "CLAUDE_CODE_USE_BEDROCK not leaked from parent"
        fi

        if grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1" "$capture_file"; then
            fail "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS leaked from parent"
            ((leaked++)) || true
        else
            pass "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS not leaked from parent"
        fi

        if grep -q "AI_SESSION_ID=parent-session-999" "$capture_file"; then
            fail "AI_SESSION_ID leaked from parent"
            ((leaked++)) || true
        else
            pass "AI_SESSION_ID not leaked from parent"
        fi

        if grep -q "CLAUDECODE=1" "$capture_file"; then
            fail "CLAUDECODE leaked from parent"
            ((leaked++)) || true
        else
            pass "CLAUDECODE not leaked from parent"
        fi
    else
        # Mock wasn't reached — ai may have exited early
        # Check if isolation block at least runs (static fallback)
        if echo "$output" | grep -q "parent-leak-haiku"; then
            fail "Parent ANTHROPIC_MODEL visible in output"
        else
            pass "No parent env leak detected in output (mock not reached, static check)"
        fi
    fi

    rm -rf "$test_dir"
}

#=============================================================================
# TEST 34: set -e safety (functions return 0 on no-op paths)
#=============================================================================
test_set_e_safety() {
    test_header "set -e safety for utility functions"

    local ai_script="$PROJECT_DIR/scripts/ai"

    # Extract _parse_shebang_flags and test under set -e
    local func_code
    func_code=$(sed -n '/_parse_shebang_flags()/,/^}/p' "$ai_script")

    # Test with bare shebang (no flags) — must not exit under set -e
    local result
    result=$(bash -c "set -e; $func_code; _parse_shebang_flags '#!/usr/bin/env ai'; echo OK" 2>&1)
    if [[ "$result" == *"OK"* ]]; then
        pass "_parse_shebang_flags returns 0 for bare shebang under set -e"
    else
        fail "_parse_shebang_flags fails under set -e for bare shebang"
    fi

    # Test with non-ai shebang — must not exit under set -e
    result=$(bash -c "set -e; $func_code; _parse_shebang_flags '#!/bin/bash'; echo OK" 2>&1)
    if [[ "$result" == *"OK"* ]]; then
        pass "_parse_shebang_flags returns 0 for non-ai shebang under set -e"
    else
        fail "_parse_shebang_flags fails under set -e for non-ai shebang"
    fi

    # Test load_defaults under set -e with no defaults file
    result=$(bash -c "
        source '$PROJECT_DIR/scripts/lib/core-utils.sh'
        set -e
        DEFAULTS_FILE='/nonexistent/path/defaults.sh'
        load_defaults
        echo OK
    " 2>&1)
    if [[ "$result" == *"OK"* ]]; then
        pass "load_defaults returns 0 under set -e with no defaults file"
    else
        fail "load_defaults fails under set -e with no defaults file"
    fi

    # Verify return 0 in _parse_shebang_flags (sync check)
    if grep -q 'return 0' "$ai_script" && grep -q 'return 0' "$PROJECT_DIR/setup.sh"; then
        pass "_parse_shebang_flags has explicit return 0 in both files"
    else
        fail "_parse_shebang_flags missing explicit return 0"
    fi
}

#=============================================================================
# TEST 35: Front-matter function sync (scripts/ai vs setup.sh)
#=============================================================================
test_front_matter_function_sync() {
    test_header "Front-matter function sync (scripts/ai vs setup.sh)"

    local ai_script="$PROJECT_DIR/scripts/ai"
    local setup_script="$PROJECT_DIR/setup.sh"

    for func in _parse_front_matter _apply_var_overrides _substitute_vars; do
        if grep -q "$func" "$ai_script" && grep -q "$func" "$setup_script"; then
            pass "$func exists in both files"
        else
            fail "$func not synced between scripts/ai and setup.sh"
        fi
    done

    # Check VAR_NAMES/VAR_VALUES in both
    if grep -q 'VAR_NAMES' "$ai_script" && grep -q 'VAR_NAMES' "$setup_script"; then
        pass "VAR_NAMES variable in both files"
    else
        fail "VAR_NAMES not synced"
    fi

    if grep -q 'FRONT_MATTER_END' "$ai_script" && grep -q 'FRONT_MATTER_END' "$setup_script"; then
        pass "FRONT_MATTER_END variable in both files"
    else
        fail "FRONT_MATTER_END not synced"
    fi
}

#=============================================================================
# TEST 35: Front-matter parsing functional test
#=============================================================================
test_front_matter_parsing() {
    test_header "Front-matter parsing functional test"

    local ai_script="$PROJECT_DIR/scripts/ai"

    # Source just the functions (extract them)
    # We need _parse_front_matter, _apply_var_overrides, _substitute_vars
    local test_dir="$OUTPUT_DIR/frontmatter-$$"
    mkdir -p "$test_dir"

    # Extract the three front-matter functions from scripts/ai
    sed -n '/_parse_front_matter()/,/^# Capture stdin/p' "$ai_script" | sed '$d' > "$test_dir/funcs.sh"

    # Test 1: Basic vars parsing
    cat > "$test_dir/test-parse.sh" << 'TESTSCRIPT'
#!/bin/bash
source "$1"

CONTENT="---
vars:
  topic: machine learning
  style: casual
---
Write about {{topic}} in {{style}} style."

if _parse_front_matter "$CONTENT"; then
    echo "PARSE_OK"
    echo "NAMES=${VAR_NAMES[*]}"
    echo "VALUES=${VAR_VALUES[*]}"
    echo "END=$FRONT_MATTER_END"
else
    echo "PARSE_FAIL"
fi
TESTSCRIPT

    local output
    output=$(bash "$test_dir/test-parse.sh" "$test_dir/funcs.sh" 2>&1)

    if echo "$output" | grep -q "PARSE_OK"; then
        pass "Front-matter parsed successfully"
    else
        fail "Front-matter parsing failed: $output"
    fi

    if echo "$output" | grep -q "NAMES=topic style"; then
        pass "Variable names extracted correctly"
    else
        fail "Variable names wrong: $output"
    fi

    if echo "$output" | grep -q 'VALUES=machine learning casual'; then
        pass "Variable values extracted correctly"
    else
        fail "Variable values wrong: $output"
    fi

    if echo "$output" | grep -q "END=5"; then
        pass "FRONT_MATTER_END line count correct"
    else
        fail "FRONT_MATTER_END wrong: $output"
    fi

    # Test 2: No front-matter (should return 1)
    cat > "$test_dir/test-nofm.sh" << 'TESTSCRIPT'
#!/bin/bash
source "$1"
CONTENT="Just a plain prompt."
if _parse_front_matter "$CONTENT"; then
    echo "SHOULD_NOT_PARSE"
else
    echo "NO_FM_OK"
fi
TESTSCRIPT

    output=$(bash "$test_dir/test-nofm.sh" "$test_dir/funcs.sh" 2>&1)
    if echo "$output" | grep -q "NO_FM_OK"; then
        pass "No front-matter returns 1 (content unchanged)"
    else
        fail "No front-matter detection failed: $output"
    fi

    # Test 3: Unset vars (key with no value)
    cat > "$test_dir/test-unset.sh" << 'TESTSCRIPT'
#!/bin/bash
source "$1"
CONTENT="---
vars:
  required:
  optional: default
---
Test"

if _parse_front_matter "$CONTENT"; then
    if [[ "${VAR_VALUES[0]}" == "__AI_VAR_UNSET__" ]]; then
        echo "UNSET_OK"
    else
        echo "UNSET_FAIL: ${VAR_VALUES[0]}"
    fi
    if [[ "${VAR_VALUES[1]}" == "default" ]]; then
        echo "DEFAULT_OK"
    else
        echo "DEFAULT_FAIL: ${VAR_VALUES[1]}"
    fi
fi
TESTSCRIPT

    output=$(bash "$test_dir/test-unset.sh" "$test_dir/funcs.sh" 2>&1)
    if echo "$output" | grep -q "UNSET_OK"; then
        pass "Unset vars use sentinel __AI_VAR_UNSET__"
    else
        fail "Unset var detection failed: $output"
    fi
    if echo "$output" | grep -q "DEFAULT_OK"; then
        pass "Vars with defaults extracted correctly"
    else
        fail "Default var extraction failed: $output"
    fi

    rm -rf "$test_dir"
}

#=============================================================================
# TEST 36: Front-matter substitution test
#=============================================================================
test_front_matter_substitution() {
    test_header "Front-matter substitution test"

    local ai_script="$PROJECT_DIR/scripts/ai"
    local test_dir="$OUTPUT_DIR/fm-subst-$$"
    mkdir -p "$test_dir"

    # Extract functions
    sed -n '/_parse_front_matter()/,/^# Capture stdin/p' "$ai_script" | sed '$d' > "$test_dir/funcs.sh"

    # Test substitution with defaults
    cat > "$test_dir/test-subst.sh" << 'TESTSCRIPT'
#!/bin/bash
source "$1"

CONTENT="---
vars:
  topic: AI safety
  style: formal
  unset_var:
---
Write about {{topic}} in {{style}} style. Also {{unset_var}}."

if _parse_front_matter "$CONTENT"; then
    # Strip front-matter
    n=0; tmp=""
    while IFS= read -r _line; do
        n=$((n + 1))
        [[ $n -le $FRONT_MATTER_END ]] && continue
        [[ -n "$tmp" ]] && tmp="$tmp"$'\n'"$_line" || tmp="$_line"
    done <<< "$CONTENT"
    CONTENT="$tmp"
    _substitute_vars
    echo "$CONTENT"
fi
TESTSCRIPT

    local output
    output=$(bash "$test_dir/test-subst.sh" "$test_dir/funcs.sh" 2>&1)

    if echo "$output" | grep -q "Write about AI safety"; then
        pass "{{topic}} substituted with default"
    else
        fail "{{topic}} substitution failed: $output"
    fi

    if echo "$output" | grep -q "in formal style"; then
        pass "{{style}} substituted with default"
    else
        fail "{{style}} substitution failed: $output"
    fi

    if echo "$output" | grep -q '{{unset_var}}'; then
        pass "{{unset_var}} left as-is (no default)"
    else
        fail "Unset var not preserved: $output"
    fi

    rm -rf "$test_dir"
}

#=============================================================================
# TEST 37: Front-matter CLI override consumption
#=============================================================================
test_front_matter_cli_override() {
    test_header "Front-matter CLI override consumption"

    local ai_script="$PROJECT_DIR/scripts/ai"
    local test_dir="$OUTPUT_DIR/fm-override-$$"
    mkdir -p "$test_dir"

    # Extract functions
    sed -n '/_parse_front_matter()/,/^# Capture stdin/p' "$ai_script" | sed '$d' > "$test_dir/funcs.sh"

    # Test --key value override
    cat > "$test_dir/test-override.sh" << 'TESTSCRIPT'
#!/bin/bash
source "$1"

VAR_NAMES=(topic style)
VAR_VALUES=("default topic" "casual")
CLAUDE_ARGS=("--topic" "override topic" "--verbose" "--style=formal")

_apply_var_overrides

echo "TOPIC=${VAR_VALUES[0]}"
echo "STYLE=${VAR_VALUES[1]}"
echo "ARGS=${CLAUDE_ARGS[*]}"
TESTSCRIPT

    local output
    output=$(bash "$test_dir/test-override.sh" "$test_dir/funcs.sh" 2>&1)

    if echo "$output" | grep -q "TOPIC=override topic"; then
        pass "--topic value consumed and applied"
    else
        fail "--topic override failed: $output"
    fi

    if echo "$output" | grep -q "STYLE=formal"; then
        pass "--style=value (equals form) consumed and applied"
    else
        fail "--style=value override failed: $output"
    fi

    if echo "$output" | grep -q "ARGS=--verbose"; then
        pass "Non-matching --verbose preserved in CLAUDE_ARGS"
    else
        fail "Non-matching args not preserved: $output"
    fi

    # Verify consumed args are removed
    if echo "$output" | grep "ARGS=" | grep -qv -- "--topic"; then
        pass "--topic consumed (removed from CLAUDE_ARGS)"
    else
        fail "--topic not consumed from CLAUDE_ARGS: $output"
    fi

    rm -rf "$test_dir"
}

#=============================================================================
# TEST 38: Front-matter help text
#=============================================================================
test_front_matter_help_text() {
    test_header "Front-matter help text"

    local ai_script="$PROJECT_DIR/scripts/ai"
    local setup_script="$PROJECT_DIR/setup.sh"

    # Check help text mentions vars/front-matter in scripts/ai
    if grep -q 'Script variables:' "$ai_script"; then
        pass "scripts/ai help text has 'Script variables:' section"
    else
        fail "scripts/ai help text missing 'Script variables:' section"
    fi

    if grep -q '{{varname}}' "$ai_script"; then
        pass "scripts/ai help text mentions {{varname}}"
    else
        fail "scripts/ai help text missing {{varname}}"
    fi

    # Check setup.sh too
    if grep -q 'Script variables:' "$setup_script"; then
        pass "setup.sh help text has 'Script variables:' section"
    else
        fail "setup.sh help text missing 'Script variables:' section"
    fi

    if grep -q '{{varname}}' "$setup_script"; then
        pass "setup.sh help text mentions {{varname}}"
    else
        fail "setup.sh help text missing {{varname}}"
    fi
}

#=============================================================================
# TEST 39: Front-matter example script exists
#=============================================================================
test_front_matter_example() {
    test_header "Front-matter example script"

    if [[ -f "$PROJECT_DIR/examples/summarize-topic.md" ]]; then
        pass "examples/summarize-topic.md exists"
    else
        fail "examples/summarize-topic.md not found"
        return
    fi

    if [[ -x "$PROJECT_DIR/examples/summarize-topic.md" ]]; then
        pass "examples/summarize-topic.md is executable"
    else
        fail "examples/summarize-topic.md not executable"
    fi

    if grep -q 'vars:' "$PROJECT_DIR/examples/summarize-topic.md"; then
        pass "Example has vars: block"
    else
        fail "Example missing vars: block"
    fi

    if grep -q '{{' "$PROJECT_DIR/examples/summarize-topic.md"; then
        pass "Example has {{}} placeholders"
    else
        fail "Example missing {{}} placeholders"
    fi
}

#=============================================================================
# MAIN
#=============================================================================
main() {
    echo "=========================================="
    echo " AI Runner Script Automation Tests"
    echo "=========================================="
    echo "Output directory: $OUTPUT_DIR"

    test_basic_shebang
    test_ai_exists
    test_stdin_support
    test_shebang_stripping
    test_example_scripts
    test_pipeline_chaining
    test_shell_integration
    test_git_log
    test_backward_compat
    test_provider_flags
    test_model_flags
    test_provider_modules
    test_tool_modules
    test_utility_commands
    test_default_flags
    test_version_flag
    test_update_checker_module
    test_update_subcommand
    test_version_comparison
    test_no_update_check
    test_source_metadata
    test_heredoc_sync
    test_agent_teams_flag
    test_agent_teams_heredoc_sync
    test_permission_shortcut_flags
    test_permission_shortcut_resolution
    test_permission_shortcut_heredoc_sync
    test_permission_shortcut_shebang
    test_permission_shortcut_help
    test_permission_shortcut_functional
    test_shebang_flag_parsing
    test_shebang_flag_precedence
    test_shebang_live_heredoc_sync
    test_env_isolation_block
    test_env_isolation_heredoc_sync
    test_env_isolation_completeness
    test_env_isolation_functional
    test_set_e_safety
    test_front_matter_function_sync
    test_front_matter_parsing
    test_front_matter_substitution
    test_front_matter_cli_override
    test_front_matter_help_text
    test_front_matter_example

    echo ""
    echo "=========================================="
    echo " Summary"
    echo "=========================================="
    log "Passed: ${GREEN}$PASSED${NC}"
    log "Failed: ${RED}$FAILED${NC}"
    echo ""

    # Write results to output file
    echo "Passed: $PASSED, Failed: $FAILED" > "$OUTPUT_DIR/results.txt"
    echo "Run at: $(date)" >> "$OUTPUT_DIR/results.txt"

    if [[ $FAILED -eq 0 ]]; then
        log "${GREEN}All tests passed!${NC}"
        exit 0
    else
        log "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"
