# Tech: <product name>

Written by the director. How the first version is built; the repo's existing stack and `project/STACK.md` win where they differ.

## Stack

Languages, frameworks, libraries and versions, and why each.

## Structure

Folders and modules, what lives where, and the boundaries features must keep (for example game logic as pure, testable code apart from the UI).

## Data

What is stored, where, its shape, and how it is saved and migrated.

## Interfaces between features

The modules and functions later features build on, named so each feature's card can point at them, with the edge cases each must handle. One row per edge case; an interface with none has one row that says `none` and why in the result column. Cover empty or zero input; boundaries (0, the cap, just above 0, just past the cap); a call before the thing it needs is ready (not loaded, not signed in, not set up); errors and failures (returned or thrown, logged or shown to the user); and time edges (midnight, time zones, a clock change, a long gap since the last run). Features turn each row into an acceptance criterion with a test (plan checklist item 41).

| Interface (path) | Shape | Producer → consumers | Edge case | Expected result |
|------------------|-------|----------------------|-----------|-----------------|
| `src/sim/tick.ts` `tick(state, dt)` | `(State, number) → State` | sim → save, ui | `dt` is 0 | returns the state unchanged |

## Testing

What each kind of test covers here, and what can't be tested in a headless run (it goes to the checklist as an owner check).

## Risks

What could go wrong technically, and the feature that deals with each.
