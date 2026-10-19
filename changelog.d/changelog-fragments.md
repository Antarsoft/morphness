Changelog fragments: PRs no longer edit `CHANGELOG.md`. A change to `template/` or `skills/` adds
`changelog.d/<slug>.md` with its entry, `scripts/check-updates.sh --since` requires one, and
`scripts/release-changelog.sh <release>` assembles the dated section at release time. Parallel PRs no
longer conflict on the changelog.
