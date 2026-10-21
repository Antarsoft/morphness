# Claims ledger

`tests/claims.jsonl` maps each promise in the README to what backs it. `scripts/kit-selftest.sh` reads it and fails when a promise has no entry, when an entry's promise has left the README, or when a proof no longer exists.

**What counts as a promise:** each row of the README's "Why use it" table, the "What it isn't" note, the install routes (`Ask your agent`, `Or as a plugin`, `Or by hand`) and `Requirements and cost`. An entry's `readme` field is that row's bold label, exactly as the README spells it. Rename a row and its entry has to follow.

**Entry fields**

| Field | Meaning |
|-------|---------|
| `id` | Short unique slug. |
| `readme` | The promise's label in the README. |
| `claim` | What the README says, in one line. |
| `status` | `tested`, `present` or `judgement` (below). |
| `proofs` | The things that back it. |
| `note` | What the proofs do not cover. Required, and stated plainly. |

**Statuses**

- `tested`: something runs and can fail. It needs at least one `guard` or `selftest` proof.
- `present`: the mechanism is in the kit's own text (a rule, an agent, a script), and the self-test confirms it is there, but nothing runs a model to check that a session follows it.
- `judgement`: the claim is partly a matter of opinion ("easy", "any codebase"). The entry names the closest measurable stand-in as its proofs and says in `note` what stays unproven. These are counted in the self-test summary, so the number can't grow unnoticed.

**Proof kinds**

- `{"kind": "guard", "expect": "deny", "contains": "git push origin {P}"}`: a case in `tests/guard-cases.jsonl` with that verdict whose tool input contains the text. Optional `tool` (exact tool name) and `"raw": true` (a case whose input is not a tool event). The self-test already replays every case, so the entry shows the claim is exercised.
- `{"kind": "selftest", "path": "...", "contains": "..."}`: the file holds a check the self-test runs, named by that text. Rename the check and the entry fails.
- `{"kind": "check", "path": "...", "contains": "..."}`: the file exists and still holds that text (a rule, a script, a fixture).

**Adding a promise to the README:** add its entry in the same PR. If nothing can prove it, add a `judgement` entry and say so in `note`.
