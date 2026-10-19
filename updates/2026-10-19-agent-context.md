---
id: 2026-10-19-agent-context
title: Subagents skip the project instructions, and the Technical Lead rule moves out of the rules folder
kind: fix
release: 2026-10-19.2
applies_to: { modules: [] }
files:
  - .claude/agents/fullstack-engineer-medium.md
  - .claude/agents/fullstack-engineer-xhigh.md
  - .claude/agents/fullstack-engineer.md
  - .claude/agents/legal-writer.md
  - .claude/agents/qa-engineer-medium.md
  - .claude/agents/qa-engineer.md
  - .claude/agents/researcher-high.md
  - .claude/agents/researcher.md
  - .claude/rules/harness.md
  - AGENTS.md
  - CLAUDE.md
  - harness/HANDOFFS.md
  - harness/MODES.md
  - harness/MORPHING.md
  - harness/PLAN_CHECKLIST.md
  - harness/README.md
  - harness/SETUP.md
  - harness/TECHNICAL_LEAD.md
  - harness/agents/researcher.md
  - harness/modules/claude-projects/README.md
  - harness/modules/security/README.md
  - harness/templates/research.md
  - project/HARNESS_AGENTS.md
  - project/PROCESS.md
  - scripts/prune-counter.sh
removed:
  - .claude/rules/technical-lead.md
moved:
  - .claude/rules/technical-lead.md -> harness/TECHNICAL_LEAD.md
---

## What changed

- Every `.claude/agents/*.md` file sets `omitClaudeMd: true`, so a subagent starts without CLAUDE.md
  and AGENTS.md and reads only its role body (`harness/agents/<role>.md` and `project/agents/<role>.md`).
  Claude Code v2.1.271 or later honours the field; older versions ignore it.
- The Technical Lead rule moves from `.claude/rules/technical-lead.md` to `harness/TECHNICAL_LEAD.md`
  and `CLAUDE.md` imports it with `@harness/TECHNICAL_LEAD.md`. Only the main chat loads it now. The
  text is unchanged except for its relative links. Links to the old path in `AGENTS.md`,
  `project/PROCESS.md`, the other kit files and `scripts/prune-counter.sh` point at the new file.
- The researcher agents also deny the shell (`disallowedTools: Bash, Write, NotebookEdit`). The
  Technical Lead records the commit in the research file's § Context, and the researcher says what
  needs a run under § Open questions.
- `.claude/rules/harness.md` gains a **Long output** line: log to a file, print the exit code and the
  last lines.

## Why

The Technical Lead rule says "no app code, non-negotiable" and was loaded into every subagent, so
Full-stack and QA started with 12 KB of instructions that contradict their own role, about 7k tokens
per run, paid again by every fresh subagent context. A rule file with `paths:` would not work here,
because the main chat has to load it always. A subagent that can't run a shell can't be talked into
running one by a web page or an issue it reads.

## How to apply

1. Add `omitClaudeMd: true` under `effort:` (or the last frontmatter line) in every
   `.claude/agents/*.md`, and `Bash` to the researchers' `disallowedTools`. Keep any tool limits the
   project added.
2. Move `.claude/rules/technical-lead.md` to `harness/TECHNICAL_LEAD.md` (keep the project's own
   edits), fix its relative links (`../../harness/X` becomes `./X`, `../../project/X` becomes
   `../project/X`), add `@harness/TECHNICAL_LEAD.md` under `@AGENTS.md` in `CLAUDE.md`, and replace
   other links to the old path.
3. Add the research commit line to `harness/templates/research.md` § Context and the researcher
   changes in `harness/agents/researcher.md`.

## Skip if

The project wants the Technical Lead rule in every subagent, or runs a Claude Code older than
v2.1.271 (the move still works there; only the subagent skip doesn't).
