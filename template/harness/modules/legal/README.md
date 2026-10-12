# Module: legal (legal wording)

Optional. Enable it in `harness.config.yml` → `modules` when the product has legal pages (terms, privacy policy, refund policy, data-processing agreement) or customer-facing sentences that make legal or data-handling promises. Legal wording is written by the `legal-writer` subagent. Only the legal portion of a feature goes to it; the rest stays with the plan's Full-stack and QA variants.

## What counts

What counts in this project is listed in [project/HARNESS_AGENTS.md](../../../project/HARNESS_AGENTS.md) § Legal wording. In general:

- Any text on the legal pages, and the values those pages read from code (company name, address, contact).
- Consent, acceptance and fine-print lines that link to or summarise those pages: a sign-up form's terms line, a waitlist or newsletter consent line, cookie or consent banners.
- Text quoted from or mirroring a legal page elsewhere in the code (a promise constant, a storage-key description shown to customers).
- Any other customer-facing sentence (UI, email, help page) that states a legal right or obligation, a data-handling or retention promise, a refund or cancellation term, or who the operator or seller of record is.
- Not legal wording: marketing copy, prices, ordinary UI and error text, internal docs. When unsure, the Technical Lead treats it as legal.

## Flow

1. While planning, the Technical Lead sets `plan.md` § QA scope → **Legal wording: yes** when any change fits the list above, and lists each legal change in the plan (page or component, what must be said and why).
2. Before asking for approval, the Technical Lead launches `legal-writer` with the feature folder path and that list. It writes `<feature>/Legal/legal-copy.md`: every sentence, where it goes, and a check row per sentence against the sources below.
3. The Technical Lead checks each check row against its source `file:line` and links `legal-copy.md` from the plan. The owner approves the wording with the plan.
4. Full-stack pastes the sentences word for word. It may change the markup around them (links, line breaks, components), never the words. A sentence it needs that the file lacks is a hand-back to the Technical Lead, who reruns `legal-writer`.
5. Any later change to a legal sentence (a review finding, a QA fail, the owner's comment) goes back to `legal-writer`, which updates `legal-copy.md`; then Full-stack applies it.
6. QA checks every sentence in `legal-copy.md` appears word for word where the file says, one row per sentence in `qa-result.md` § Legal wording. A missing or reworded sentence is a fail.

**The Technical Lead never writes or rewords a legal sentence, and never lets Full-stack do it.** Even one sentence about what a key or a tool can read goes to `legal-writer`. Subagents can't start subagents, so only the Technical Lead launches it.

## Sources

The legal writer checks every sentence against two project docs:

- **`docs/LEGAL.md`**: where each legal page's copy lives, when the pages must be updated (a list of triggers such as a new data field, a new processor, a new storage key), and the open items for a lawyer.
- **A promises runbook** (for example `docs/LEGAL_PROMISES_RUNBOOK.md`): each promise the pages make (deletion within N days, export on request) and the steps that keep it true. A sentence that touches a promise says whether the runbook's steps still hold.

Each check row names the fact and its source `file:line`, every other page that states the same fact and whether they agree, the `LEGAL.md` trigger it falls under, the runbook promise it touches, and whether it changes a lawyer item. Facts that live in code are written as the placeholder the page already uses, never typed in. Gaps go under **Open points** with a suggested default; the writer never invents a fact.

## On install

- Create stubs for `docs/LEGAL.md` and the promises runbook when the project has neither (headings only: pages and their files, when the pages must be updated, for the lawyer; promises and their steps).
- Fill [project/HARNESS_AGENTS.md](../../../project/HARNESS_AGENTS.md) § Legal wording with this project's legal pages and files, and `project/agents/legal-writer.md` (sources, style, pages that must agree).
- Keep the `legal-writer` agent in `.claude/agents/` and its row in the agents table; set its model (advised `fable`, fallback `opus`).
- Keep the plan template's § QA scope line **Legal wording** and the `qa-result.md` template's **Legal wording (from plan)** line and § Legal wording section (both templates ship with them).

## On remove

When the project doesn't choose this module, morph-init deletes this folder and the items below. Sentences elsewhere that start "With the `legal` module" (the Technical Lead rule, the Full-stack and QA bodies, checklist item 35) and the plan template's `n/a (legal module off)` choice stay as they are.

**Delete these files:**

- `.claude/agents/legal-writer.md`
- `harness/agents/legal-writer.md`
- `project/agents/legal-writer.md`

**Delete or reword these lines:**

- `harness.config.yml` → `agents`: the `legal_writer` line.
- `CLAUDE.md` § Claude Code notes → **Delegation**: drop ", and `legal-writer` for a plan's legal wording (when the `legal` module is enabled)".
- `project/HARNESS_AGENTS.md`: in the first sentence drop "and, for legal wording, the **legal writer**" (keep "the **Full-stack engineer** and the **QA engineer**"); delete the `Legal writer` row of § Agents; delete § Legal wording.
- `harness/STRATEGY.md`: in the first sentence drop ", an optional **legal writer**"; delete the `Legal writer` row of § Agents (high level), the `Legal/` and `legal-copy.md` lines of the folder tree, and § Agent 4: Legal writer.
- `harness/SETUP.md` § Claude Code execution: the `Legal writer` row.
- `harness/HANDOFFS.md` § Ownership: the `Legal/legal-copy.md` row.
- `harness/README.md` § Modules: the `legal` row. In the table of folders, the `agents/` row becomes "Generic role bodies for the Full-stack and QA subagents (project addenda in `project/agents/`)".
- `_harness/README.md`: the `Legal/` and `legal-copy.md` lines of the folder tree.
- `harness/templates/qa-result.md`: the **Legal wording (from plan)** line under § Environment and § Legal wording.

**Unlink:** every Markdown link left pointing into `harness/modules/legal/` becomes plain text, or goes with its line (`/morph-doctor` fails on a broken link). Find them with `grep -rn 'modules/legal' --include='*.md' . | grep -v '^./harness/modules/'`.
