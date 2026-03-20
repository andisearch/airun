# Examples

Executable markdown scripts showing key AI Runner features. Run from any repo.

## Scripts

| File | Key Flags | What It Shows |
|------|-----------|---------------|
| `hello.md` | `--haiku` | Minimal shebang — cheap model for a trivial task |
| `analyze-code.md` | `--sonnet --skip` | Code analysis — Sonnet reads files to summarize architecture |
| `run-tests.md` | `--sonnet --skip` | Automation — `--skip` allows running commands and reading output |
| `check-project-readme.md` | `--sonnet --skip --live` | Live audit — streams findings in real-time as it reads files |
| `live-report.md` | `--sonnet --skip --live` | Live streaming — explores repo and streams a report |
| `analyze-stdin.md` | `--haiku` | Stdin piping — cheap model for `cat data.json \| ./analyze-stdin.md` |
| `summarize-topic.md` | `--haiku` + vars | Variables — front-matter defaults with `--varname` CLI overrides |

## Running

```bash
# Run directly (uses shebang flags)
./hello.md

# Run with ai command (shebang flags like --skip, --live are honored)
ai live-report.md

# Pipe a script (shebang flags still honored)
cat live-report.md | ai

# Override provider or model (CLI flags override shebang)
ai --aws --opus run-tests.md

# Pipe data into a script
cat package.json | ./analyze-stdin.md

# Redirect output to file (status messages appear on stderr)
ai live-report.md > report.txt
```

## Chaining Scripts

Chain scripts together in pipelines — each script runs independently with process isolation:

```bash
# Parse → generate → review pipeline
./parse-input.md | ./generate-code.md | ./review-output.md > final.txt

# Feed data through multiple analysis steps
cat data.json | ./extract.md | ./summarize.md > summary.txt
```

See [docs/SCRIPTING.md](../docs/SCRIPTING.md) for composable patterns and the dispatcher pattern.

## Variables

`summarize-topic.md` declares variables with defaults. Override any combination from the CLI:

```bash
# Use all defaults (topic=machine learning, style=casual, length=short)
./summarize-topic.md

# Override everything — variable flags mix freely with AI Runner flags
./summarize-topic.md --live --length "100 words" --topic "the fall of rome" --style "peter griffin"

# Override provider and model too
ai --aws --opus summarize-topic.md --topic "quantum computing" --style formal
```

Variable overrides (`--topic`, `--style`, `--length`) are consumed by AI Runner. AI Runner flags (`--live`, `--aws`, `--opus`) are handled normally. Unrecognized flags pass through to Claude Code.

## Key Concepts

- **`--haiku`** = cheap/fast model for simple tasks (text generation, data analysis)
- **`--sonnet`** = balanced model for code analysis, test running, report generation
- **`--skip`** = full automation (can run commands, write files, use tools)
- **`--live`** = stream text as it's generated — prompt should say "print your findings as you go" for intermediate output
- **Stdin piping** = pipe data in with `cat file | ./script.md`
- **Variables** = declare `vars:` in YAML front-matter, override with `--varname "value"` or `--varname` (boolean) from CLI
- **CLI overrides shebang** = `ai --aws script.md` overrides the script's shebang provider
- **Shebang overrides defaults** = shebang flags beat `--set-default` preferences

See [docs/SCRIPTING.md](../docs/SCRIPTING.md) for the full guide.
