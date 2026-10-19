---
id: 2026-10-19-qa-layout-pass
title: QA checks every page at the narrowest width on a UI change
kind: rule
release: unreleased
applies_to: { modules: [] }
files:
  - harness/agents/qa-engineer.md
removed: []
---

## What changed

On a UI change, QA opens every page of the app at the narrowest width `project/TESTING.md`
supports (320 px when it names none), signed in and signed out, and checks nothing scrolls sideways
or is cut off. Each page and its result goes in `qa-result.md`. An overflow fails QA when the request
was about layout, phones or screen size, even when it names one page, and is a hand-off finding
otherwise.

## Why

Asked to fix the layout for narrow screens, the agents fixed the products page and left the
signed-in account page overflowing: screenshots covered only the pages the plan named. With a
layout pass that only reported other pages, QA found the overflow and logged it as out of scope, so
the fail now covers any page when the request is about screen size.

## How to apply

Add the "UI change, layout pass" bullet to `harness/agents/qa-engineer.md` after the screenshot
bullet. Projects with a narrowest supported width other than 320 px name it in `project/TESTING.md`.
