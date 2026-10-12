---
id: pnpm-reresolve-lockfile-after-upgrade
title: Re-resolve the lockfile after a package manager upgrade
kind: rule
target: project/STACK.md
tags: { stack: [pnpm], service: [], area: [tooling, dependencies] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Re-resolve the lockfile after a package manager upgrade

## Rule

After a pnpm upgrade, force one re-resolve (add and remove a scratch dev dependency), check that no resolved version moved, and commit the lockfile alone. A plain install on a clean tree is a no-op.

## Why

A stale lockfile surfaced as about 150 unrelated lines the next time a dependency changed, and cost a whole feature.

## How to check

The upgrade PR has a lockfile-only commit.
