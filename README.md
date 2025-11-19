# Claude Switcher

A collection of scripts to easily switch between different authentication modes and providers for [Claude Code](https://claude.ai/code).

## Features

- **Multiple Providers**: Support for Anthropic API, AWS Bedrock, and Google Vertex AI.
- **Model Switching**: Easily switch between Sonnet 4.5, Opus 4.1, or custom models.
- **Pro Plan Support**: Toggle back to standard Claude Pro web authentication.
- **Session Management**: Unique session IDs for tracking.
- **Secure Configuration**: API keys stored in a separate, git-ignored file.

## Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/claude-switcher.git
   cd claude-switcher
   ```

2. Run the setup script:
   ```bash
   ./setup.sh
   ```

3. Configure your secrets:
   Edit `~/.claude-switcher/secrets.sh` and add your API keys/credentials.

4. Add the scripts to your PATH (optional but recommended):
   ```bash
   export PATH="/path/to/claude-switcher/scripts:$PATH"
   ```

## Usage

### AWS Bedrock
```bash
# Use default model (Sonnet 4.5)
claude-aws

# Use Opus 4.1
claude-aws --opus

# Use a custom model ID
claude-aws --model "us.anthropic.claude-3-5-sonnet-20241022-v2:0"
```

### Google Vertex AI
```bash
# Use default model
claude-vertex

# Use Opus
claude-vertex --opus
```

### Anthropic API
```bash
# Use default model
claude-anthropic

# Use Opus
claude-anthropic --opus
```

### Claude Pro Plan
```bash
# Switch back to standard web auth
claude-pro

# OR simply run claude directly (works if no environment variables are set)
claude
```

## Configuration

### Models
Default model IDs are defined in `config/models.sh`. You can modify this file to change defaults for the project, or override them with environment variables.

### Model Overrides
You can override the default models without changing `config/models.sh` by defining them in your `~/.claude-switcher/secrets.sh` file. This is useful for testing new models or using custom fine-tuned models.

Example `secrets.sh` override:
```bash
# Override AWS Sonnet model
export CLAUDE_MODEL_SONNET_AWS="us.anthropic.claude-3-5-sonnet-20241022-v2:0"
```

### Secrets
Credentials are stored in `~/.claude-switcher/secrets.sh`. This file is not committed to the repository.

## License

MIT License. Copyright (c) 2025 Jed White from Andi AI Search.
