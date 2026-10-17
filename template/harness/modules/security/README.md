# Module: security (threat model, secret scanning, dependency audit)

Optional. Enable it in `harness.config.yml` → `modules` when the product has sign-in, takes payments or stores data about people. It adds three things: a threat model in the plan of every **security feature**, two named checks that run on every feature (`secrets` and `audit`), and a security review before QA for security features. The rules are tool-neutral; the examples use **gitleaks** for secrets. The commands are the `secrets` and `audit` rows in [project/CONTROLS.md](../../../project/CONTROLS.md), the only place they are spelled out.

## What counts as a security feature

The Technical Lead sets `plan.md` § Security → **Security feature: yes** when the plan touches any of these. When unsure, it is yes.

- **Authentication and sessions:** sign-in, sign-up, password or key reset, tokens, session handling, roles and permissions, invitations, impersonation.
- **Payments and money:** checkout, subscriptions, refunds, credits or balances, payment webhooks, prices a customer is charged.
- **User data:** fields about people added, shown, exported, shared with a service or deleted; files people upload; anything one account can read of another's.
- A `risk_areas` entry in `harness.config.yml`.

This project's paths for each are in [project/CONTROLS.md](../../../project/CONTROLS.md) § Security paths, so the check is a grep of the plan's files, not a guess.

## Threat model

A security feature's plan fills `plan.md` § Security before approval. It is short and specific to the change, not a general essay:

- **Assets:** what an attacker would want from this change (an account, money, another customer's data, a secret).
- **Entry points:** each new or changed route, handler, job, webhook, form or file upload, and who can reach it (anyone, a signed-in user, an admin, another service).
- **Identity and ownership:** how each entry point knows who is calling (session check, signed token, webhook signature) and how it checks the caller may touch this record, with the `file:line` of each check.
- **Threats and mitigations:** one row per threat the entry points open (someone else's id in the request, a replayed or forged webhook, a missing ownership filter, a value that reaches a query, page or shell unescaped, a secret in a log or response, too many attempts). Each mitigation names the acceptance criterion that tests it, and that test covers the rejection path (`.claude/rules/testing.md` § Security boundaries).
- **Secrets:** each new secret, where it lives (the host's secret store, a local env file that is never committed) and who sets it (the owner, as a human step). Never a value in the plan.
- **Accepted risks:** anything left open on purpose, with the reason. The owner accepts these with the plan.

The plan's § Inputs and client code still covers new fields, client code and enforcement on every write path; the threat model is the feature-wide view and may link to those lines instead of repeating them.

## Named checks

| Check | What it proves | Runs |
|-------|----------------|------|
| `secrets` | No secret (key, token, password, private key) is in the branch's commits or in the working tree, uncommitted files included | Full-stack before every handoff and QA on the final commit |
| `audit` | No dependency with a known high or critical advisory is added or upgraded | Full-stack when the diff touches a dependency manifest or lockfile (a `paths` row in `project/CONTROLS.md` § Check scope); QA on the final commit |

Examples (morph-init fills the real ones from the stack and the installed tools; check the tool's own docs for its version):

- `secrets`: `gitleaks git --log-opts="origin/<integration>..HEAD" --redact --no-banner && gitleaks dir . --redact --no-banner` (the branch's commits, then the working tree). Folders it should skip (dependencies, vendored code, build output) go in `.gitleaks.toml` → `[allowlist]` `paths`.
- `audit`: `npm audit --omit=dev --audit-level=high`, `pnpm audit --prod --audit-level high`, `uv run pip-audit` (or `pip-audit -r requirements.txt`), `govulncheck ./...`, `cargo audit`, `bundle exec bundle-audit check --update`.

Rules for both:

- **Never print a secret.** The secrets command always redacts, its log stays in the scratchpad, and no agent pastes a finding's value into a file, a commit, a PR or a reply. A finding is named by file, line and rule only.
- **A real secret is the owner's.** An agent removes it from the change, and the steps file asks the owner to rotate it (a key that reached a pushed commit counts as leaked even after the commit is gone). Rewriting pushed history is the owner's call. Agents never set or rotate secret values (`AGENTS.md` § Shared remote environments).
- **A false positive** goes in the tool's ignore file (`.gitleaksignore`, by fingerprint) with a comment saying why, in the same diff, and QA checks each new entry. A test fixture that looks like a key uses an obviously fake value instead where it can.
- **The audit judges this change, not the world.** Advisories appear without any code change. When `audit` fails, QA compares the flagged packages with the lockfile diff (`git diff <merge-base> -- <lockfile>`): a package the branch added or upgraded is a fail; one it didn't touch is recorded in `qa-result.md` as **pre-existing**, not a fail, and the Technical Lead raises it to the owner as its own bug-mode fix or an accepted advisory.
- **Accepted advisories** (no fixed version yet, or not reachable from this project's code) are listed in [project/CONTROLS.md](../../../project/CONTROLS.md) § Security exceptions with the reason, the owner's approval and a review date, and the audit command skips exactly those ids. An entry past its review date is reported by `/morph-doctor`.
- **The audit needs the advisory database.** Offline, it is recorded as **not run** with the reason, never as passed.
- With the `ci-cd` module, CI runs both like any `before_qa` check. The job installs each tool at a pinned version and reads no secret but the built-in token.

## Security review before QA

For a plan with **Security feature: yes**, the Technical Lead runs the security review in [harness/SETUP.md](../../SETUP.md) § Code review before QA (step 2, then steps 3 to 5) after dev completes and before QA, whatever the plan's effort: `/security-review` with a brief naming the files to read in full, at least 15 tool calls, the count recorded in `Plan/review.md`. Without the `security-review` skill, a read-only subagent with the same brief does it and `review.md` says so; the review is never skipped. The code review in step 1 stays for `xhigh` plans. The brief also names the plan's § Security, so the review checks each mitigation is in the code.

QA confirms each `fix` item from `review.md` as usual, and that every mitigation's acceptance criterion passed.

## Owner steps

Agents can't do these; they go in `project/RELEASE.md` § Manual steps, and morph-init lists them in its hand-off:

- [ ] Install the secrets tool (and the audit tool, when the stack doesn't ship one) on each computer and cloud environment the agents run in. Until then the check is recorded as **not run**.
- [ ] Turn on the code host's own secret scanning and push protection (GitHub: Settings → Code security; free on public repositories, a paid add-on for private ones). It catches a secret the local check missed, at push time.
- [ ] Optional: turn on dependency alerts (GitHub: Dependabot alerts) so a new advisory reaches you between features.

## On install

- Fill the `secrets` and `audit` rows in [project/CONTROLS.md](../../../project/CONTROLS.md) § Named checks from the stack (check each tool is installed with its version command; a missing tool is an owner step above, and the row still gets its command). Add both names to `harness.config.yml` → `checks.before_qa` and `checks.before_signoff`, and a § Check scope row `| audit | paths | <the dependency manifests and lockfile> |`.
- Fill § Security paths (the auth, payment and user-data code and the database tables that hold personal data) and leave § Security exceptions at "None.".
- Suggest `auth`, `payments` and `user data` for `risk_areas` when the scan finds them and they aren't listed.
- With the `ci-cd` module, add the two steps to CI (the module's rule: one step per `before_qa` check, word for word).

## On remove

When the project doesn't choose this module, morph-init deletes this folder and the items below. Sentences elsewhere that start "With the `security` module" (the Technical Lead rule, the Full-stack and QA bodies) stay as they are.

**Delete these files:** none outside this folder.

**Delete the marked text:** every span and line marked `module:security`, with the command in [harness/README.md](../../README.md) § Modules → **Module markers**.

**Delete or reword these lines** (unmarked: always-loaded, config or code-block text):

- `harness.config.yml` → `checks`: remove `secrets` and `audit` from `before_qa` and `before_signoff`, if listed.
- `project/CONTROLS.md` § Check scope: the `audit` row, if any.

**Unlink:** every Markdown link left pointing into `harness/modules/security/` becomes plain text, or goes with its line (`/morph-doctor` fails on a broken link). Find them with `grep -rn 'modules/security' --include='*.md' . | grep -v '^./harness/modules/'`.
