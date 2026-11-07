---
slug: <feature-slug>
status: passed          # passed | escalated | waiting_owner | split
mode: full              # the mode the Technical Lead chose
qa_rounds: 1
departure: no           # yes when the plan departs from docs/product/ (say how below)
split_into: []          # for status split: [{ slug, title, depends_on: [...] }, ...] in build order
bugs_found: []          # bugs outside this plan: [{ in: <feature-slug>, what: <one line>, where: <path> }]
v1_items: []            # one line per owner item (steps file) or `human decides` rule item; the driver copies them to the checklist
---

At most 40 lines below. The next features read this instead of the code, so name what they can use.

## Built

What works now, in a few lines.

## Interfaces others can use

Modules, functions, components, data shapes and events, with their paths.

## Decisions

Choices made in this feature that later ones must keep.

## Departures

How and why the plan departs from `docs/product/`, or `none`.
