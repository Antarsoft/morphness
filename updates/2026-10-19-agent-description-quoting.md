---
id: 2026-10-19-agent-description-quoting
title: Agent descriptions are quoted so strict YAML readers accept them
kind: fix
release: 2026-10-20
applies_to: { modules: [] }
files:
  - .claude/agents/fullstack-engineer.md
  - .claude/agents/fullstack-engineer-medium.md
  - .claude/agents/fullstack-engineer-xhigh.md
  - .claude/agents/legal-writer.md
  - .claude/agents/qa-engineer.md
  - .claude/agents/qa-engineer-medium.md
  - .claude/agents/researcher.md
  - .claude/agents/researcher-high.md
removed: []
---

## What changed

- The `description:` line of every agent file is now a quoted string. It contained text such as `Default (effort high): use when...`, which is not valid YAML unquoted, so a strict reader (a YAML library, a linter, a future Claude Code) could not parse the agent. The wording is unchanged.
- If you edited a description in your copy, keep your text and add the quotes (escape any `"` inside as `\"`).

## Why

An unquoted `word: word` inside a YAML value makes the line invalid. Claude Code reads such files leniently today, but nothing guarantees every tool or later version will.

## How to apply

Wrap the value of `description:` in double quotes in each agent file, escaping any `"` or `\` inside it. Nothing else changes.
