---
id: command-output-to-log-with-exit-file
title: Send check output to a log and record the exit code
kind: rule
target: harness/CONTROLS.md
in_template: true
tags: { stack: [], service: [], area: [tooling, cost] }
evidence: { fired: unknown, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Send check output to a log and record the exit code

## Rule

Every check writes its full output to a log file and prints only the exit code and the log's tail. Take the exit code from `$?` right after the command, never from a pipe or the log's last line. Remove the old exit file before a run and report a run only once its new exit file exists. On failure read only the failing lines.

## Why

A full test or build log in the agent's context is re-read on every later turn; a stale exit file from an earlier run was once reported as a full pass.

## How to check

The recorded exit code comes from a file newer than the run's start.
