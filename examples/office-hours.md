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
