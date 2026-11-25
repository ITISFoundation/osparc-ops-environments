---
description: Update a Helm chart dependency to the version from a Renovate PR.
---

Update a Helm chart dependency to the version proposed in a Renovate PR.

Input: $ARGUMENTS

## Rules

- Input: exactly one Renovate PR URL. Missing or unreadable: STOP and ask.
- Print `## Step N: <title>` before each step.
- Link every external claim; if unreachable, write `unavailable: <what>`.
- Change only the dependency version in `Chart.yaml` and values/templates needed for compatibility. Never touch `appVersion` or the wrapper chart's `version`.
- Only STOP conditions end the run early.

## Steps

1. **Read PR** — chart name, upstream repo, old/new version, local chart directory.
2. **Security check** (GitHub, osv.dev) — repo not transferred/renamed/archived; no advisory or compromise report; new tag on default branch by usual publisher; no unexplained changes to `.github/workflows`, publish config or maintainers between versions.
3. **Chart changes** — one bullet per chart version (`<old> -> <new>`), breaking changes marked. Max 10, then `…`.
4. **Image changes** — only if upstream `appVersion` changed: one bullet per image tag (`<old> -> <new>`). From release notes, flag breaking changes, deprecations and renamed/removed metrics that affect this workspace (values, templates, collector/alert configs, dashboards). Max 10, then `…`.
5. **Required changes** — per inspected file (`Chart.yaml`, `values*.yaml.gotmpl`, `templates/`, `files/`), list applicable step 3/4 items. Also update other references to the old version (e.g. pinned doc links).
6. **Edit** — apply the bump and step 5 edits, or state `no compatibility changes needed`.
7. **Validate** — set `.config.location` to `charts/.ci-deployment/repo.config`. In `charts/` run `make helmfile-lint RELEASE=<release>`, then `make helmfile-template RELEASE=<release>`. On failure fix and retry (max 3), then STOP and report.

## Report

Each section is a heading with one finding per bullet:

- `### Chart` — `<name>, <old> -> <new>`
- `### Chart version changes` — from step 3
- `### Image version changes` — from step 4, with workspace impact; or `no image change`
- `### Security check` — repo state, advisories, publisher, workflow/config diff
- `### Files changed` — file and change made
- `### Validation` — command, pass/fail, attempts
- `### Unavailable checks` — or `none`
