---
id: 2026-10-31-feature-cost-robust
title: The feature cost survives bad transcript lines and prices Sonnet 5.5 cache reads correctly
kind: fix
release: v0.15.0
applies_to: { modules: [] }
files:
  - scripts/feature-cost.sh
  - harness/MODEL_PRICES.md
removed: []
---

## What changed

- `harness/MODEL_PRICES.md`: `claude-sonnet-5-5` cache reads cost $0.10 per million tokens, not $0.20 (Anthropic prices Sonnet 5.5 and Opus 5.5 cache reads at 0.05x input). Sessions on Sonnet 5.5 read mostly from the cache, so their `Cost ≈` lines were too high. A new last paragraph says how to check the table against Claude Code's own `total_cost_usd`.
- `scripts/feature-cost.sh` no longer dies on one bad line. A torn or non-JSON line, a field of the wrong type, an invalid UTF-8 byte or a byte-order mark is skipped or read, and skipped lines are counted on the `Cost ≈` line. Token counts written as strings are read, negative or junk counts count 0, a timestamp with no zone is UTC, and the timestamps Claude Code writes and the usual `--since` forms (`2026-10-15T09:30`, `…Z`, `…+04:00`, any number of fraction digits) parse the same on every Python from 3.8 to 3.13 (rarer ISO forms, such as `20261015T0930Z`, still need Python 3.11).
- A call that appears in two transcript files counts once, on the row of the file read last: a resumed or forked session's copy with `--branch` or several `--session` ids, or a call in both a session's transcript and its subagent's (it goes on the subagent's row). Before, it counted twice.
- With `--since`, a call whose time can't be read is now left out and counted on the `Cost ≈` line ("N calls with no readable time left out by --since"); before, it was counted. Real transcripts always carry a time.
- Python runs isolated (`-I`), so a `json.py` or `re.py` in the project can't run in its place, and in UTF-8 mode, so writing `≈` to a Windows cp1252 console or pipe no longer fails.
- Transcript discovery handles an emoji in the project path, a recorded folder reached through a symlink (`/tmp` is `/private/tmp` on macOS), and picks the newest matching folder in the fallback.
- Exit codes change (STABILITY.md lists them): 0 with a `Cost` or `not measured` line as before; 2 for an unknown option (was 0); 1 with a `Cost: not measured (…)` line when `scripts/lib/config.sh` is missing or the script itself fails (was 0, with nothing on stdout, so the budget check was lost silently). Nothing in the kit relied on the old 0.

## Why

One bad byte in a transcript made the script print a traceback and exit 0: no `Cost ≈` line for the retro and no `Budget:` check, with nothing telling the Technical Lead. And on Sonnet 5.5 the estimate ran well above what Claude Code itself reports, because one rate in the table was double the published price.

## How to apply

1. Copy `scripts/feature-cost.sh` from the kit. Projects rarely edit it; if yours did, keep your edits and take from the kit: the two `not measured` lines at the top, the `python3 -I -X utf8` line, the `count`, `parse_time`, `folder_name` and `first_cwd` helpers, the folder lookup, the transcript loop, the notes on the Cost line and the exit code handling at the end.
2. In `harness/MODEL_PRICES.md`, set the `claude-sonnet-5-5` Cache read cell to `0.10`, set `Prices as of:` to `2026-10-31`, and add the last paragraph ("To check the table against Claude Code's own figure …"). If you keep your own rates (Bedrock, a discount), leave your numbers and date and only add the paragraph.
3. Cost lines already written in learnings files and retros stay as they are; they were estimates at the old rate. Say so in the next prune if a trial compares costs across the change.
