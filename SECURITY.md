# Security

Morphness is a set of Markdown rules, agent definitions and shell scripts that run inside your own
Claude Code sessions. The parts with a security impact are:

- `scripts/install.sh`, which copies files into your repo;
- `template/.claude/settings.json` and the permission rules `/morph-init` writes, which deny agents
  access to secrets, protected branches and shared remote environments;
- lessons and profiles from the community catalog, which become instructions your agents follow.

## Reporting a vulnerability

Please don't open a public issue. Use GitHub's
[private vulnerability reporting](https://github.com/antarsoft/morphness/security/advisories/new)
with what you found, how to reproduce it, and what an attacker could do. You'll get a reply within a
week, and credit in the release notes if you want it.

In scope: a permission rule that doesn't block what it claims to, an install step that overwrites or
leaks files, and a merged lesson that tells agents to do something unsafe.
