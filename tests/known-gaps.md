# Known limits, shown on the public results page

One line per limit, each starting with "- ". `scripts/trust-report.sh` copies these onto the page as they are, so write them for a reader who does not know the kit. Keep them at the level of categories. The same limits are described for owners in `template/AGENTS.md` § Permissions for this project ("What it does not see").

- The guard hook is a safety net for an agent that makes mistakes. It is not a sandbox, and it does not stop an agent or script that is determined to get around it.
- The guard reads Bash commands as the shell does, but it does not see inside a script file or Makefile target that an earlier call wrote, code that an interpreter decodes or builds at run time, or a command-line tool it has no rule for.
- Secrets are recognised by file name and by common commands. A secret stored in a file with an unusual name is not seen.
- Only Bash, file tools, Grep and MCP tool calls are checked. Other tools are left to Claude Code's own permission prompts.
- The test suite is the kit's own: it shows the guard does what the kit says it does on the cases listed. No tool on this page tests the guard against hostile input beyond those cases.
- No tool on this page measures quality or cost compared with plain Claude Code. Morphness adds process, and process costs tokens.
- The real protection for shared environments is the host: branch protection, and environment secrets that only the owner holds.
- Static scanners read the kit's text and scripts. They do not run an agent, so they say nothing about how a model behaves with these rules.
