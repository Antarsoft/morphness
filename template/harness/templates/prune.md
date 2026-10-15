# Prune: <YYYY-MM-DD>

**Author:** Technical Lead  
**Window:** entries after `<slug> v<n>` through `<slug> v<n>` (N features)  
**Status:** proposed | approved | applied

Process: `harness/SETUP.md` § Prune; why: `harness/MORPHING.md` § Pruning.

## 1. Window vs previous

| Feature | QA rounds | Review round | Failure causes | Full-stack / QA model and effort | Retro run table |
|---------|-----------|--------------|----------------|----------------------------------|-----------------|
| | | | | | link |

**Trend:** one or two lines: did rework per feature fall, and why we think so.

## 1b. Trials

One row per `_harness/LEARNINGS.md` § Trials entry: KPI numbers over this window's features, `keep` or `revert` (or `carry on` when no feature qualified), one line of why. When the project tracks plan usage: the owner's usage reading for this prune day, next to the previous prune's.

| Trial | Features run | KPI numbers | Proposal |
|-------|--------------|-------------|----------|
| | | | keep · revert · carry on |

## 1c. Research

One row per research file added since the last prune. Leave the table empty when there were none.

| Research file | Researcher effort | Outcome | Used by |
|---------------|-------------------|---------|---------|
| | medium · high | planned · light-mode change · no action · undecided | feature slug, or none |

## 2. Rule audit

| Rule / item (file) | Added by (provenance) | Evidence | Verdict |
|--------------------|-----------------------|----------|---------|
| | feature slug · learned · `(lesson: <id>)` | fired (retro link) · insurance (cost of the failure) · never fired · too new to judge | keep · merge into … · shorten · move to on-demand · remove |

## 3. Open action items older than the window

| Item | Proposal |
|------|----------|
| | still wanted · close as skipped |

## 3b. Lessons worth sharing upstream (optional)

Rules marked `fired` or `insurance` here that are not specific to this project. Shared only with the owner's yes, via `/morph-share` (`harness/MORPHING.md` § Sharing a lesson upstream).

| Rule (file) | Why others would want it |
|-------------|--------------------------|
| | |

## 3c. Upstream updates

From `/morph-update`'s read-only listing (`harness/MORPHING.md` § Health check and upstream updates): kit updates and matching lessons this project hasn't seen, fixes first. The human decides each row; applied and declined rows are recorded by `/morph-update`. With no network: "not checked".

| Item (update note or lesson id) | Kind | Why it fits this project | Local files it touches (edited here?) | Proposal |
|---------------------------------|------|--------------------------|---------------------------------------|----------|
| | fix · module · rule · template · config · lesson | | | apply · decline · later |

## 4. Decision

Rule rows (§ 2), trial rows (§ 1b) and upstream rows (§ 3c): the human approves or rejects each; default is no change. Leftovers (§ 3): the TL decides (`harness/SETUP.md` § Retrospective → Per-feature review).

| Row | Decision | Note |
|-----|----------|------|
| | | |

## 5. Applied

Docs change / commit: … · Upstream rows applied with `/morph-update`: yes | none approved | not checked · `_harness/learnings/` files folded into `LEARNINGS.md` and deleted: yes | no · Steps files folded into the next version's checklist (roadmap module): yes | no | n/a · Last prune and Counting from updated: yes | no
