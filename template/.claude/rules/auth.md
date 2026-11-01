---
paths:
  - "**/auth/**"
  - "**/auth.*"
  - "**/session/**"
  - "**/sessions/**"
  - "**/session.*"
  - "**/middleware.*"
  - "**/policies/**"
---

# Sign-in and access

You are reading or changing sign-in, sessions or access rules. Keep these paths in step with `project/CONTROLS.md` § Risk paths.

<!-- morph-init: fill the paths above with this repo's sign-in, session and access-rule paths from project/CONTROLS.md § Risk paths, then delete this comment. -->

- A change here is on a risk path: full mode, however small (`bash scripts/risk-check.sh <files>`).
- Test the verification and rejection paths (a bad signature, a missing or expired session, another user's data) where that works without live keys ([testing.md](testing.md)).<!-- module:security --> A change to who can sign in or what they can reach is a security feature ([harness/modules/security/README.md](../../harness/modules/security/README.md)).<!-- /module:security -->
- A subagent working on these paths gets this file named in its prompt.
