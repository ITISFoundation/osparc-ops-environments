---
name: Grafana convert exported JSON to dashboard file JSON
description: Rewrites an existing Grafana V2-model dashboard JSON file in place, replacing hardcoded datasource types with the placeholders its chart substitutes and hardcoded datasource uids with a datasource variable.
argument-hint: "Path to an existing dashboard JSON file exported from Grafana (V2 model)"
agent: agent
---

Input: the path to an existing file in the workspace containing a dashboard JSON exported from the Grafana UI with **Export > Model: V2**. If no path is given, use the file currently open in the editor.

## 1. Validate

Check the JSON is the V2 model: `apiVersion` starts with `dashboard.grafana.app/v2` and a `spec` object exists.

If not, stop and tell the user to re-export the dashboard from the Grafana UI with Model `V2`. Change nothing.

Check the export was made with **Share dashboard with another instance** enabled: `metadata` must have no `namespace`, no `uid` and no `resourceVersion`, and its `labels` and `annotations` must be empty.

If not, stop and tell the user to re-export from the Grafana UI with the **Share dashboard with another instance** toggle switched on. Change nothing.

## 2. Find the placeholders

In the chart owning the dashboard file, find the Helm template that injects the dashboard JSON (grep for `__DS` or `Files.Get`). Its `replace` calls are the only valid placeholders, and they differ per chart.

Note which datasource role (metrics, logs, traces) each placeholder maps to. If no such template exists, or a role is unclear, stop and ask.

## 3. Rewrite datasource references

Apply to every datasource reference (annotations, variables, panels, queries, nested elements):

- Hardcoded datasource **type** (e.g. `"prometheus"`, `"loki"`): replace with the type placeholder of its role.
- Hardcoded datasource **uid**: never keep it and never write a uid placeholder. Reference a dashboard datasource variable instead, e.g. `"${datasource}"`.
- Add the variable if missing: one per role (`datasource`, `logsDatasource`, `tracesDatasource`), type `datasource`, query set to that role's type placeholder.

Leave everything else untouched: panel types, query expressions, transformations, titles, ids, layout.

## 4. Save

Write the result back to the exact same input file, in place. Do not create a new file, do not move or rename it, and do not touch templates or values files.

## 5. Verify

First, check the saved dashboard file is valid JSON and still uses the V2 model (`apiVersion` starts with `dashboard.grafana.app/v2` and `spec` exists).

Then inspect every datasource reference, including nested references, and confirm:

- Every datasource type uses a placeholder found in step 2, instead of a hardcoded type such as `prometheus` or `loki`.
- No hardcoded datasource uid remains and no uid placeholder is used.
- Every datasource uid reference uses the dashboard variable of its role.
