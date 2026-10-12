# Release QA result: vX.Y.Z

**Release:** `vX.Y.Z`  
**Release PR:** <link> (integration branch → production branch)  
**Path:** `_harness/releases/<version>/qa-result.md` (QA engineer only)  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD  
**Started:** YYYY-MM-DD HH:MM (from `date`; agent's note, the TL records real duration)  
**Ended:** (from `date`; separate times per round if using Round 2)

Process: [harness/RELEASE.md](../../../harness/RELEASE.md) step 3; project specifics and the smoke checklist: [project/RELEASE.md](../../../project/RELEASE.md). The human's "release" command is acted on (anything that reaches production) only after this file's verdict is **pass**.

## Environment

- **Integration commit tested:** (`git rev-parse origin/<integration>`; must be the release PR's head)
- **Integration environment URL:** (preview or staging deploy; "local" when the project has none)
- **Checks run:**

## What ships

From `git log --oneline origin/<production>..origin/<integration>`.

| Feature (`_harness/features/<slug>/<version>/`) | Feature QA | Migrations | Env var changes |
|--------------------------------------------------|-----------|------------|-----------------|
| `<slug>/<version>` | pass (`QA/qa-result.md`) | none / list | none / list |

## Checks ([CONTROLS.md](../../../harness/CONTROLS.md), the full `before_signoff` suite on the integration commit)

| Check (command from `project/CONTROLS.md`) | Exit code | Notes |
|--------------------------------------------|-----------|-------|
| `install` | | |
| `typecheck` | | |
| `lint` | | |
| `unit` | | |
| `build` | | |
| `e2e-full` (browser-e2e module) | | |

## Smoke on the integration environment

Steps from `project/RELEASE.md` § Smoke checklist that apply to this release; mark the rest `n/a` with the reason.

| Step | Status | Evidence |
|------|--------|----------|
| <smoke step> | pass / fail / n/a | |

## Production prerequisites (for the human, RELEASE.md step 4)

- **Migrations to apply to production before merging, in order:** none / list
- **Env vars to set in production before merging:** none / list

## Round 2

(Only if applicable: after fixes merged into the integration branch.)

## Verdict

- **Result:** pass | fail

### Blocking issues (if fail)

1. 

## Notes for Technical Lead
