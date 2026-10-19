---
id: 2026-10-17-security-module
title: Optional security module (threat model, secret scanning, dependency audit)
kind: module
release: 2026-10-19
applies_to: { modules: [] }
offer_module: security
files:
  - harness/modules/security/README.md
  - harness/README.md
  - harness/CONTROLS.md
  - harness/SETUP.md
  - harness/templates/plan.md
  - harness/agents/fullstack-engineer.md
  - harness/agents/qa-engineer.md
  - project/CONTROLS.md
  - .claude/rules/technical-lead.md
  - harness.config.yml
  - harness/HANDOFFS.md
  - harness/MODES.md
  - harness/TECHNICAL_LEAD.md
  - harness/templates/bug-plan.md
removed: []
---

## What changed

A new optional `security` module for products with sign-in, payments or data about people. A change
that alters who can sign in or read or change data, moves money, handles secrets or deletes people's
data is a **security feature** (touching user data alone isn't, and a small-mode change never is): it
fills a short threat model
in `plan.md` § Security (assets, entry points, how each one checks identity and ownership, threats with
the mitigation and the acceptance criterion that tests it, new secrets, accepted risks), and gets the
security review before QA whatever its effort, with the existing subagent fallback when the
`security-review` skill is missing. Two named checks run on every feature: `secrets` (secret scanning,
gitleaks in the examples, always redacted) and `audit` (the stack's dependency audit). Their commands
live in `project/CONTROLS.md`, with § Security paths and § Security exceptions (accepted advisories
with a review date). An `audit` advisory on a package the branch didn't add or upgrade is recorded as
pre-existing, not a QA fail.

## Why

Security work only got a deeper look when the plan happened to run at `xhigh` effort on a risk area,
nothing checked for keys left in the code, and a vulnerable dependency could be added without anyone
seeing it. The threat model makes each mitigation a tested acceptance criterion before approval.

## How to apply

Run `/morph-module add security` (it asks morph-init's Q11b and does the steps below), or by hand:

1. Ask whether the product has sign-in, payments or data about people (morph-init
   `references/questions.md` Q11b) and which secrets and audit tools to use; check each is installed.
   A missing tool is an owner step; the check is recorded as not run until then.
2. Add `harness/modules/security/README.md`, and every span the template marks `module:security`
   (`harness/README.md` § Modules → **Module markers**) at the same place in the project's copy:
   the module row in `harness/README.md`, two named-check rows and § Security checks and features in
   `harness/CONTROLS.md`, the inline sentence in `harness/SETUP.md` § Code review before QA, § Security
   and the review line in `harness/templates/plan.md`, and the two rows, § Security paths and
   § Security exceptions in `project/CONTROLS.md` (fill the rows' commands and § Security paths).
3. Merge the "With the `security` module" bullets into `harness/agents/fullstack-engineer.md` and
   `harness/agents/qa-engineer.md`, and the review clause into `.claude/rules/technical-lead.md`.
4. Add `security` to `modules`, `secrets` and `audit` to `checks.before_qa` and
   `checks.before_signoff`, and an `audit` row with scope `paths` (the manifests and lockfile) to
   `project/CONTROLS.md` § Check scope. With the ci-cd module, add both as CI steps.
5. Put the module's owner steps in `project/RELEASE.md` § Manual steps: install the tools, turn on the
   code host's secret scanning and push protection.

## Skip if

The product has no sign-in, no payments and keeps no data about people, or the project already runs
its own secret scanning and audit with a security review on every risky change.
