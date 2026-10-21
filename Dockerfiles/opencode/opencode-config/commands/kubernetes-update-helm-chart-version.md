---
description: Update a Helm chart dependency to a specified version, including its lockfile and focused validation.
---

Update a Helm chart dependency to the version proposed in a Renovate PR.

Input: $ARGUMENTS

## Rules

- Input is exactly one Renovate PR URL. If it is missing or unreadable: STOP and ask.
- Print `## Step N: <title>` before performing each step.
- Link every external claim. If a source is unreachable, write `unavailable: <what>`.
- Change only the dependency version in `Chart.yaml` plus values/templates required for compatibility.
- Never change `appVersion` or the wrapper chart's own `version`.
- Only the STOP conditions below end the run early.

## Steps

1. **Read PR** — extract chart name, upstream repo, old version, new version, chart directory in this workspace.
2. **Security check** — via GitHub and osv.dev: repo not transferred, renamed or archived; no advisory or issue reporting compromise; new tag on the default branch by the usual publisher; old->new diff has no unexplained changes to `.github/workflows`, publish config or maintainers. FAIL: STOP. Doubt: ask.
3. **Read release notes** — list breaking changes, renamed/removed/added values, changed defaults. Max 10 bullets and then ellipsis.
4. **Identify required changes** — list inspected files (`Chart.yaml`, `values*.yaml.gotmpl`, `templates/`, `files/`) and, per file, which step-3 items apply. Additionally search for any reference to old version and update them (e.g. pinned documentation links)
5. **Edit** — apply the version bump plus the compatibility edits from step 4, or state `no compatibility changes needed`.
6. **Validate** — set `.config.location` to point to `charts/.ci-deployment/repo.config`. From `charts/`, run `make helmfile-lint RELEASE=<release>` then `make helmfile-template RELEASE=<release>`. On failure fix and rerun, max 3 attempts, then STOP and report.

## Report

| Field | Value |
| --- | --- |
| Chart | |
| Old → New | |
| Upstream compromised? | |
| Sources | |
| Files inspected | |
| Files changed | |
| Compatibility edits | |
| Validation | |
| Unavailable checks | |
