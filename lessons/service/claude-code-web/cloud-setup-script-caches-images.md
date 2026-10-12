---
id: cloud-setup-script-caches-images
title: Cache heavy images in the environment setup script
kind: rule
target: project/STACK.md
tags: { stack: [], service: [claude-code-web], area: [tooling, cost] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Cache heavy images in the environment setup script

## Rule

Container images the local stack pulls are pulled in the environment's setup script (a human adds it), which must finish in about five minutes for its cache to apply.

## Why

Each fresh session spent over a minute pulling the same images.

## How to check

None; a human step in the stack doc.
