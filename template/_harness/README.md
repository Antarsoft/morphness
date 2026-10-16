# Feature work (runtime)

Active and completed harness features live under **`features/`**. The kit that defines the process is in [`harness/`](../harness/); this folder holds what the process produces.

## Layout

```
features/
  <feature-slug>/
    <version>/
      Plan/
        feature.md
        plan.md
        review.md      # TL: code review findings (Full-stack xhigh only)
        retro.md       # TL: retrospective (after QA pass or escalation)
      Research/
        <topic>.md     # researcher: optional research before the plan
      Legal/
        legal-copy.md  # legal writer (legal module, Legal wording: yes only)
      Development/
        progress.md
      QA/
        qa-result.md
      steps.md         # TL: the human's steps at QA pass (roadmap module off; on, under docs/versions/)
research/              # research mode: <YYYY-MM-DD>-<slug>.md, one question each
learnings/             # one learnings file per feature until the next prune
prunes/                # one prune proposal per prune: <YYYY-MM-DD>.md
releases/
  <release-version>/
    qa-result.md       # release QA record
LEARNINGS.md           # condensed entries, trials, action items
HARNESS_BACKLOG.md     # larger harness changes waiting for a slot
```

Across features: [LEARNINGS.md](./LEARNINGS.md) holds one condensed line per folded retro, the trials table and the action-items tables with each item's status.

## Start a feature

1. Copy templates from [`harness/templates/`](../harness/templates/) into a new path, e.g. `features/my-feature/1/Plan/`.
2. Follow [`harness/SETUP.md`](../harness/SETUP.md).

Do not commit secrets or production credentials into this tree.
