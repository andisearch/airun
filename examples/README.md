# Examples

Executable markdown scripts showing key AI Runner features. Run from any repo.

## Scripts

| File | Key Flags | What It Shows |
|------|-----------|---------------|
| `hello.md` | *(none)* | Minimal shebang — just `#!/usr/bin/env ai` |
| `analyze-code.md` | *(none)* | Read-only analysis — no permission flags needed |
| `run-tests.md` | `--skip` | Automation — `--skip` allows running commands and writing files |
| `live-report.md` | `--skip --live` | Live streaming — see output in real-time as it's generated |
| `analyze-stdin.md` | *(none)* | Stdin piping — accepts data via `cat data.json \| ./analyze-stdin.md` |

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

## Key Concepts

- **No flags** = read-only (can analyze code but won't modify anything)
- **`--skip`** = full automation (can run commands, write files, use tools)
- **`--live`** = stream text as it's generated. Streams at turn granularity — your prompt should tell Claude to narrate progress (e.g., "print your findings as you go") so there's text to stream between tool calls. When redirecting to a file (`> report.md`), narration streams to stderr while clean content goes to the file.
- **Stdin piping** = pipe data in with `cat file | ./script.md`
- **CLI overrides shebang** = `ai --aws script.md` overrides the script's shebang provider
- **Shebang overrides defaults** = shebang flags beat `--set-default` preferences

See [docs/SCRIPTING.md](../docs/SCRIPTING.md) for the full guide.
