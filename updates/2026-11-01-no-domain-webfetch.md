---
id: 2026-11-01-no-domain-webfetch
title: Settings no longer allow WebFetch on all of api.github.com and raw.githubusercontent.com
kind: fix
release: unreleased
applies_to: { modules: [] }
files:
  - .claude/settings.json
  - scripts/guard.sh
removed: []
reviewed: "removes two allow rules; the guard change is a comment and a message"
---

## What changed

- `.claude/settings.json` drops `WebFetch(domain:api.github.com)` and `WebFetch(domain:raw.githubusercontent.com)` from `permissions.allow`. Those let an agent fetch any page on either host with no prompt, any repository's file or API data included. The update checks keep their reads, which are scoped to the Morphness repository: `gh api --method GET repos/antarsoft/morphness/*` and `curl -fsSL` of the two Morphness URLs. WebFetch now gets Claude Code's own prompt for every page.
- `scripts/guard.sh`: the comment above the WebFetch check and its message say so. The check itself is unchanged: a project that adds a domain allow back still gets an ask for pages outside the Morphness paths.

## Why

The kit's audit found the two domain-wide allows wider than anything the kit needs.

## How to apply

1. In `.claude/settings.json` → `permissions.allow`, remove the two WebFetch lines, unless this project added them on purpose.
2. Merge `scripts/guard.sh`: the comment above `elif tool == "WebFetch":` and the text of its `ask(...)` message.
