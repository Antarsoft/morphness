---
id: 2026-10-16-agent-tool-limits
title: Researcher and legal writer get real tool limits
kind: fix
release: 2026-10-16
applies_to: { modules: [] }
files:
  - .claude/agents/researcher.md
  - .claude/agents/researcher-high.md
  - .claude/agents/legal-writer.md
  - project/HARNESS_AGENTS.md
  - CLAUDE.md
removed: []
---

## What changed

- `researcher.md` and `researcher-high.md` add `disallowedTools: Write, NotebookEdit` to their
  frontmatter. The researcher can still read, search, run read-only shell commands, use the web and
  read-only MCPs, and Edit the research file the Technical Lead created. It can no longer create files.
- `legal-writer.md` adds `tools: Read, Grep, Glob, Edit, Write`. The legal writer only reads code and
  docs and writes `Legal/legal-copy.md`, so it no longer gets the shell, web or MCP tools.
- `project/HARNESS_AGENTS.md` § Agents gains a **Tool limits** paragraph, and `CLAUDE.md` says the
  agent files set tool limits as well as model and effort.
- Full-stack and QA are unchanged: QA needs the shell and scratch edits for its checks.

## Why

The researcher and the legal writer were "read-only" only because their instructions said so; with
no `tools` or `disallowedTools` in their frontmatter they inherited every tool, shell and MCP writes
included. Claude Code can't limit Edit to one path or Bash to read-only commands, so which file each
role may edit stays a rule in its role body; the frontmatter removes what they never need.

## How to apply

1. Add the `disallowedTools` line under `effort:` in every `.claude/agents/researcher*.md` file, and
   the `tools` line under `effort:` in `.claude/agents/legal-writer.md` (skip it when the legal module
   is off). Include any trial variants of these roles.
2. If the project's `project/agents/legal-writer.md` asks the legal writer to run a command, fetch a
   page or use an MCP, add that tool to its `tools` list instead (for example `Bash` or `WebFetch`).
3. Add the **Tool limits** paragraph to `project/HARNESS_AGENTS.md` § Agents, and update the
   `CLAUDE.md` subagent line.

## Skip if

The project has already set its own `tools` or `disallowedTools` on these agents.
