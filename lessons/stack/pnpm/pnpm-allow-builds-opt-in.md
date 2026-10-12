---
id: pnpm-allow-builds-opt-in
title: Dependency build scripts are opt-in
kind: rule
target: project/STACK.md
tags: { stack: [pnpm], service: [], area: [tooling, dependencies] }
evidence: { fired: unknown, features: 153, source: "Twinpage learnings" }
added: 2026-10-12
---

# Dependency build scripts are opt-in

## Rule

pnpm 12 fails install on a new dependency with an install script until it is listed under `allowBuilds` in the workspace file; set it to true or false deliberately.

## Why

An unexplained install failure blocks every check.

## How to check

A plan adding a dependency with a build script names its `allowBuilds` entry.
