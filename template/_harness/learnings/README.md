# Learnings, one file per feature

Each feature's retro entry and its new action items live in their own file here, `<feature-slug>-v<version>.md`, so two feature branches never edit the same lines (a shared learnings file is the most common merge conflict between parallel branches).

- **Written by** the Technical Lead with the feature's retro, on the feature branch ([harness/SETUP.md](../../harness/SETUP.md) § Retrospective).
- **Format:** a `# <feature-slug> v<version> learnings` title, the entry in the format of [`LEARNINGS.md`](../LEARNINGS.md) § Entry format, then `## Action items` with a table in the columns of `LEARNINGS.md` § Action items → Open (`From retro | # | Type | Action | Why raised | Status | Note`), or "None".
- **Decisions:** the approve / skip / defer is the Technical Lead's, except an item that adds a step for the owner, changes product behaviour or customer-facing copy, or costs money, which the owner decides. It is recorded in the Status column of this file; an item applied later names the feature or file in Note.
- **Prune counter:** the number of `*-v*.md` files here is the number of features since the last prune (`bash scripts/prune-counter.sh` counts them with the integration branch's and prints the line for the hand-off); the prune is due at `loop.prune_every` in `harness.config.yml`.
- **Folded by** the prune: it condenses each entry to one line in `LEARNINGS.md` § Entries, moves each action item row to the matching `LEARNINGS.md` table, and deletes the file.
