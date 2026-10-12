# <label>: <short name>

**Roadmap:** id `<id>`, order <n>, status `<next | planned | idea>`. Checklist: [checklist.md](./checklist.md) (once `next` or `planned`). Part of the project's roadmap (`roadmap.file` in `harness.config.yml`).  
**Status:** one line on where it stands.  
**Goal:** one sentence: who it is for and what they can do when it ships.  
**Starts when:** what has to be true first (usually: the previous version is `shipped`).

<!-- Roadmap module. Create from harness/templates/version.md when the human decides a new version. It lives in its own folder, `<roadmap.versions_dir>/<id>/<id>.md`, next to the version's `checklist.md` and `steps/`. The id is the folder name and file stem (for example `v2`); the label is free text (v2, 2.0.0, a name). Rules: harness/modules/roadmap/README.md. -->

## Exit criteria

The version is `shipped` when all hold (the human says so):

1.

## In scope

- **<item id> <title>.** One line of why. Size S / M / L.

## Out of scope

- <item>: why, and which version it goes to.

## Done

- <item id>: link to the feature's `Plan/plan.md`.

## Still to do

- **Code:**
- **Human-only:** tracked in the checklist, not here.

## Before launch

Checks that belong to this version's launch and that no feature owns (legal review, provider settings, production environment variables).

## Carried over

From earlier versions (code scope and anything a release carried forward).

## Decisions

| Date | Decision | By |
|------|----------|----|
