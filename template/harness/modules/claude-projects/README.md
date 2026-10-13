# Module: Claude Projects

Use this module when you run the harness from a Claude Project: a coordinator session watches the
project chat and starts a thread session for each piece of work, and each thread runs Claude Code
against this repo. Nothing here changes the process. The Technical Lead is the thread's Claude; the
coordinator only routes work and keeps project memory.

Claude Projects settings and instructions live in the Claude app, not the repo, so Morphness can only
advise them. Everything below is a suggestion you can change.

## Advised settings

Set these in the Project's settings. They mirror `harness.config.yml` § claude_projects.

| Session | Model | Effort | Why |
|---------|-------|--------|-----|
| Coordinator | opus | medium | It triages, routes and answers status from memory; it doesn't plan or code. |
| Feature threads | opus | high | The thread is the Technical Lead: it writes plans and drives agents. |
| One-shot threads (a status check, a quick question) | opus | medium | Short work that doesn't need a plan. |

Subagent models and efforts come from `.claude/agents/*.md` in the repo, whatever the thread runs on.
For risky features the Technical Lead may ask you to raise a thread's effort; say so in the thread.

## Playbook to paste into the Project instructions

Copy the block below into the Project's custom instructions. Edit names and paths if yours differ.

```markdown
This project uses the Morphness harness in the repository. Read AGENTS.md and CLAUDE.md first.

Coordinator:
- Start one thread per feature or fix. The thread's Claude is the Technical Lead: it plans in
  _harness/features/<slug>/<version>/Plan/, gets the owner's approval, delegates to the Full-stack
  and QA subagents, and never writes application code itself.
- Brief a new thread with the owner's message and only what memory adds: the repo, the integration
  branch, decisions already made. Don't add deliverables the owner didn't ask for.
- Answer status questions from memory and the thread list; don't message a thread just to ask.
- Recurring checks (is the preview ready, did the nightly run pass) get a new short thread each time.
- Keep in memory: the repository, harness.config.yml basics, owner preferences about how much to
  hear, and open decisions. Don't copy plans or results into memory; they live in the repo.

Feature threads (Technical Lead):
- One feature, one PR per thread. When the PR merges, resolve the thread.
- Every decision the owner makes in chat goes into plan.md § Decisions in the same turn.
- After two QA rework rounds, the thread may hand over to a fresh thread at a natural break
  (QA pass, PR marked ready). The closing reply lists open decisions and links the new thread.
- Ask the owner only for what agents can't do: approval, accounts, remote environments,
  judgement calls. Put those in the steps file.
```

## Thread rules (also in `.claude/rules/technical-lead.md` § One feature per thread)

- **Every message wakes the whole thread.** A thread re-reads its history on each message, so send
  nothing into a thread that needs no action. An "ok" or "thanks" costs a full turn.
- **Long threads cost more per step.** Hand over to a new thread after a natural break rather than
  running several PRs in one.
- **Decisions in files, not chat.** A handed-over thread must leave nothing in chat that the files
  don't hold.
- **Shared lines between threads.** When two threads would edit the same line of a shared file, the
  thread whose plan was approved first owns it; the other plans around it.
- **Background agents.** A thread that launches a background agent checks for signs of life on a
  timer (one cheap shell command) and relaunches it if it has gone quiet.

## On install

- Keep this folder; morph-init prints the advised settings and the playbook in its hand-off.
- Add `claude-projects` to `environment` and `modules` in `harness.config.yml`.

## On remove

When the project doesn't run the harness from a Claude Project, morph-init deletes this folder and the items below. The thread rules in `.claude/rules/technical-lead.md` § One feature per thread stay: in a plain CLI session a thread is one session, and the sentences about a coordinator or the project chat say "when there is one" or "with the `claude-projects` module".

**Delete these files:** none outside this folder.

**Delete or reword these lines:**

- `harness.config.yml`: delete the `claude_projects` block with its two comment lines above it, and remove `claude-projects` from `environment` and `modules`.
- `harness/README.md` § Modules: the `claude-projects` row.

**Unlink:** every Markdown link left pointing into `harness/modules/claude-projects/` becomes plain text, or goes with its line (`/morph-doctor` fails on a broken link). Find them with `grep -rn 'modules/claude-projects' --include='*.md' . | grep -v '^./harness/modules/'`.
