---
id: 2026-10-19-curl-guard
title: The allowed Morphness curl can only read to the terminal
kind: config
release: 2026-10-19
applies_to: { modules: [] }
files:
  - scripts/guard.sh
removed: []
---

## What changed

The allow rule for `curl -fsSL https://api.github.com/repos/antarsoft/morphness/*` (and its
raw.githubusercontent.com twin) matches any words after the URL, so `-o out.json`, `-X POST`,
`-H "Authorization: …"` or a second URL ran without a prompt. `scripts/guard.sh` now checks every
`curl` that names one of the two Morphness prefixes and asks unless the line is only `-f`, `-s`,
`-S`, `-L` flags and URLs under those prefixes (no `..` in the path). Writing a file (`-o`, `-O`,
`>`), changing the method, sending a body or headers, a config file, credentials and any other
URL or flag now wait for the owner's yes. The update checks themselves are unchanged: `gh api
--method GET` first, plain `curl -fsSL <url>` as the fallback.

## Why

The updates path reads release notes and lessons written by others. A prompt-injected line in one
could have asked for a "read" that writes into the repository or sends a token, with no prompt.

## How to apply

Merge the `check_curl` function, its call in `check_bash` and the header comment in
`scripts/guard.sh`. Nothing else changes; the allow rules in `.claude/settings.json` stay as they
are, because the guard asks before they apply.

## Skip if

The project's `.claude/settings.json` has no Morphness `curl` allow rule (it was set up before
the updates-without-a-clone change, or `updates.source` is `local`).
