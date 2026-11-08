---
slug: <feature-slug>
status: passed      # passed | escalated | waiting_owner | split | not-a-bug (an inserted fix that found no bug)
# reason: product-decision   # not-a-bug only: not-reproduced | product-decision (add an owner item) | duplicate
# evidence: src/sim/actions.ts:42 or module-detail plan D2 or the slug it duplicates   # not-a-bug only
mode: full          # full | bug | small | light | small-bug: the mode the Technical Lead chose
qa_rounds: 1
departure: no       # yes when the plan departs from docs/product/ (say how in § Departures)
---

At most 40 lines below. The next features read this instead of the code, so name what they can use. The driver reads the three list sections: one `- ` line per item, or `- none`.

## Built

What works now, in a few lines.

## Interfaces others can use

Modules, functions, components, data shapes and events, with their paths.

## Decisions

Choices made in this feature that later ones must keep.

## Departures

How and why the plan departs from `docs/product/`, or `none`.

## Owner items

- none   (one line per item in the steps file; a rule item from the retro starts `rule:`)

## Bugs found

- none   (outside this plan: `- <feature-slug> | what is wrong | where | kind | reproduction`, kind `behaviour`, `style`, `docs` or `decision`; only behaviour with a failing test or steps becomes a fix; a bug in the harness itself, its scripts or rules: `- harness | what is wrong | where`)

## Split into

- none   (status split only: `- <part-slug> | title | depends on, comma separated, or -`)
