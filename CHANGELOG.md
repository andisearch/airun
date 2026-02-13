# Changelog

All notable changes to AI Runner will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.4] - 2026-02-12

### Fixed
- **`--live` output splitting**: System prompt no longer hints at markdown headings, improving non-markdown output (code, JSON, plain text)
- **`--live` "Done" message**: Changed "written to file" to "written" — the message appears for pipes too, not just file redirects

### Improved
- **`--live` documentation**: Explain turn-level streaming granularity and the need for narration instructions in prompts (e.g., "print your findings as you go") for intermediate output to stream

## [2.3.3] - 2026-02-12

### Fixed
- **Shebang flag parsing**: `ai file.md` and `cat file.md | ai` now correctly
  honor all shebang flags (provider, model, permissions, --live)
- **Flag precedence**: Corrected to CLI > shebang > defaults (previously
  shebang flags were ignored in Mode 1 and parsed too late in Mode 2)
- **`--live` status messages**: Show `[AI Runner]` status on stderr when stdout
  is redirected to file, so users get progress feedback during long-running scripts

### Added
- **`--live` flag**: Stream text output in real-time for script mode
  - `ai --live --skip task.md` or `#!/usr/bin/env -S ai --skip --live` in shebangs
  - Pipes `claude`'s `stream-json` output through `jq` to extract human-readable text
  - Shows each agentic turn as it completes — useful for long-running scripts
  - **Smart output splitting** when redirecting to a file (`> report.md`):
    narration streams to stderr, clean content (from first `#` heading) goes to file,
    "Done (N lines written)" status on stderr when complete
  - Requires `jq` (clear error message if missing)
  - Works in all script modes: shebang, piped, and CLI file execution
  - Pairs well with `--chrome` for browser automation with real-time progress
- **`examples/` directory**: Ready-to-run example scripts demonstrating key features
  - `hello.md` — minimal shebang
  - `analyze-code.md` — read-only analysis
  - `run-tests.md` — automation with `--skip`
  - `live-report.md` — live streaming with `--live`
  - `analyze-stdin.md` — stdin piping

## [2.3.2] - 2026-02-09

### Added
- **Permission shortcut flags**: `--skip` and `--bypass` for cleaner shebangs and CLI usage
  - `--skip` — shortcut for `--dangerously-skip-permissions`
  - `--bypass` — shortcut for `--permission-mode bypassPermissions`
  - Explicit `--permission-mode` or `--dangerously-skip-permissions` flags take precedence over shortcuts (warning shown)
  - CLI flags override shebang flags (same precedence as provider/model flags)
  - Updated SCRIPTING.md with permission flag precedence table and security guidance

## [2.3.1] - 2026-02-07

### Added
- **Agent Teams support (`--team`)**: Enable Claude Code's multi-agent collaboration feature
  - `ai --team` sets `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to enable agent teams
  - Use Claude Code's native `--teammate-mode` flag for display control (`in-process`, `tmux`)
  - Works with all providers (AWS, Vertex, Anthropic API, Azure, Vercel, Pro, Ollama, LM Studio)
  - Interactive mode only — warns via stderr if explicitly passed in script mode; silently skipped when from saved defaults
  - Persistable with `ai --team --set-default`; both `--team` and `--teammate-mode` are saved
  - Session tracking includes team status; `ai-sessions` shows `[team]` indicator
  - `ai-status` displays agent teams environment variable when set
- **Tests 23-24**: Agent teams flag parsing and heredoc sync validation

## [2.3.0] - 2026-02-07

### Added
- **`ai update` subcommand**: One-command self-update — pulls latest code and re-runs `setup.sh`
  - Tracks source directory via `/usr/local/share/ai-runner/.source-metadata` (written by `setup.sh`)
  - Warns on local modifications before pulling
  - Clears update cache after successful update
- **Update notifications**: Non-blocking cached check against GitHub Releases API
  - Shows "Update available: v2.2.2 -> v2.3.0" in interactive mode banner and `ai-status`/`ai-sessions`
  - Cache refreshes in background every 24 hours — never blocks launch
  - Disable with `export AI_NO_UPDATE_CHECK=1`
- **Tests 17-22**: Update checker module, subcommand parsing, version comparison, cache cycle, `AI_NO_UPDATE_CHECK`, source metadata format, heredoc sync

### Fixed
- **Setup sudo loop**: `setup.sh` now validates sudo credentials upfront with `sudo -v`, exiting immediately with a clear error if authentication fails instead of repeatedly prompting for every file copy

## [2.2.2] - 2026-02-05

### Added
- **Vercel AI Gateway multi-model support**: Document and fix support for 100+ non-Anthropic models (OpenAI, xAI, Google, Meta, Mistral, DeepSeek, etc.) via `--vercel --model provider/model`

### Fixed
- **Vercel small/fast model for non-Anthropic models**: When using `--vercel --model xai/grok-code-fast-1` (or any non-Anthropic model), `ANTHROPIC_SMALL_FAST_MODEL` is now set to the same model to avoid provider mixing (e.g., xAI main + Anthropic background)

## [2.2.1] - 2026-02-05

### Fixed
- **`ai-sessions` no output**: Installed version sourced legacy `claude-switcher-utils.sh` which set wrong sessions directory; now uses `SHARE_DIR` fallback to load correct `core-utils.sh`
- **`ai-status` library loading**: Added `SHARE_DIR` fallback so `ai-status` finds libs when installed to `/usr/local/bin`
- **`ai-status` Claude Pro detection**: Replaced broken file checks (`session.json`/`.credentials`) with cross-platform detection — macOS Keychain (`security find-generic-password`) and Linux/WSL (`~/.claude/.credentials.json`)
- **`[Claude Switcher]` branding**: Fixed stale branding appearing in `ai-sessions` when run from installed location
- **Session isolation hardening**: `_provider_disable_all()` now unsets `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, `ANTHROPIC_MODEL`, `ANTHROPIC_SMALL_FAST_MODEL` for a clean slate when switching providers

## [2.2.0] - 2026-02-05

### Added
- **`--set-default` / `--clear-default` flags**: Save preferred provider and model tier as persistent defaults
  - `ai --vercel --opus --set-default` saves preference to `~/.ai-runner/defaults.sh`
  - `ai --clear-default` removes saved defaults
  - CLI flags always override saved defaults
- **Setup model update prompt**: `setup.sh` now detects model config changes and prompts before overwriting

### Changed
- **Opus 4.6 model IDs**: Updated Opus from 4.5 to 4.6 across all providers
  - Anthropic API: `claude-opus-4-6`
  - AWS Bedrock: `global.anthropic.claude-opus-4-6-v1`
  - Vertex AI: `claude-opus-4-6`
  - Azure: `claude-opus-4-6`
  - Vercel: `anthropic/claude-opus-4.6`
  - OpenRouter: `anthropic/claude-opus-4.6`
- **Pro default behavior**: `ai --pro` (no model flag) no longer hardcodes Opus; Claude Code uses its own latest default model

### Fixed
- Vertex region override loop now includes `VERTEX_REGION_CLAUDE_4_6_OPUS`
- OpenRouter model IDs in `secrets.example.sh` now use dots (matching `config/models.sh`)
- Fixed incorrect Sonnet date in `docs/PROVIDERS.md` model alias example

## [2.1.0] - 2026-01-30

### Added
- **LM Studio Provider**: Local AI with MLX support via `--lmstudio` or `--lm` flag
  - Anthropic-compatible API on localhost:1234
  - MLX models for faster inference on Apple Silicon
  - Auto-detects loaded models from LM Studio server
  - See [docs/PROVIDERS.md](docs/PROVIDERS.md) for setup
- **Auto-Download Models**: Both Ollama and LM Studio now offer to download missing models
  - `ai --ollama --model qwen3` prompts to pull if not installed
  - `ai --lm --model publisher/model` prompts to download if not found
  - Ollama offers choice between local and cloud versions (recommends cloud for < 20GB VRAM)
  - Works in interactive mode only (non-interactive fails gracefully)
- **Provider Flag Shortcuts**: `--ol` for Ollama, `--lm` for LM Studio
- **Model Load/Unload**: LM Studio provider can load/unload models via REST API
- **Shared System Utils**: `scripts/lib/system-utils.sh` for RAM/GPU/VRAM detection
- **Provider Documentation**: Moved detailed provider setup to `docs/PROVIDERS.md`

### Changed
- README provider section simplified with summary table + link to docs

## [2.0.1] - 2026-01-26

### Changed
- **Repository Renamed**: GitHub repository renamed from `claude-switcher` to `airun`
  - Previous URL (`github.com/andisearch/claude-switcher`) automatically redirects
  - All GitHub URLs in documentation updated
  - Added "Name History" section to README for discoverability

## [2.0.0] - 2026-01-25

### Added
- **AI Runner Rebranding**: Project renamed from claude-switcher to AI Runner
  - New primary command: `ai` (with `airun` alias)
  - New utilities: `ai-sessions`, `ai-status`
  - New config directory: `~/.ai-runner/` (migrates from ~/.claude-switcher/)
- **Ollama Provider**: Local free AI with `--ollama` flag
- **Provider Abstraction Layer**: Modular provider system in `providers/`
- **Tool Abstraction Layer**: Modular tool system in `tools/`
- **Model Tier Aliases**: `--high`, `--mid`, `--low` as alternatives to `--opus`, `--sonnet`, `--haiku`

### Changed
- Primary command is now `ai` instead of `claude-run`
- Config directory moved to `~/.ai-runner/` (automatic migration)
- Install location: `/usr/local/share/ai-runner/`

### Backward Compatibility
- All `claude-*` commands continue to work unchanged
- Existing shebang scripts with `claude-run` still work
- `~/.claude-switcher/` configuration still supported

## [1.3.1] - 2026-01-11

### Added
- **Piped Script Execution**: Run markdown scripts from the web via stdin
  - `curl -fsSL https://example.com/install.md | claude-run` executes remote AI scripts
  - Supports [install.md](https://installmd.mintlify.app/) proposal for human-readable installation instructions
  - Shebang flags in piped content are honored (e.g., `--permission-mode bypassPermissions`)
  - CLI flags override shebang flags for safety
  - Simple prompts work too: `echo "Analyze this codebase" | claude-run`

## [1.3.0] - 2026-01-07

### Added
- **Stdin Piping Support**: Pipe data into executable markdown scripts for Unix-style workflows
  - `echo '{"data": 1}' | ./analyze.md` - stdin content is prepended to prompt by default
  - `cat data.txt | ./process.md --stdin-position append` - optionally append instead
  - Enables chaining scripts: `./generate.md | ./format.md > output.txt`
- **`--stdin-position` Flag**: Control where piped input appears in the prompt
  - `prepend` (default): stdin content comes before the markdown file content
  - `append`: stdin content comes after the markdown file content
- **Automation Test Suite**: Validates all README script examples (`./test/automation/run_tests.sh`)
  - Tests shebang execution, stdin piping, pipeline chaining, shell integration
  - Also available as executable markdown: `./test/automation/run_tests.md`
- **Full Automation Mode**: Document `--permission-mode bypassPermissions` for unattended scripts
  - Enables AI scripts to run commands without interactive approval
  - Use in CI/CD pipelines and trusted automation environments

### Fixed
- **Pipe Output Pollution**: Console output (banners, `[Claude Switcher]` messages) no longer pollutes stdout when piping to files
  - Added `is_interactive()` TTY detection to suppress banners in non-interactive mode
  - All status messages now route to stderr instead of stdout
  - `./script.md > result.txt` now produces clean output without escape codes
- Banner and print functions redirected to stderr for proper Unix semantics

## [1.2.0] - 2026-01-04

### Added
- **`claude-run` Unified Entry Point**: New command that combines provider switching and executable markdown
  - Interactive mode: `claude-run --aws --opus --resume` (equivalent to `claude-aws --opus --resume`)
  - Shebang mode: Executable markdown files with `#!/usr/bin/env claude-run`
  - Provider flags: `--aws`, `--vertex`, `--apikey`, `--azure`, `--vercel`, `--pro`
  - Model flags: `--opus`, `--sonnet`, `--haiku`, `--model <id>`
  - Full passthrough of all native `claude` flags
- **Executable Markdown**: Run AI prompts as scripts
  - Supports `#!/usr/bin/env claude-run` shebang
  - Multiple flags via `#!/usr/bin/env -S claude-run --aws --opus`
  - Works with `--output-format json` for scripting
- **Security Documentation**: Clear warnings about non-interactive mode risks
  - Trust model explanations (same as `claude -p`)
  - Guidance on `--dangerously-skip-permissions` appropriate usage

### Changed
- **README Restructure**: `claude-run` is now the primary recommended approach
  - Cleaner Quick Start section
  - Individual provider scripts (`claude-aws`, etc.) documented as secondary option
  - Added security warnings for shebang mode
- Setup output now highlights `claude-run` as recommended entry point

## [1.1.0] - 2026-01-03

### Added
- **Vercel AI Gateway Support**: New `claude-vercel` command to route Claude Code through Vercel's AI Gateway
  - Provides automatic failover (e.g., to AWS Bedrock)
  - Unified billing and spend management across all AI providers
  - Uses `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` per [rauchg's announcement](https://x.com/rauchg/status/2007556249437778419)
- Vercel-specific model identifiers: `anthropic/claude-sonnet-4.5`, `anthropic/claude-opus-4.5`, `anthropic/claude-haiku-4.5`
- New configuration options: `VERCEL_AI_GATEWAY_TOKEN` and `VERCEL_AI_GATEWAY_URL`

## [1.0.8] - 2025-12-04

### Fixed
- **Critical Bug Fixes in `claude-pro` script**:
  - **Syntax Error (Line 40)**: Removed malformed backslash-quote causing "unexpected EOF while looking for matching `"'" error
  - **Authentication Conflict**: Added missing `unset ANTHROPIC_API_KEY` to prevent "Auth conflict" warning
    - Now properly unsets `ANTHROPIC_API_KEY` before launching Claude Code (matching pattern from other scripts)
    - Ensures only web authentication is active for Claude Pro/Max sessions
    - Environment variable is still saved and restored on exit
  - Script now passes bash syntax validation and runs without authentication conflicts
  - Thanks to Reddit user for reporting the initial syntax issue

## [1.0.7] - 2025-11-24

### Changed
- **Model Update**: Updated default Claude Opus model from 4.1 to 4.5 across all providers
  - AWS Bedrock: `global.anthropic.claude-opus-4-5-20251101-v1:0`
  - Google Vertex AI: `claude-opus-4-5@20251101`
  - Anthropic API: `claude-opus-4-5-20251101`
  - Microsoft Azure Foundry: `claude-opus-4-5`
- Updated `config/models.sh` with new Opus 4.5 model identifiers
- Updated `secrets.example.sh` model override examples to reflect Opus 4.5

## [1.0.6] - 2025-11-23

### Changed
- Updated Claude Code link to official product page (claude.com/product/claude-code)
- Improved Vertex AI Model Garden links to use general model garden URL instead of model-specific URL
- Enhanced provider configuration documentation with direct links to Anthropic's official setup guides
  - Added link to Google Vertex AI instructions
  - Added link to Microsoft Foundry instructions

### Improved
- Better navigation to external documentation resources
- More reliable links that won't break when specific model URLs change
- Clearer guidance for users following provider-specific setup steps

## [1.0.5] - 2025-11-23

### Changed
- **README Simplification**: Streamlined documentation from 704 to 503 lines (28.5% reduction)
  - Converted verbose usage examples to scannable table format (40 line reduction)
  - Condensed "How It Works" section from technical details to clear bullet points (23 line reduction)
  - Simplified provider configuration sections with links to external docs (33 line reduction)
  - Reorganized troubleshooting with common issues first (44 line reduction)
  - Reduced model configuration section by removing redundant variable listings (53 line reduction)
- Improved Quick Start section with example of switching back to native Claude Code
- Enhanced Azure configuration documentation to clarify default deployment names
- Refined workflow examples for better clarity (e.g., "Complex reasoning needed" vs "Large codebase")
- Updated versioning section to reference VERSION file dynamically

### Improved
- Significantly enhanced README scannability and user experience
- Better information hierarchy prioritizing common use cases
- Reduced redundancy while maintaining all essential information
- File size reduced by 24.8% (25,993 → 19,547 bytes)

## [1.0.4] - 2025-11-23

### Added
- **Comprehensive Session Tracking**: `claude-sessions` now displays detailed information about active Claude sessions
  - Shows provider (AWS Bedrock, Vertex AI, Anthropic API, Claude Pro)
  - Shows model name, region/project, session ID, and uptime
  - File-based tracking system in `~/.claude-switcher/sessions/`
- **Robust Stale Session Cleanup**: Automatic cleanup of session files for non-existent PIDs
  - Multiple verification layers ensure only active sessions are displayed
  - Protection against PID reuse (verifies process is actually Claude)
- **Enhanced `claude-status`**: Now detects and displays current session information
  - Shows active session details when running within a Claude session
  - Displays provider, model, region, auth method, and uptime
- Session tracking functions in `claude-switcher-utils.sh`:
  - `write_session_info()`: Records session metadata on startup
  - `cleanup_session_info()`: Removes session file on exit
  - `cleanup_stale_sessions()`: Removes files for dead processes

### Changed
- Updated all wrapper scripts (`claude-aws`, `claude-vertex`, `claude-apikey`, `claude-pro`, `claude-azure`) to write and clean up session tracking files
- Rewrote `claude-sessions` from process-based detection to file-based tracking for reliability
- `claude-sessions` output now includes comprehensive session metadata in formatted table

### Fixed
- Session tracking now works reliably on macOS (previous process-based approach was unreliable)
- `claude-sessions` no longer shows stale sessions or "Mode: Unknown"

## [1.0.2] - 2025-11-23

### Added
- **ASCII Banner**: Welcome banner displaying "Claude Switcher" branding on command launch
- Banner uses ANSI colors matching Andi AI brand (blue/cyan theme)
- Centralized banner configuration in `~/.claude-switcher/banner.sh`
- All command scripts (`claude-aws`, `claude-azure`, `claude-vertex`, `claude-apikey`, `claude-pro`) now display banner on startup

### Changed
- Updated `setup.sh` to install banner configuration file
- Added `display_banner()` function to `claude-switcher-utils.sh` for centralized banner management
- Enhanced project branding with "Brought to you by Andi AI" tagline

## [1.0.1] - 2025-11-22


### Fixed
- **Authentication conflict**: claude-apikey no longer exports ANTHROPIC_API_KEY as an environment variable, preventing "Auth conflict" warning from Claude CLI
- apiKeyHelper now reads the API key directly from secrets.sh, avoiding dual authentication method detection

## [1.0.0] - 2025-11-22

### Added
- **Session-scoped API key switching**: claude-apikey and claude-pro now preserve and restore original apiKeyHelper configuration
- **State preservation**: Automatic save/restore of existing apiKeyHelper settings for non-destructive operation
- **Multi-session support**: Independent state tracking for concurrent Claude sessions
- **Uninstall script**: Safe removal of all installed components with interactive prompts
- **Semantic versioning**: VERSION file and `--version` flag support across all wrapper scripts
- API key helper script for dynamic Anthropic API authentication
- Mode tracking via `current-mode.sh`
- Comprehensive documentation of session-scoped behavior

### Changed
- Removed destructive `/logout` calls from claude-apikey (now uses apiKeyHelper)
- Simplified claude-pro to temporarily disable apiKeyHelper for session
- Updated all wrapper scripts to use session-scoped restore traps
- Enhanced claude-status to show apiKeyHelper configuration and current mode
- Updated README with "How It Works" section explaining apiKeyHelper mechanism
- Improved installation documentation to emphasize non-destructive nature

### Fixed
- Plain `claude` command now always runs in native state after wrapper exits
- Existing user apiKeyHelper configurations are preserved and restored
- No longer modifies `~/.claude/settings.json` during setup (only during wrapper sessions)

## [Unreleased]

### Planned
- Integration tests for all provider modes
- Support for additional Claude providers as they become available

---

**Versioning Guidelines:**
- **MAJOR (x.0.0)**: Breaking changes to CLI interface or configuration format
- **MINOR (1.x.0)**: New features (new providers, new flags, new functionality)
- **PATCH (1.0.x)**: Bug fixes, documentation updates, minor improvements
