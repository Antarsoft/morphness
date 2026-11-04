---
id: 2026-11-03-risk-path-review
title: The code review before QA runs on every risk path, and xhigh is for sign-in, secrets and money
kind: rule
release: v0.16.0
applies_to: { modules: [] }
files:
  - _harness/README.md
  - harness/HANDOFFS.md
  - harness/MODES.md
  - harness/SETUP.md
  - harness/SKILLS_AND_MCPS.md
  - harness/STRATEGY.md
  - harness/TECHNICAL_LEAD.md
  - harness/modules/security/README.md
  - harness/templates/bug-plan.md
  - harness/templates/plan.md
  - harness/templates/retro.md
  - project/HARNESS_AGENTS.md
removed: []
reviewed: "It names secrets only as a kind of change that keeps Full-stack at xhigh and gets the security review; it touches no secret, setting, guard, permission or harness.config.yml value."
---

## What changed

- **The code review before QA runs for every full or bug plan on a risk path**, not only when Full-stack is `xhigh` (`harness/SETUP.md` § Code review before QA). A plan is on a risk path when `bash scripts/risk-check.sh` named one for the change (a `- <file>: <area>` line, a `deletes stored data` line, or a change to the risk check or the risk paths list); a plan raised to full only by file count or by choice isn't. After dev, the Technical Lead runs the risk check again with no files, and a risk path the plan didn't name gets the review anyway. The plan's **Code review before QA** line says `yes` for it.
- **The review runs at `/code-review medium`**, and at `/code-review high` when Full-stack is `xhigh` or the change touches access rules.
- **The security review (step 2) is for sign-in, access rules, secrets, money, a public API, or deleting or sharing people's data.** The plan's line says `yes, with the security review` for those. A risk path outside them, such as a migration that only adds columns or indexes, gets the code review alone. With the `security` module, a security feature still gets the security review whatever the line says.
- **`xhigh` is for sign-in and sessions, secrets, and money** (`harness/SETUP.md` § Choosing a level). Tenancy, access rules, concurrency, public APIs and new architecture now run Full-stack at `high`, with the code review (and for access rules and public APIs, the security review) carrying the depth. QA stays at `medium`, and `high` only when Full-stack is `xhigh`.
- **Bug mode** runs the code review on a fix's diff when the risk check named a risk path; a hotfix off the risk paths skips it.
- `harness/templates/plan.md` and `bug-plan.md` (§ Agent effort), `harness/TECHNICAL_LEAD.md`, `harness/HANDOFFS.md`, `harness/MODES.md`, `harness/STRATEGY.md`, `harness/SKILLS_AND_MCPS.md`, `_harness/README.md`, `project/HARNESS_AGENTS.md` (risk areas) and the security module say the same. The retro template's example process change no longer names the old rule.

## Why

A risk-path change with Full-stack at `high` got no code review at all, and the review ran only at `xhigh`. Meanwhile `xhigh` on a tenancy feature cost several times a plain session and found nothing a review would have missed. A read-only review costs much less than an `xhigh` build, and it finds what the acceptance criteria don't name on every risky change, not only the rare `xhigh` ones.

## How to apply

1. Merge `harness/SETUP.md` § Code review before QA (the opening, steps 1 and 2), § Effort per feature → § Choosing a level (the `xhigh` and QA bullets), § Split large features by risk, the status table's `approved` row and the first feature checklist's step 4.
2. Merge the **Code review before QA** line (and, with the `security` module, the **Security review before QA** line in `plan.md`) in `harness/templates/plan.md` and `harness/templates/bug-plan.md`, and the `xhigh` note on the Full-stack line in `plan.md`.
3. Merge the matching lines in `harness/TECHNICAL_LEAD.md`, `harness/HANDOFFS.md`, `harness/MODES.md` (§ Full harness step 2, § Bug mode step 3), `harness/STRATEGY.md`, `harness/SKILLS_AND_MCPS.md`, `_harness/README.md`, `harness/templates/retro.md`, the risk areas line in `project/HARNESS_AGENTS.md` and, with the `security` module, `harness/modules/security/README.md`.
4. Open plans keep the effort and review line they were approved with. A project whose prune set its own `xhigh` areas in `project/HARNESS_AGENTS.md` § Effort per feature keeps them.

## Skip if

Never: every project with risk paths gets the review.
