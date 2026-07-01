#!/usr/bin/env bash
# Fails if any charts/<name>/ directory is missing from charts/helmfile.ci.yaml.
# Ensures every new chart is scanned by the Trivy PR workflow.
set -euo pipefail

return_code=0

for d in charts/*/; do
  name="$(basename "$d")"
  [[ "$name" == ".template" || "$name" == "simcore-charts" ]] && continue
  grep -q "${name}/" charts/helmfile.ci.yaml && continue
  echo "Missing in charts/helmfile.ci.yaml: $name" >&2
  return_code=1
done

exit "$return_code"
