# Known limits, shown on the public results page

One line per limit, each starting with "- ". `scripts/trust-report.sh` copies these onto the page as they are, so write them for a reader who does not know the kit. Keep them at the level of categories. The same limits are described for owners in `template/harness/GUARD.md` ("What it does not see").

- The guard hook is a safety net for an agent that makes mistakes. It is not a sandbox, and it does not stop an agent or script that is determined to get around it.
- The guard reads Bash commands as the shell does, but it does not see inside a script file or Makefile target that an earlier call wrote, code that an interpreter decodes or builds at run time, or a command-line tool it has no rule for.
- A command written so that the shell builds it while it runs, for example from variables or with unusual quoting, can hide a command or file name from the guard. The guard's rules are written for commands as they are usually typed.
- Shell expansions the guard does not perform itself, such as word breaks from `${IFS}`, brace lists, `$'…'` quoting and short globs, can hide a command or a file name from it.
- Commands that git runs on your behalf from hooks, aliases or helpers already set in a repository are not checked. Setting a new one with `git config` or `git -c` asks first.
- Secrets are recognised by file name and by common commands. A secret stored in a file with an unusual name is not seen.
- A search over the whole project (grep, or Claude Code's Grep tool) is stopped or asks only when the folder holds a file with a known secret name. A secret inside a file with another name can still be printed.
- Reading files outside the project is not blocked, except known credential files such as SSH and cloud keys.
- When the hook does not answer within Claude Code's hook time limit, Claude Code runs the call. The guard ends its own check sooner and blocks the call, so this needs a hang its own timer can't end, such as one before the check starts.
- Only Bash, file tools, Grep, WebFetch and MCP tool calls are checked. Other tools are left to Claude Code's own permission prompts.
- The test suite is the kit's own: it shows the guard does what the kit says it does on the cases listed. No tool on this page tests the guard against hostile input beyond those cases.
- No tool on this page measures quality or cost compared with plain Claude Code. Morphness adds process, and process costs tokens.
- The real protection for shared environments is the host: branch protection, and environment secrets that only the owner holds.
- Static scanners read the kit's text and scripts. They do not run an agent, so they say nothing about how a model behaves with these rules.
- Process rules, such as planning before code, which mode a change runs in and which files each agent may edit, are instructions to the model, and the model can skip them. Only the guard, the tool limits set on an agent and the checks run at the end of a task are code. In the lighter modes (light, small and research) no separate agent tests the work.
- Before a task counts as done, the kit runs the project's checks (tests, lint and the like) as committed on the branch the work merges into. An agent that moves that branch in its own clone (with `git update-ref` or a fetch refspec) changes which commands run, and the guard does not ask.
- The checks at the end of a task skip files that count as documentation: the kit's documentation folders, Markdown files, the README and LICENSE. A project can add paths to that list or remove them, but the check script keeps the kit's own list, so a path the project added is still checked as code and code under a path it removed is still skipped.
- When a bug fix finds the same mistake in other places, those are left for separate changes unless the owner says otherwise. The fix's record lists each one, and they stay unfixed until someone plans them.
- A change that touches sign-in, secrets, money or people's data gets a security review, and the review always runs again on the final code after its findings are fixed, so such a change pays for two reviews. The security module widens which changes get one.
- `/morph-update` does not scan upstream update notes and lessons when it applies them. The kit's own checks scan them for commands, links and changes to the guard, settings or secrets when they are proposed and merged, and the owner reads each item before it is applied. A copy installed from a fork gets that fork's notes, which the kit's checks never saw.
- Installs and updates are pinned to the commit a release tag named when the copy first read it. A tag moved before a copy reads it cannot be told apart from the original.
- With no option, the cost estimate (`feature-cost.sh`) counts the whole current Claude Code session. When the session did other work before the feature, the figure includes it unless `--since` is given.
- The kit does not isolate a headless run (`claude -p`). One started from inside another Claude Code session inherits that session's environment, including its memory and settings, and a fresh config folder alone does not isolate it.
