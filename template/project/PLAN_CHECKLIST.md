# Plan checklist: project items

The Technical Lead runs [harness/PLAN_CHECKLIST.md](../harness/PLAN_CHECKLIST.md) and then this file before asking the owner to approve a `plan.md`. The kit file holds items that apply to any project; this file holds items that only make sense here (a path, a constant, a page or a test helper of this codebase). Retros add items here; prunes audit them like any other rule ([harness/SETUP.md](../harness/SETUP.md) § Prune).

Record the greps and their hit counts in `plan.md` § References → **Greps**: one line per kit item (`K1`, `K2`, …, covering that item's specifics below) and one per project item (`P1`, `P2`, …); write "n/a" for an item that doesn't apply. Cite items with the prefix in retros and prunes too, so a kit number and a project number never read alike.

## Before asking for approval

Run the kit checklist first, then every item under § Items below. A plan whose **Greps** record lacks a line for each item (a hit count or "n/a") is not ready for approval.

## Item format

Number items `P1`, `P2`, … and never renumber (retros and prunes cite them). Each item is one bullet:

- a bold one-line rule;
- when it applies ("When a plan changes …");
- the grep or check to run, with the exact paths;
- what to do with each hit (put it in the steps, or in the AC's allowed-leftover list);
- the reason in brackets: the failure it prevents, or the feature that taught it.

Example (not an active item):

> **P0. Public pages and the sitemap agree.** When a plan changes a gate, redirect or the list of public pages, compare it with the sitemap source (`src/sitemap.ts`) and put each mismatch in the steps or the allowed-leftover list (learned: the sitemap listed pages the gate still blocked).

## Specifics for kit items

Project greps, paths and values that sharpen a kit item without being a new rule. List them under the
kit item they belong to, e.g. "**K6 (Every affected file).** Also grep `src/legal/` for renamed field
names (learned: …)". Prefer this over a new `P` item when a kit item already states the principle.

None yet.

## Items

None yet.
