---
paths:
  - ".github/workflows/**"
  - ".github/actions/**"
  - ".gitlab-ci.yml"
  - ".circleci/**"
  - "**/Dockerfile"
  - "**/Dockerfile.*"
  - "**/docker-compose*.yml"
  - "**/vercel.json"
  - "**/netlify.toml"
  - "**/fly.toml"
  - "**/render.yaml"
  - "**/railway.json"
  - "**/wrangler.toml"
  - "**/wrangler.json"
  - "**/wrangler.jsonc"
  - "**/serverless.yml"
  - "**/sst.config.*"
  - "**/firebase.json"
  - "**/*.tf"
---

# CI and deploy

You are reading or changing CI or deploy config: how code reaches the shared environments.

<!-- morph-init: fill the paths above with this repo's CI and deploy config (the files harness.config.yml → environments deploys through), then delete this comment. -->

- Change the files; never deploy yourself: no deploy CLI, deploy script or workflow run. `{{branches.production}}` moves only through a release ([harness/RELEASE.md](../../harness/RELEASE.md); this project's steps: [project/RELEASE.md](../../project/RELEASE.md)).<!-- module:ci-cd --> The kit's workflows: [harness/modules/ci-cd/README.md](../../harness/modules/ci-cd/README.md).<!-- /module:ci-cd -->
- The guard asks the owner before each edit to a CI definition ([harness/GUARD.md](../../harness/GUARD.md)).
- A subagent working on these paths gets this file named in its prompt.
