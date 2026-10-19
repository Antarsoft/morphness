---
id: 2026-10-17-guard-hook
title: Guard hook that checks tool calls before they run
kind: rule
release: 2026-10-19
applies_to: { modules: [] }
files:
  - scripts/guard.sh
  - .claude/settings.json
  - harness.config.yml
  - AGENTS.md
  - CLAUDE.md
  - harness/RELEASE.md
  - harness/SKILLS_AND_MCPS.md
removed: []
---

## What changed

A new `PreToolUse` hook, `scripts/guard.sh`, runs before Bash, file and MCP tool calls. It reads a
Bash command the way the shell does (every command in a chain, `$(…)`, `bash -c`, `eval`, `env`,
`git -C <dir>`) and blocks: pushes that would update an environment branch in any form (a bare
`git push` on one, `HEAD`, `--all`, `--mirror`, deletes), force-pushes, reading or writing `.env`
files other than `.env.example`, `.env.sample` and `.env.template`, `gh secret`/`gh variable` writes
and `gh api` writes to secrets, and well-known remote database writes (`supabase db push`,
`prisma migrate deploy`, `wrangler d1 … --remote`, …). `gh api` writes to rulesets, branch protection
and repo settings show a permission prompt. Every MCP tool whose name doesn't start with a read verb
(get, list, search, read, …) shows a permission prompt too, so no connector write runs without the
owner's yes; `guard: { mcp_writes: off }` in `harness.config.yml` turns that part off. The deny and
ask rules in `.claude/settings.json` stay as a second layer.

## Why

Deny rules match command text, so they only catch the common spellings: `git push` while on `main`,
`bash -c 'git push origin main'` or `grep KEY .env.production` slipped through (review fix A7 could
only widen the patterns). Connector writes relied on one `ask` rule per tool name, so a newly
connected MCP had none until someone added it.

## How to apply

1. Copy `scripts/guard.sh` and make it executable (`chmod +x scripts/guard.sh`).
2. Add the template's `hooks.PreToolUse` entry to `.claude/settings.json`. Keep any PreToolUse hook
   the project already has; the guard is one more entry. Check it parses: `jq . .claude/settings.json`.
3. Add the `guard: { mcp_writes: ask }` block (with its comment) to `harness.config.yml` above `loop:`.
   Ask the owner whether connector writes should prompt (`ask`, the default) or rely on the named
   `ask` rules only (`off`).
4. Check: `echo '{"tool_name":"Bash","tool_input":{"command":"git push origin <integration>"}}' | bash scripts/guard.sh`
   exits 2. It needs `python3`; without it the hook lets every call through, so tell the owner.
5. Merge the sentences that mention the guard into `AGENTS.md` (Commit and push, Shared remote
   environments, Settings row, Permissions paragraph), `CLAUDE.md` (Settings), `harness/RELEASE.md`
   § Branch protection (For agents) and `harness/SKILLS_AND_MCPS.md` § Connector actions.
6. If the project's own setup steps copy secrets with a shell command (`cp .env.example .env`), move
   that step to the owner: the guard blocks it.

## Skip if

The project already runs its own PreToolUse guard that covers the same calls.
