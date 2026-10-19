# Prune: <YYYY-MM-DD>

**Author:** Technical Lead  
**Window:** entries after `<slug> v<n>` through `<slug> v<n>` (N features)  
**Status:** proposed | approved | applied | declined

Process: `harness/SETUP.md` § Prune; why: `harness/MORPHING.md` § Pruning.

## 1. Window vs previous

| Feature | QA rounds | Review round | Failure causes | Full-stack / QA model and effort | Est. cost | Retro run table |
|---------|-----------|--------------|----------------|----------------------------------|-----------|-----------------|
| | | | | | $… or not measured | link |

**Cost:** window total $… over N measured features, average $… per feature; previous window average $… (or "first window"). Estimates at API list prices (`harness/MODEL_PRICES.md`), so compare windows priced the same way.

**Escaped:** the window's `Escaped` retro lines (bugs found after QA passed), one line each, or "none". A repeat points at a rule row in § 2.

**Trend:** the `Last N features: …` line from `bash scripts/prune-counter.sh --prune` (average rework rounds, QA fails, total cost), then one line: did rework and cost per feature fall against the previous window, and why we think so.

## 1b. Trials

One row per active trial in `_harness/trials/`: its `Trial …` line from `bash scripts/prune-counter.sh --prune` (features run against its length, rework rounds, QA fails, cost), `keep` or `revert` against its Pass and Revert lines, or `carry on` when it hasn't run its length or its escape window (one prune window of features after its last trial feature) is still open, with one line of why. Add the `Escaped` lines traced to its features, from bug-mode and fix-PR learnings files. When the project tracks plan usage: the owner's usage reading for this prune day, next to the previous prune's.

| Trial | Features run | Numbers | Proposal |
|-------|--------------|-------------|----------|
| | | | keep · revert · carry on |

## 1c. Research

One row per research file added since the last prune, from its header and § How it went. Leave the table empty when there were none.

| Research file | Researcher effort | Outcome | Check | Scope and effort | Used by |
|---------------|-------------------|---------|-------|------------------|---------|
| | medium · high | planned · light-mode change · no action · undecided | held · partly · overruled | right · too wide · too narrow · effort too low · effort too high | feature slug, or none |

**Proposals:** a tweak per pattern the rows show (a default researcher effort for a kind of question, a scoping rule in `project/agents/researcher.md`), or "none". Decided with the rule rows.

## 2. Rule audit

Start from the `Rule tags` lines of `bash scripts/prune-counter.sh --prune`: every rule tagged `(from <slug>, <date>)`, with the features finished since. For each, check the retros after that date for the problem its **Why raised** names.

| Rule / item (file) | Added by (provenance) | Evidence | Verdict |
|--------------------|-----------------------|----------|---------|
| | `(from <slug>, <date>)` · feature slug · learned · `(lesson: <id>)` | fired (retro link) · insurance (cost of the failure) · never fired · too new to judge | keep · merge into … · shorten · move to on-demand · remove |

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

Docs change / commit: … · Upstream rows applied with `/morph-update`: yes | none approved | not checked · `_harness/learnings/` files folded into `LEARNINGS.md` and deleted: yes | no · Trial features added to their trial file's § Results: yes | none · Steps files folded into the next version's checklist (roadmap module): yes | no | n/a · Last prune and Counting from updated: yes | no
