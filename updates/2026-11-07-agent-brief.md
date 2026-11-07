---
id: 2026-11-07-agent-brief
title: Full-stack and QA read one compiled agent brief instead of five to seven project files
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - scripts/handoff.sh
  - harness/HANDOFFS.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - .claude/agents/fullstack-engineer.md
  - .claude/agents/fullstack-engineer-medium.md
  - .claude/agents/fullstack-engineer-xhigh.md
  - .claude/agents/qa-engineer.md
  - .claude/agents/qa-engineer-medium.md
removed: []
reviewed: "No guard rule, settings or config value changes. handoff.sh now also writes one file inside the git folder (morphness/briefs/), next to the records checks.sh keeps there; it still writes nothing in the work tree."
---

## What changed

- **`scripts/handoff.sh`**: for `fullstack`, `fullstack-bug`, `qa` and `qa-repro` it compiles the **agent brief** and names it on a new `Agent brief:` line of the prompt. The brief holds, in this order: the project addendum (`project/agents/fullstack-engineer.md` or `project/agents/qa-engineer.md`; its § Read before you start stays, with a note that the files it names are in the brief, so a condition or another doc it names still reaches the agent), `.claude/rules/testing.md`, each path rule on the prompt's `Path rules:` line, and the project files the role body and the addendum name (Full-stack: `project/TESTING.md`, `project/PROJECT.md` and the `project/STACK.md` sections the addendum lists; QA: the files its addendum lists, by default `project/CONTROLS.md` and `project/STACK.md` § Local stack (QA)). HTML comments (morph-init's placeholders; not inside code), headings left empty without them and the rule files' `paths:` headers are taken out, and relative links are written as repo paths. It is written to `<git folder>/morphness/briefs/<slug>-<version>-<fullstack|qa>.md` and rebuilt at every hand-off, so a retro edit, or a fact the Full-stack engineer added to `PROJECT.md` in the last feature, is in the next brief. A section the addendum names that the file doesn't have is reported on a `Missing:` line in the brief and on the script's last lines. In a git worktree the brief goes to the main checkout's git folder, like the checks' records.
- **`harness/HANDOFFS.md`**: the Full-stack, QA and bug-reproduction blocks get the `Agent brief (drop this line when there is none): …` line, and the paragraph under § Subagent prompt blocks describes the brief.
- **`harness/agents/fullstack-engineer.md`** § Before you start step 2 and **`harness/agents/qa-engineer.md`** § Before you start step 1: read the brief the prompt names instead of the files it holds; without a brief, read them as before.
- **`.claude/agents/fullstack-engineer*.md`, `.claude/agents/qa-engineer*.md`**: "then the agent brief your prompt names, which opens with `project/agents/<role>.md`" (without a brief, that file).

## Why

In the benchmark's full-mode features each Full-stack and QA run spent four to seven tool calls reading the addendum, the rule files and the project docs, one file per call, and each call re-reads the whole context. One compiled file is one call, and dropping the comments and empty template headings makes it smaller than the files it replaces.

## How to apply

1. Copy `scripts/handoff.sh` from the kit.
2. Add the `Agent brief (drop this line when there is none): …` line to the Full-stack, QA engineer and QA bug-reproduction blocks in `harness/HANDOFFS.md` § Subagent prompt blocks, and the paragraph's last sentence. If you customised the blocks, keep the line's prefix: the script fills it.
3. Take the kit's step 2 of `harness/agents/fullstack-engineer.md` § Before you start, step 1 of `harness/agents/qa-engineer.md` § Before you start, and each file's first paragraph.
4. Take the kit's sentence in each `.claude/agents/fullstack-engineer*.md` and `.claude/agents/qa-engineer*.md` file (keep your `model:` and `effort:` lines).
5. Keep `project/agents/fullstack-engineer.md` § Read before you start in the kit's form (`In [project/STACK.md](../STACK.md) read only § A, § B and § C`): the script takes each `project/*.md` file named on a line, with the § names that follow it on that line (a file with none goes in whole), and leaves out a file named after skip, not, never, except or without.

## Skip if

Your Technical Lead runs no subagents (light and small mode only), or doesn't use `scripts/handoff.sh`.
