---
id: nextjs-streamed-page-scope-test-ids
title: Scope test ids on streamed pages
kind: testing-rule
target: project/TESTING.md
in_template: true
tags: { stack: [nextjs, playwright], service: [], area: [e2e, flaky] }
evidence: { fired: 1, features: 153, source: "Twinpage prune audits" }
added: 2026-10-12
---

# Scope test ids on streamed pages

## Rule

On a page with `loading.tsx`, test-id locators are scoped to a role locator (a named region); under load an unscoped test id can match React's hidden streaming copy.

## Why

Unscoped locators flaked only under a full suite run.

## How to check

Grep specs for streamed pages for unscoped `getByTestId`.
