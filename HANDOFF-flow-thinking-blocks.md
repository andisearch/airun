# Handoff: flow `/v1/messages` rejects thinking-only content blocks in conversation history

**From:** airun session, 2026-06-14
**To:** flow backend agent
**Severity:** blocker for any interactive (multi-turn) Claude Code session against a non-Anthropic model that emits thinking blocks

## The bug

When a model (e.g. `gemma-4-26B-A4B-it-UD-Q4_K_M`, but also `Qwen3.6-27B`, and likely any other thinking-tier model) responds to a first turn with a `content` array that contains a `thinking` block but **no** `text` block, flow returns HTTP 200 on that turn. But on the second turn — when the conversation history includes that prior assistant message — flow returns:

```
HTTP 400
{"type":"error","error":{"type":"invalid_request_error","message":"Content block type `thinking` is not supported in this Anthropic MVP."},"request_id":"req_..."}
```

The "this Anthropic MVP" wording is flow's own validation error, not a forwarded message from `api.anthropic.com`. Flow is rejecting the request before it reaches the upstream llama.cpp backend.

## Reproduction (verified working on 2026-06-14)

flow server: `http://localhost:3377`, `python -m flow_llm.main` running from `/Users/jameyaita/james-llm/server`.

```bash
# Step 1: load the model (any thinking-tier GGUF works; tested with
# gemma-4-26B-A4B-it-UD-Q4_K_M and Qwen3.6-27B-UD-Q4_K_XL)
curl -sS -X POST "http://localhost:3377/api/models/gemma-4-26B-A4B-it-UD-Q4_K_M/load" \
  -H 'content-type: application/json' -d '{}'

# Step 2: send a follow-up request whose messages[] includes a prior
# assistant turn with a thinking-only content block
curl -sS -X POST 'http://localhost:3377/v1/messages?beta=true' \
  -H 'content-type: application/json' \
  -H 'anthropic-version: 2023-06-01' \
  -d '{
    "model":"gemma-4-26B-A4B-it-UD-Q4_K_M",
    "max_tokens":200,
    "messages":[
      {"role":"user","content":"hi"},
      {"role":"assistant","content":[{"type":"thinking","thinking":"The user said hi."}]},
      {"role":"user","content":"are you still there?"}
    ]
  }' -w '\nHTTP %{http_code}\n'
```

Result:
```
{"type":"error","error":{"type":"invalid_request_error","message":"Content block type `thinking` is not supported in this Anthropic MVP."},"request_id":"req_..."}
HTTP 400
```

The same request **succeeds** (HTTP 200) if the assistant turn in the history has only `text` blocks, or if the `thinking` block is omitted entirely. It also **succeeds** if the request is the first turn (no prior assistant message at all).

## Why this matters for Claude Code

Claude Code 2.1+ stores prior assistant turns in conversation history verbatim. If a non-Anthropic model returns a thinking-only response on turn 1, CC will send that exact turn back as part of turn 2's `messages[]`. flow then 400s, and CC displays the error to the user.

This is what produces the user-visible error:
```
API Error: 400 Content block type `thinking` is not supported in this Anthropic MVP.
```

First-turn requests work fine, which masks the problem in single-shot CLI invocations (`ai --local "do thing"`) and makes it look like the bug appears "after the second message" specifically.

## Likely root cause

flow's request validation in front of the llama.cpp backend (the proxy layer that turns `127.0.0.1:3377` requests into `127.0.0.1:{model_port}/v1` calls) appears to:

1. Accept any Anthropic-shaped request with no `thinking` content in the history → pass through to llama.cpp
2. Reject (with "this Anthropic MVP") any request whose `messages[]` contains a `type:"thinking"` content block

This is the wrong default. The Anthropic API has historically supported thinking blocks in conversation history when the `interleaved-thinking-2025-05-14` beta header is sent, and CC 2.1 sends that header by default (it uses `POST /v1/messages?beta=true` in the access log). The 400 fires even with the `interleaved-thinking` beta header set, so it's not gated on that.

## Suggested fixes (in order of preference)

### Option A — strip thinking blocks at the request boundary (recommended)

In flow's `/v1/messages` request handler, before forwarding to the llama.cpp backend:

1. Walk `messages[]` and for any assistant message, drop content blocks where `type == "thinking"`.
2. If the resulting assistant message has no content blocks left, drop the message entirely (an empty assistant turn is invalid).
3. Forward the cleaned request.

This is what the Anthropic API would do implicitly when the model doesn't support extended thinking. It's lossless in the sense that thinking was internal scratchpad anyway, and the user's `text` blocks (if any) are preserved.

### Option B — synthesize a placeholder text block

Same as A, but instead of dropping thinking-only assistant messages, replace each `type:"thinking"` block with `type:"text"`, `text:""`. This keeps message count stable for clients that are strict about message indexing, at the cost of sending empty text blocks downstream.

### Option C — auto-rewrite responses

In flow's response handler, after llama.cpp returns a thinking-only response, append a synthetic `{"type":"text","text":""}` block. This prevents the round-trip problem at the source but doesn't help with clients that store the raw response and replay it.

**Option A is preferred** because it handles the actual failure mode (replayed history) regardless of how the response was constructed.

## Files / locations to look at in flow

flow source lives in `/Users/jameyaita/james-llm/server/`. Relevant entry points:

- `POST /v1/messages` handler (the Anthropic-Messages-compatible proxy)
- Wherever the request body is validated or normalized before being forwarded to the upstream llama.cpp endpoint (per-model port, e.g. `http://127.0.0.1:8082/v1` for a loaded model)
- Look for any code that walks `messages[].content` and rejects unknown content types

OpenAPI spec at `http://localhost:3377/openapi.json` lists all routes if a more systematic search is needed.

## Workarounds for the user (until flow is fixed)

- Use a model on flow that emits text without thinking (e.g. smaller non-reasoning models). The `gemma-4-E2B-it-Q4_K_M` model on this flow instance was tested and emits text within `max_tokens=200` in 1-2 seconds, but it still emits a `thinking` block alongside the `text` block — so the round-trip 400 will still fire if CC replays the full content array. The only true workaround at the model level is to find a model that doesn't emit `type:"thinking"` content blocks at all.
- For one-off tasks, use `ai --local -p "<prompt>"` (print mode) instead of interactive. The first turn always succeeds; only interactive sessions hit the replay issue.

## Related work in airun (for context, not for flow to act on)

- airun probe fix (repo commit, not yet installed): widened 4xx + Anthropic-envelope 503 detection in `scripts/lib/local-provider-manager.sh::local_provider_probe_messages_from`. Unblocks `ai --local` startup but does not address the round-trip 400.
- airun display-layer fix (already installed): `tools/claude-code.sh` already handles `select(.type == "text" or .type == "thinking")` for streaming display. That's not the problem here — the problem is at the request-construction layer in CC, which airun doesn't control.
