---
paths:
  - "**/migrations/**"
  - "**/*.sql"
  - "**/schema.prisma"
---

# Data

You are reading or changing database schema, migrations or SQL. Keep these paths in step with `project/CONTROLS.md` § Risk paths.

<!-- morph-init: fill the paths above with this repo's schema and migration paths from project/CONTROLS.md § Risk paths (for example `supabase/migrations/**`, `drizzle/**`, `db/schema.ts`), then delete this comment. -->

- A change here is on a risk path: full mode, however small (`bash scripts/risk-check.sh <files>`).
- Write the change as migration files and run it on the local stack only ([project/STACK.md](../../project/STACK.md)). Never apply it to a shared remote database from a CLI, a script or a connector: it reaches remote through the project's workflow or by the owner ([project/RELEASE.md](../../project/RELEASE.md)). A read-only query on remote needs the owner's yes.<!-- module:data-access --> Data-access features: [harness/modules/data-access/README.md](../../harness/modules/data-access/README.md).<!-- /module:data-access -->
- A migration that drops or rewrites stored data is called out in the plan; `bash scripts/risk-check.sh` flags it too.
- A subagent working on these paths gets this file named in its prompt.
