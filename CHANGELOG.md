# Changelog

All notable changes to claude-switcher will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
