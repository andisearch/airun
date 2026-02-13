# Scripting & Automation Guide

How to write executable markdown scripts that go beyond read-only prompts — scripts that write files, run commands, and take real actions.

## The `-S` Flag (Essential for Shebangs)

Standard `env` only passes a single argument. To pass flags to `ai` in a shebang, you need `env -S` (split string):

```markdown
#!/usr/bin/env ai                        # Works (no extra flags)
#!/usr/bin/env -S ai --aws               # Works (with -S)
#!/usr/bin/env ai --aws                  # FAILS — env treats "ai --aws" as one command
```

`-S` tells `env` to split the string into separate arguments. Use it whenever your shebang has flags.

## Permission Modes

By default, `claude -p` (and `ai` in script mode) runs with limited permissions — it will refuse to write files, run commands, or take actions without approval. For scripts that need to *do* things, you need to set a permission mode.

### Available Modes

| Mode | Shebang Flag | Shortcut | Behavior |
|------|-------------|----------|----------|
| **Default** | *(none)* | — | Read-only — can analyze code but won't modify anything |
| **Bypass Mode** | `--permission-mode bypassPermissions` | `--bypass` | Full access via permission mode system — composable with other settings |
| **Skip Permissions** | `--dangerously-skip-permissions` | `--skip` | Nuclear — bypasses ALL permission checks, overrides `--permission-mode` |
| **Allowed Tools** | `--allowedTools 'Bash(npm test)' 'Write'` | — | Granular — only specified tools allowed |

> **Note:** `--bypass` and `--skip` both result in no permission prompts, but `--skip` (`--dangerously-skip-permissions`) is more aggressive — it overrides any `--permission-mode` flag. Use `--bypass` when you may want to compose with other permission settings in the future.

### Examples

**Read-only script** (no permission flags needed):
```markdown
#!/usr/bin/env ai
Analyze this codebase and summarize the architecture.
```

**Full automation** (script needs to run commands and write files):
```markdown
#!/usr/bin/env -S ai --skip
Run the test suite and fix any failing tests.
```
Or equivalently: `#!/usr/bin/env -S ai --bypass` or `#!/usr/bin/env -S ai --permission-mode bypassPermissions`

**Granular permissions** (only allow specific tools):
```markdown
#!/usr/bin/env -S ai --allowedTools 'Bash(npm test)' 'Bash(npm run lint)' 'Read'
Run tests and linting. Report results but do not modify any files.
```

## Common Patterns

### Run tests and report results
```markdown
#!/usr/bin/env -S ai --skip
Run `./test/automation/run_tests.sh` and summarize: how many passed/failed.
```

### Generate a file
```markdown
#!/usr/bin/env -S ai --skip
Read the source files in `src/` and generate a `ARCHITECTURE.md` documenting the codebase structure.
```

### Pipe data in, get results out
```bash
cat data.json | ./analyze.md > results.txt
```

```markdown
#!/usr/bin/env ai
Analyze the JSON data provided on stdin. Summarize key trends and outliers.
```
Note: Read-only analysis of piped input doesn't need permission flags.

### Code review with provider selection
```markdown
#!/usr/bin/env -S ai --aws --opus
Review the code in this repository for security vulnerabilities.
Focus on OWASP Top 10 issues. Be specific about file and line numbers.
```

### CI/CD automation
```markdown
#!/usr/bin/env -S ai --apikey --haiku --skip
Run the linter and fix any issues. Then run the test suite.
Commit fixes with a descriptive message if all tests pass.
```

## Live Output

By default, `ai` in script mode waits for the full response before printing anything. Use `--live` to stream text to the terminal as it's generated — useful for long-running scripts where you want to see progress in real-time.

### How streaming works

`--live` streams at **turn granularity** — each time Claude writes a text response between tool calls, that text appears immediately. This means your prompt needs to tell Claude to narrate its progress, otherwise it may silently use tools and only output text at the end.

**Streams incrementally** (Claude narrates between tool calls):
```markdown
#!/usr/bin/env -S ai --skip --live
Explore this repository. Print a brief summary after examining each
directory. Finally, generate a concise report in markdown format.
```

**No intermediate output** (Claude works silently, then reports):
```markdown
#!/usr/bin/env -S ai --skip --live
Explore this repository and write a summary.
```

Both produce the same final result, but only the first streams progress to the terminal. The key is phrases like **"print as you go"**, **"step by step"**, or **"describe what you find"** — these prompt Claude to write text between tool calls, giving `--live` something to stream.

### Piped content with live streaming
```bash
cat data.json | ai --live --skip analyze.md
```

### Output redirection

When stdout is redirected to a file, `--live` automatically separates narration from content:

```bash
./live-report.md > report.md
```

**Console (stderr):**
```
[AI Runner] Using: Claude Code + Claude Pro
[AI Runner] Model: (system default)

I'll explore the repository structure and key files...
Now let me look at the core scripts and provider structure.
Here's my report:
[AI Runner] Done (70 lines written)
```

**File (stdout):**
```markdown
# Repository Summary
...clean report content only...
```

How it works:
- Intermediate turns (narration, progress) stream to stderr in real-time
- The last turn is split at the first markdown heading (`#`)
- Preamble text before the heading goes to stderr
- Content from the heading onward goes to the file
- A "Done (N lines written)" summary appears on stderr when complete

### Browser automation with Chrome
`--live` pairs well with `--chrome` (a Claude Code flag) for browser test scripts where steps take time and you need real-time progress:
```markdown
#!/usr/bin/env -S ai --skip --chrome --live
Navigate to the app and verify the login flow works.
```

> **Note:** `--live` requires `jq` to be installed (`brew install jq` on macOS).

## Passing Claude Code Flags

Any flag not recognized by `ai` is passed directly to Claude Code. Useful flags for scripts:

| Flag | Purpose | Example |
|------|---------|---------|
| `--skip` | Shortcut for `--dangerously-skip-permissions` | Quick automation |
| `--bypass` | Shortcut for `--permission-mode bypassPermissions` | Quick automation |
| `--permission-mode bypassPermissions` | Skip all permission prompts (long form) | Automation scripts |
| `--dangerously-skip-permissions` | Skip all permission prompts (long form) | Automation scripts |
| `--allowedTools` | Allow only specific tools | Restricted automation |
| `--max-turns N` | Limit agentic loop iterations | Prevent runaway scripts |
| `--output-format stream-json` | Structured JSON output | Pipeline integration |
| `--live` | Stream text in real-time | Long-running scripts |

Combine with `ai` flags freely:
```markdown
#!/usr/bin/env -S ai --aws --opus --skip --max-turns 10
```

## Flag Precedence

`ai` resolves flags from multiple sources. Higher sources override lower ones:

| Priority | Source | Example |
|----------|--------|---------|
| 1 (highest) | CLI flags | `ai --aws --opus script.md` |
| 2 | Shebang flags | `#!/usr/bin/env -S ai --ollama --low` |
| 3 | Saved defaults | `ai --aws --opus --set-default` |
| 4 (lowest) | Auto-detection | Current Claude subscription |

**Example:** A script has `#!/usr/bin/env -S ai --ollama --low`. Running `ai script.md` uses Ollama with the low-tier local model (shebang). Running `ai --aws script.md` uses AWS (CLI overrides shebang). If you also have `--set-default vertex`, the shebang still wins over the default.

## Permission Flag Precedence

`ai` resolves permission shortcuts before passing flags to Claude Code. When conflicts are detected, explicit flags take precedence:

- `--permission-mode <value>` and `--dangerously-skip-permissions` are **explicit** — they always win
- `--skip` and `--bypass` are **shortcuts** — ignored with a warning if an explicit flag is also present
- **CLI flags override shebang flags** — if you run `ai --permission-mode plan script.md` and the script has `--skip` in its shebang, plan mode is used

| You use | What happens |
|---------|-------------|
| `ai --skip` | Same as `--dangerously-skip-permissions` (nuclear — overrides all permission modes) |
| `ai --bypass` | Same as `--permission-mode bypassPermissions` (mode-based — composable) |
| `ai --skip --permission-mode plan` | Plan mode used, `--skip` ignored (warning shown) |
| `ai --bypass --permission-mode plan` | Plan mode used, `--bypass` ignored (warning shown) |
| `ai --permission-mode plan script.md` (script has `--skip`) | Plan mode used, shebang `--skip` ignored |

### Why two shortcuts?

`--skip` and `--bypass` differ in how Claude Code processes them internally:

- **`--skip`** expands to `--dangerously-skip-permissions` — this is a standalone flag that completely bypasses all permission checks. In Claude Code, it **overrides** any `--permission-mode` setting ([known issue](https://github.com/anthropics/claude-code/issues/17544)). Use for simple, quick automation.
- **`--bypass`** expands to `--permission-mode bypassPermissions` — this sets the permission mode through the standard mode system. It's composable with other Claude Code settings and respects the mode framework. Use when working with advanced permission configurations.

For most automation scripts, either works. When in doubt, use `--bypass`.

## Security

**`--skip`, `--bypass`, `--permission-mode bypassPermissions`, and `--dangerously-skip-permissions` all give the AI full access to your system.** Use them carefully:

- Only run trusted scripts in trusted directories
- Prefer `--allowedTools` for granular control when full access isn't needed
- In CI/CD, run inside containers or sandboxed environments
- Never pipe untrusted remote scripts with bypass permissions:
  ```bash
  # DANGEROUS — don't do this
  curl https://untrusted-site.com/script.md | ai --skip
  ```

## Quick Reference

| I want to... | Shebang |
|--------------|---------|
| Analyze code (read-only) | `#!/usr/bin/env ai` |
| Use a specific provider | `#!/usr/bin/env -S ai --aws` |
| Run commands and write files | `#!/usr/bin/env -S ai --skip` |
| Restrict to specific tools | `#!/usr/bin/env -S ai --allowedTools 'Bash(npm test)' 'Read'` |
| Full automation with provider | `#!/usr/bin/env -S ai --aws --opus --skip` |
