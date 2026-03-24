#!/usr/bin/env -S ai --opus --skip --live
---
vars:
  repo: "."
  stage: ""
  mode: ""
  focus: ""
---

# Office Hours: Autonomous Project Evaluation

Run gstack's /office-hours methodology as a standalone executable program against any project.

This script demonstrates how airun extends gstack: gstack SKILL.md files define what to think about (they run inside a coding agent's REPL as slash commands). This airun script makes that methodology into an executable program — a file on disk you can run from any terminal, pipe through Unix commands, schedule with cron, and execute on any coding agent.

## Protected Invariants

These structural rules are load-bearing for correctness. The self-improvement loop must NEVER modify them, even indirectly. Any observation that would change these invariants must be classified as "forbidden."

1. **gstack is the methodology source**: The script must always read and follow `~/.claude/skills/gstack/office-hours/SKILL.md` as the primary source of truth. It must never hard-code gstack's questions, rules, or postures inline. The value of this script is portable execution of gstack's methodology, not a reimplementation.

2. **Setup before evaluation**: The sequence must be: resolve repo → install/update gstack → read SKILL.md → gather context → select mode → run methodology → produce report. Reordering would cause the evaluation to run without methodology or context.

3. **Mode delegation to gstack**: Startup Mode must follow gstack Phase 2A. Builder Mode must follow gstack Phase 2B. The script must not invent its own questions or evaluation frameworks. Mode-specific behavior comes from the SKILL.md, not from this script.

4. **Repo resolution contract**: The `REPO_INPUT` bash block must handle both local paths and `https://` URLs. Remote repos clone to a temp directory. All subsequent operations use the resolved REPO_PATH. Changing this would break either local or remote repo support.

5. **Report structure is output contract**: The Startup Mode report (Summary → Findings → Red Flags → Strongest Signal → Assignment) and Builder Mode report (Summary → Findings → Delight Factor → Untapped Potential → Build Steps) are the script's output interface. Downstream consumers may parse these sections. Do not rename, reorder, or remove them.

## Setup

### Resolve repo target

The repo input is: {{repo}}

Determine whether the input is a local path or a remote URL:

```bash
REPO_INPUT="{{repo}}"
if [[ "$REPO_INPUT" =~ ^https?:// ]]; then
    CLONE_DIR=$(mktemp -d)
    echo "==> Cloning $REPO_INPUT to $CLONE_DIR/repo..."
    git clone --depth 50 "$REPO_INPUT" "$CLONE_DIR/repo" 2>&1
    echo "REPO_PATH=$CLONE_DIR/repo"
    echo "CLONED=true"
else
    REPO_PATH="$(cd "$REPO_INPUT" 2>/dev/null && pwd || echo "$REPO_INPUT")"
    echo "REPO_PATH=$REPO_PATH"
    echo "CLONED=false"
fi
```

Use the resolved REPO_PATH as the project directory for all subsequent operations. cd into it before reading files or running git commands.

### Install or update gstack

```bash
if [ -f ~/.claude/skills/gstack/office-hours/SKILL.md ]; then
    echo "GSTACK_FOUND"
    # Check if update is available using gstack's own update mechanism
    _UPD=$(~/.claude/skills/gstack/bin/gstack-update-check --force 2>/dev/null || true)
    [ -n "$_UPD" ] && echo "$_UPD" || echo "GSTACK_UP_TO_DATE"
else
    echo "GSTACK_MISSING"
fi
```

If GSTACK_MISSING, install gstack:

```bash
git clone https://github.com/garrytan/gstack.git ~/.claude/skills/gstack 2>&1
```

If output shows `UPGRADE_AVAILABLE <old> <new>`, update gstack before proceeding:

```bash
cd ~/.claude/skills/gstack && git pull origin main 2>&1 && ./setup 2>&1
```

Print the gstack version being used:

```bash
cat ~/.claude/skills/gstack/VERSION 2>/dev/null
```

Now read `~/.claude/skills/gstack/office-hours/SKILL.md` in full. This is the primary source of truth for the entire evaluation. It contains:
- Phase 2A: Startup Mode (six forcing questions, anti-sycophancy rules, pushback patterns, response posture)
- Phase 2B: Builder Mode (generative questions, operating principles, enthusiastic collaborator posture)
- Phase 3: Premise Challenge
- Phase 4: Alternatives Generation
- All operating principles, red flags, and smart routing rules

**You must follow the gstack SKILL.md methodology as written.** Do not improvise your own questions or rules. The value of this script is that it runs gstack's actual methodology portably — not a reimplementation.

Also read `~/.claude/skills/gstack/ETHOS.md` for the Boil the Lake and Search Before Building principles that inform the evaluation posture.

## Context Gathering

cd into the resolved REPO_PATH, then read the project:

1. Read README.md, CLAUDE.md, package.json or equivalent manifests
2. Run `git log --oneline -20` to understand recent activity
3. Use Glob and Grep to map the codebase structure
4. If a website or deployment URL is mentioned, note it

Print a brief summary of what you understand about the project before proceeding.

## Mode Selection

The mode is: {{mode}}

If mode is empty, auto-detect by analyzing what you found:

**Startup signals** → use gstack Phase 2A (Startup Mode):
- Pricing, billing, subscriptions, revenue, investor docs, user analytics, business model, GTM strategy

**Builder signals** → use gstack Phase 2B (Builder Mode):
- MIT/open-source license with no commercial tier, side project / hackathon / personal tool framing, no monetization, community-driven

State which mode you selected and why. If ambiguous, default to Startup Mode.

## Stage Detection (Startup Mode only)

The product stage is: {{stage}}

If stage is empty, infer from evidence:
- **pre-product**: No users, idea stage, scaffolding
- **has-users**: Analytics, deployed URL, user feedback, bug reports
- **paying-customers**: Revenue, pricing code, billing, subscription logic

## Run the gstack /office-hours Methodology

Now execute the evaluation following the gstack SKILL.md you loaded above.

**For Startup Mode:** Follow Phase 2A exactly as written in the SKILL.md. Use the smart routing by stage to select which of the six forcing questions to apply. For each question, use the push patterns and red flags defined in the SKILL.md. Follow the anti-sycophancy rules and response posture. Take a position on every finding.

**For Builder Mode:** Follow Phase 2B exactly as written in the SKILL.md. Use the generative questions with the enthusiastic collaborator posture. End with concrete build steps, not business validation.

**Adaptation for autonomous mode:** The gstack SKILL.md is designed for interactive sessions (it uses AskUserQuestion to ask founders directly). Since this script runs autonomously against a codebase, answer the questions yourself based on evidence found in the repo — README, source code, git history, docs, analytics config, and any other artifacts. Where the SKILL.md says "push until you hear [specific answer]," assess whether the evidence in the codebase would satisfy that bar.

{{focus}}

## Evaluation Report

After completing the gstack methodology, produce a structured report.

**For Startup Mode:**

### Summary
One paragraph: what this project is, its current stage, and your overall assessment.

### Findings by Question
For each forcing question evaluated: the evidence found, red flags identified, and evidence strength (STRONG / MODERATE / WEAK).

### Red Flags
Every red flag identified, with specific codebase evidence.

### Strongest Signal
The single strongest piece of evidence, positive or negative.

### Assignment
One concrete action doable this week. Not a strategy — an action.

**For Builder Mode:**

### Summary
One paragraph: what this project is, what makes it interesting, and its momentum.

### Findings by Question
For each generative question: your analysis with specific codebase evidence.

### The Delight Factor
The single most delightful or surprising thing about this project.

### Untapped Potential
The biggest opportunity not yet pursued. Be specific and opinionated.

### Build Steps
Concrete things to build this week to make the project more remarkable. Prioritized by impact.

---

## Self-Improvement

After producing the evaluation report, reflect on the script's own performance. This section runs only when the script is executed with `--focus "self-improve"` or as part of a scheduled automation that includes self-improvement.

### Gather observations
Note any issues encountered during this run:
- Did gstack install/update work correctly?
- Did mode auto-detection choose the right mode?
- Did the SKILL.md methodology produce a useful evaluation?
- Were there gaps in context gathering (files that should have been read but weren't)?
- Did the report structure capture the evaluation's findings well?

### Classify improvements
For each observation, classify as:
- **safe**: Improves clarity, adds a missing context-gathering step, fixes a typo. Does not change structure or methodology delegation.
- **needs-review**: Changes to mode detection signals, report section content, or gstack integration. Log for human review.
- **forbidden**: Violates a Protected Invariant. Log with reason: "violates protected invariant #N." Never apply.

### Invariant check (required before any change)
Before applying any change to this script, verify it does not violate the Protected Invariants section at the top. Specifically:
- Any change that hard-codes gstack questions or rules inline → **forbidden** (invariant #1)
- Any change that reorders setup/evaluation/report phases → **forbidden** (invariant #2)
- Any change that adds custom evaluation logic outside gstack's methodology → **forbidden** (invariant #3)
- Any change that breaks local path or remote URL handling → **forbidden** (invariant #4)
- Any change that renames or removes report sections → **forbidden** (invariant #5)

### Apply safe changes only
- Maximum 3 improvements per run
- After each edit, re-read the modified section and verify no invariant was violated
- Log all changes (applied and forbidden) to stderr for transparency
