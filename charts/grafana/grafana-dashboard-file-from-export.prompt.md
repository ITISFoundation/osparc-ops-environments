---
name: Save Grafana dashboard export as chart file
description: Rewrites an existing Grafana V2-model dashboard JSON file in place, replacing hardcoded datasource types with __DS_TYPE__ and hardcoded datasource uids with a datasource variable.
argument-hint: "Path to an existing dashboard JSON file exported from Grafana (V2 model)"
agent: agent
---

Input: the path to an existing file in the workspace containing a dashboard JSON exported from the Grafana UI with **Export > Model: V2**. If no path is given, use the file currently open in the editor.

## 1. Validate

Check the JSON is the V2 model: `apiVersion` starts with `dashboard.grafana.app/v2` and a `spec` object exists.

If not, stop and tell the user to re-export the dashboard from the Grafana UI with Model `V2`. Change nothing.

## 2. Rewrite datasource references

Apply to every datasource reference (annotations, variables, panels, queries, nested elements):

- Hardcoded datasource **type** (e.g. `"prometheus"`, `"loki"`): replace with `__DS_TYPE__`.
- Hardcoded datasource **uid**: never keep it and never write `__DS_UID__`. Reference a dashboard datasource variable instead, e.g. `"${datasource}"`.
- Add that variable if missing: name `datasource`, type `datasource`, query `__DS_TYPE__`.

Leave everything else untouched: panel types, query expressions, transformations, titles, ids, layout.

`__DS_TYPE__` is substituted at Helm render time by [templates/dashboards.yaml](templates/dashboards.yaml).

## 3. Save

Write the result back to the exact same input file, in place. Do not create a new file, do not move or rename it, and do not touch templates or values files.

## 4. Verify

First, check the saved dashboard file is valid JSON and still uses the V2 model (`apiVersion` starts with `dashboard.grafana.app/v2` and `spec` exists).

Then inspect every datasource reference, including nested references, and confirm:

- Datasource types use a `__<...>__` placeholder (e.g. `__DS_TYPE__`), instead of a hardcoded type such as `prometheus` or `loki`.
- No hardcoded datasource uid remains and `__DS_UID__` is not used.
- Any datasource uid reference uses the `${datasource}` dashboard variable.
