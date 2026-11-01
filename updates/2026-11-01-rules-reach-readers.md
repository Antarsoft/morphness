---
id: 2026-11-01-rules-reach-readers
title: Rules reach the agent they are for, and the researcher can't edit files
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/agents/fullstack-engineer-medium.md
  - .claude/agents/fullstack-engineer-xhigh.md
  - .claude/agents/fullstack-engineer.md
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
  - harness/SETUP.md
  - harness/STRATEGY.md
  - harness/TECHNICAL_LEAD.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - harness/agents/researcher.md
  - harness/templates/research.md
  - project/HARNESS_AGENTS.md
removed: []
---

## What changed

- Full-stack and QA now read `.claude/rules/testing.md` in § Before you start. Subagents run with `omitClaudeMd`, so Claude Code never loaded it for them, though it is the file every lesson about tests lands in.
- `.claude/rules/harness.md` loses its Full-stack, QA and researcher bullets (those agents never load it; their role bodies already hold the same rules) and says where a rule for a subagent goes. `CLAUDE.md`, `AGENTS.md` § Tool setup and `harness/MORPHING.md` § Where a lesson lands say the rule files load in the main chat only.
- Full-stack no longer reads all of `AGENTS.md`, which is the Technical Lead's and told it again to "never edit application code". `harness/agents/fullstack-engineer.md` § Project rules has the short version of what applies to it: the guard's denies and asks, and what to do on a deny.
- The researcher variants get `disallowedTools: Bash, Edit, MultiEdit, Write, NotebookEdit` (Edit was allowed before, so "read-only" was only an instruction). The researcher now replies with the sections between the research file's two lines, and the Technical Lead pastes them in unchanged (`harness/MODES.md` § Research mode, `harness/HANDOFFS.md`, the research template).
- The `.claude/agents/*.md` files say to read the role body in full instead of listing sections: the Read tool returns the whole file anyway, and the list left out § No outside answers.

## Why

An audit run asked a QA subagent about a phrase from `.claude/rules/testing.md`: it answered that it had no project rules at all. Retro lessons about tests were landing where the test writer never looks, while the main chat paid for text addressed to other agents on every turn.

## How to apply

1. Merge the kit files as usual. In each `.claude/agents/fullstack-engineer*.md` and `qa-engineer*.md`, replace the parenthesis after `harness/agents/<role>.md` (the "its § Before you start, …" list) with "in full". In each `.claude/agents/researcher*.md`, set `disallowedTools: Bash, Edit, MultiEdit, Write, NotebookEdit` and take the description sentence from the kit ("It has no shell and no edit tools: …").
2. In `.claude/rules/harness.md`, delete the Full-stack, QA and Researcher subagent bullets and take the kit's Subagents bullet. If a retro added a rule to one of those bullets, move it to `harness/agents/<role>.md` or `project/agents/<role>.md` first, with its `(from …)` tag. Do the same for any rule a subagent must follow in a rule file your project added to `.claude/rules/`: only the main chat loads those.
3. If your `AGENTS.md` has a rule a builder must follow (a project convention, a path it must not touch), Full-stack no longer reads it: copy it to `project/agents/fullstack-engineer.md`.
4. In `CLAUDE.md` and `AGENTS.md` § Tool setup, take the kit's "loaded in the main chat" wording, and in `AGENTS.md` § Permissions for this project the first sentence's "listed in full only here".
5. In `project/HARNESS_AGENTS.md`, take the kit's **Tool limits** wording for the researcher (`disallowedTools` with `Edit`, and the reply that the Technical Lead writes in).
