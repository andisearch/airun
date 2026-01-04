# Changelog

All notable changes to claude-switcher will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- Vercel-specific model identifiers: `anthropic/claude-sonnet-4.5`, `anthropic/claude-opus-4`, `anthropic/claude-haiku-4.5`
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
- Automatic version update notifications in setup.sh
- Integration tests for all provider modes
- Support for additional Claude providers as they become available

---

**Versioning Guidelines:**
- **MAJOR (x.0.0)**: Breaking changes to CLI interface or configuration format
- **MINOR (1.x.0)**: New features (new providers, new flags, new functionality)
- **PATCH (1.0.x)**: Bug fixes, documentation updates, minor improvements
