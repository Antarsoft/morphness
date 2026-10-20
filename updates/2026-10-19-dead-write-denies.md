---
id: 2026-10-19-dead-write-denies
title: Dead Write deny rules for .env files removed
kind: fix
release: 2026-10-19.4
applies_to: { modules: [] }
files:
  - .claude/settings.json
removed: []
---

## What changed

- `permissions.deny` no longer lists the ten `Write(./**/.env…)` rules. Claude Code accepts a `Write(path)` rule but never consults it: file permissions are checked against `Edit(path)` and `Read(path)` rules only. The same `.env` paths keep their `Edit(...)` and `Read(...)` deny rules, so nothing becomes unprotected.

## Why

A rule that looks like protection but is never checked gives a false sense of cover, and linters such as agnix flag it as an error.

## How to apply

In your `.claude/settings.json`, delete the lines that start with `"Write(./**/.env`. Keep the `Edit(...)` and `Read(...)` lines. If you added `Write(...)` deny rules of your own for other paths, add an `Edit(...)` rule for each, since only that one is checked.
