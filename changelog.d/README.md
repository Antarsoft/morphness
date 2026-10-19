# Changelog fragments

A PR that changes `template/` or `skills/` adds one file here, `changelog.d/<slug>.md`, holding its
changelog entry (one paragraph, same style as `CHANGELOG.md`). PRs don't edit `CHANGELOG.md`, so two
PRs never conflict on it. `scripts/release-changelog.sh <release>` turns the fragments into the dated
`CHANGELOG.md` section and deletes them (CONTRIBUTING.md § Releases).
