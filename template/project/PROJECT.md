# {{project.name}}: project

{{project.description}}

This file holds the architecture and layout agents need before a structural change. Commands and tooling are in [STACK.md](./STACK.md); the work process is in [harness/SETUP.md](../harness/SETUP.md).

<!-- morph-init: fill one or two sentences on what the product is and who uses it, and link the product docs (scope, idea, roadmap). Example: "Self-serve invoicing for freelancers. Scope: [docs/IDEA.md](../docs/IDEA.md)." -->

## Stack (decided)

| Layer | Choice |
|-------|--------|
<!-- morph-init: fill one row per layer the project has (runtime, web or app framework, database, data access layer, auth, payments, hosting, email, background jobs). Example row: "| Database | Postgres 16 |". Leave out layers the project doesn't have. -->

Summary: {{stack.summary}}.

## Repository layout

```
<!-- morph-init: fill the top-level folders and the few inner folders agents touch most, one comment each. Example:
src/
  api/          # HTTP handlers
  db/schema.ts  # table definitions
migrations/     # SQL migrations
tests/          # unit tests
-->
docs/                     # Product and planning
harness/                  # Generic agent process (the kit)
_harness/                 # Per-feature agent work (runtime)
project/                  # This project's agent context (this folder)
```

## Architecture

<!-- morph-init: fill the core entities and how they relate (tenancy, ownership), the request paths (UI, API, background), and the trust boundaries. Short subsections are fine. Example:
### Tenancy
- **User** → identity provider
- **Organisation** → owns projects; billing owner
- **Project** → belongs to one organisation; every query filters by organisation id
-->

### Security

<!-- morph-init: fill how each surface authenticates and authorises (session, API key, webhook signature), and which checks are authoritative versus optimistic. Example: "Dashboard: session cookie checked in each server handler; the edge middleware only redirects and authorises nothing." -->

### API conventions

| Surface | Mechanism | Auth |
|---------|-----------|------|
<!-- morph-init: fill one row per surface. Example: "| Public REST API | handlers under `src/api/v1/` | API key in `Authorization: Bearer` |". -->

### Conventions agents must follow

<!-- morph-init: fill the project rules that aren't obvious from the code and break things when missed (import boundaries, a size budget, a generated file never edited by hand). Example: "Client bundles import only from `lib/client/`; the server-only modules use secrets." -->

## Out of scope

<!-- morph-init: fill what the current version deliberately leaves out, or link the version doc that says so. -->

## Harness

Work process: [harness/SETUP.md](../harness/SETUP.md). Features: `_harness/features/<slug>/<version>/`.
