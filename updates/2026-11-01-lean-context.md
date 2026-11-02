---
id: 2026-11-01-lean-context
title: Every session loads an 8 KB core; other rules load by path
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/rules/auth.md
  - .claude/rules/data.md
  - .claude/rules/deploy.md
  - .claude/rules/harness.md
  - .claude/rules/testing.md
  - AGENTS.md
  - CLAUDE.md
  - harness.config.yml
  - harness/GUARD.md
  - harness/HANDOFFS.md
  - harness/MODES.md
  - harness/MORPHING.md
  - harness/README.md
  - harness/RELEASE.md
  - harness/SETUP.md
  - harness/SKILLS_AND_MCPS.md
  - harness/TECHNICAL_LEAD.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - harness/modules/data-access/README.md
  - harness/modules/legal/README.md
  - harness/modules/roadmap/README.md
  - harness/modules/security/README.md
  - scripts/guard.sh
  - scripts/prune-counter.sh
removed: []
reviewed: "It moves the guard's documentation from AGENTS.md to harness/GUARD.md word for word and repoints links to it; it changes no guard rule, settings, permission or secret handling. The only scripts/guard.sh change appends the GUARD.md pointer to deny messages. The harness.config.yml change adds loop.owner_rules_kb and lowers loop.rule_budget_kb. Secrets are named only in the unchanged golden rule (never read or write .env files)."
---

## What changed

- Claude Code now loads about 8 KB of kit rules into every session instead of about 35 KB: `CLAUDE.md` and `AGENTS.md`, nothing else.
- `CLAUDE.md` no longer imports `harness/TECHNICAL_LEAD.md`. `AGENTS.md` § Golden rules tells the Technical Lead to read it in full before writing a full or bug mode plan, and keeps the rules every session needs in a few lines: pick the mode with the risk check, who merges, no writes to shared remote environments, no secret files, long output to a log.
- The guard's full list (what it denies, asks and does not see, and its switches) moves from `AGENTS.md` § Permissions for this project to the new `harness/GUARD.md`. Every guard deny now ends with "What the guard checks: harness/GUARD.md." The harness and project tables in `AGENTS.md` become a short § Where things are.
- Every `.claude/rules/` file now has `paths:` frontmatter, so Claude Code loads it only when a file it matches is read or edited:
  - `harness.md` for `_harness/**` (plans and records);
  - `testing.md` for test files;
  - new `data.md` for migrations, SQL and schema files;
  - new `auth.md` for sign-in, session, middleware and access-rule files;
  - new `deploy.md` for CI definitions and deploy config.
- Subagents load none of `.claude/rules/`. The Full-stack and QA prompt blocks in `harness/HANDOFFS.md` gain a `Path rules:` line naming the rule files the plan's paths need, and both role bodies read them.
- `scripts/prune-counter.sh`:
  - its `Rules:` line adds a token estimate and the size of the agent and skill descriptions Claude Code also loads;
  - the new `loop.owner_rules_kb` gives the owner's own always-loaded text, kept at install, its own allowance on top of `loop.rule_budget_kb`;
  - the template's `loop.rule_budget_kb` drops from 36 to 16.

## Why

Every turn re-reads the always-loaded rules. About 35 KB of them was paid on every step of every task, a docs fix included, while most of it applied only to full mode, the guard, or one kind of file. An install over a long existing `CLAUDE.md` was due a prune on day one.

## How to apply

This note builds on `2026-11-01-rules-reach-readers`, `2026-11-01-risk-check` and `2026-11-01-one-agent`: apply them first. Where their steps edit `AGENTS.md` § Tool setup or § Permissions for this project, `CLAUDE.md` or `.claude/rules/harness.md`, this note's text replaces theirs.

0. Before anything moves, look for lines your retros added to `.claude/rules/harness.md`, `.claude/rules/testing.md` and `harness/TECHNICAL_LEAD.md`. After this update the first two load only for matching files and the third only for full and bug mode plans. Move any such line that every session needs to `AGENTS.md` § Golden rules, one line each.
1. Add `harness/GUARD.md`. Move anything your project added to `AGENTS.md` § Permissions for this project into it, then delete that section and § Tool setup from `AGENTS.md`. Merge the new `AGENTS.md` § Golden rules and § Where things are. Keep your own golden rules, one line each.
2. Merge `CLAUDE.md`: drop the `@harness/TECHNICAL_LEAD.md` line and take the new § Claude Code notes. Keep your own notes below them.
3. Add `paths:` frontmatter to `.claude/rules/harness.md` and `.claude/rules/testing.md`, and add `data.md`, `auth.md` and `deploy.md`. Set their `paths:` to this repo's own files: the § Risk paths rows in `project/CONTROLS.md` for data and sign-in, and the files `harness.config.yml` → `environments` deploys through for deploy. A rule file your project added gets `paths:` too when it applies to one kind of file; leave it without `paths:` only when every session needs it.
4. Merge `harness/HANDOFFS.md` (the `Path rules:` lines), the two role bodies, `harness/TECHNICAL_LEAD.md` (read `testing.md` before writing acceptance criteria), `harness/MODES.md`, `harness/MORPHING.md`, `harness/README.md`, `harness/SETUP.md`, `scripts/guard.sh` and `scripts/prune-counter.sh`. Repoint the links in `harness/RELEASE.md`, `harness/SKILLS_AND_MCPS.md`, `harness/agents/fullstack-engineer.md` and `harness.config.yml`, and in any project file that names `AGENTS.md` § Permissions for this project, to `harness/GUARD.md`.
5. In `harness.config.yml` → `loop`, add `owner_rules_kb`, set to the size in KB (rounded up) of your own text that every session loads: your lines in `CLAUDE.md` and `AGENTS.md`, and your rule files without `paths:`. Then lower `rule_budget_kb` to 16, or keep your value.
6. Run `bash scripts/prune-counter.sh` and check the `Rules:` line.

## Skip if

Never: an update with the rule files still always loaded keeps paying for them on every turn. Step 5's budget change is optional.
