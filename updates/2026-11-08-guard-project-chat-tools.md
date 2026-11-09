---
id: 2026-11-08-guard-project-chat-tools
title: The guard lets the Claude Projects thread tools through
kind: template
release: v0.18.0
applies_to: { modules: [] }
files:
  - harness/GUARD.md
  - scripts/guard.sh
removed: []
reviewed: "It lets one fixed list of tools from the hearthbot server (the Claude Projects thread tools) pass scripts/guard.sh: replies, reactions, the checklist, decision cards, resolve, reminders, renames and messages inside the owner's own project. Tools of that server that reach the device, connectors or the model still ask, and a tool of the same name on any other server still asks. It adds no setting, permission or network call."
---

## What changed

- **`scripts/guard.sh`** passes these `mcp__hearthbot__` tools: `post_message`, `edit_message`, `react`, `unreact`, `no_reply_needed`, `update_progress_checklist`, `rename_thread`, `request_decision`, `close_decision`, `set_thread_resolved`, `set_thread_reminder`, `message_coordinator`, `message_thread`, `post_widget`, `mark_draft_sent` and `show_helpline_card`. Its read tools (`read_thread`, `list_threads` …) already passed. `connect_device`, `start_remote_control`, `stop_remote_control`, `suggest_connectors`, `switch_model` and `set_effort_level` still ask.
- **`harness/GUARD.md`** names them in the MCP line.

## Why

A Claude Projects thread must end every turn with one of these tools. When the thread runs on the owner's computer, in a project with Morphness installed, the guard read them as connector writes and asked on every turn, even for `no_reply_needed`. They only post inside the owner's own project.

## How to apply

1. Copy `scripts/guard.sh` from the kit. Agents can't write it, so the owner copies it by hand (`/morph-update` prints the `cp`).
2. In `harness/GUARD.md`, take the kit's sentence about the Claude Projects thread tools in the MCP line.

## Skip if

The project never runs Claude Projects threads on this computer, or `guard.mcp_writes` is `off`.
