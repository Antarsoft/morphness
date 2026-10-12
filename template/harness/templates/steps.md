<!-- Steps file: the human's steps after QA pass (harness/HANDOFFS.md § Steps file, harness/SETUP.md § After QA pass, step 4).
     Roadmap module off: _harness/features/<slug>/<version>/steps.md
     Roadmap module on:  <roadmap.versions_dir>/<id>/steps/<slug>.md (folded into that version's checklist at release and prune)
     Rule: the human does only what agents can't. No items means no file, and plan.md says Steps file: none.
     Ids: <id>-<feature-slug>-N with the roadmap module, <feature-slug>-N without it. Delete the sections that have no items. -->

### <feature-slug> (QA pass YYYY-MM-DD, [qa-result.md](<relative path>/_harness/features/<slug>/<n>/QA/qa-result.md))

**Needs you**

- [ ] **<feature-slug>-1** What to do, in one line, and what you should see (why only a human: account no agent can reach / change to the integration or production environment / judgement call).

**Deferred from QA**

- [ ] **<feature-slug>-2** AC <n>: what to check, where, and with which login. QA could not reach <service> in its environment (`qa-result.md` § Verdict).

**Apply to the integration environment** (features with migrations)

- [ ] **<feature-slug>-3** After the merge, apply the migrations (`<files in order, from progress.md>`) by the project's workflow or by hand (`project/RELEASE.md`), then tell the Technical Lead (with the `data-access` module, QA then runs stage B).
