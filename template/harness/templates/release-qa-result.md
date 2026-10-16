# Release QA result: vX.Y.Z

**Release:** `vX.Y.Z`  
**Release PR:** <link> (release branch → production branch)  
**Path:** `_harness/releases/<version>/qa-result.md` (QA engineer only)  
**Created:** YYYY-MM-DD  
**Updated:** YYYY-MM-DD  
**Started:** YYYY-MM-DD HH:MM (from `date`; agent's note, the TL records real duration)  
**Ended:** (from `date`; separate times per round if using Round 2)

Process: [harness/RELEASE.md](../../../harness/RELEASE.md) step 3; project specifics and the smoke checklist: [project/RELEASE.md](../../../project/RELEASE.md). The human's "release" command is acted on (anything that reaches production) only after this file's verdict is **pass**.

## Environment

- **Release branch commit tested:** (`git rev-parse origin/<release branch>`, the integration branch unless a middle environment has its own; must be the release PR's head)
- **Release QA environment and URL:** (the `environments` entry just before production, `project/RELEASE.md`; "local" when there is none)
- **Checks run:**

## What ships

From `git log --oneline origin/<production>..origin/<integration>`.

| Feature (`_harness/features/<slug>/<version>/`) | Feature QA | Migrations | Env var changes |
|--------------------------------------------------|-----------|------------|-----------------|
| `<slug>/<version>` | pass (`QA/qa-result.md`) | none / list | none / list |

## Checks ([CONTROLS.md](../../../harness/CONTROLS.md), the full `before_signoff` suite on the tested commit)

One row per name in `harness.config.yml` → `checks.before_signoff`, in that order (commands: `project/CONTROLS.md`). A name with no command there is recorded as **not run**.

| Check | Exit code | Notes |
|-------|-----------|-------|
| <each `before_signoff` check> | | |

## Smoke on the release QA environment

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
