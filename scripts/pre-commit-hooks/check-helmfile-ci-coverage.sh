#!/usr/bin/env bash
# Fails if any charts/<name>/ directory is missing from charts/helmfile.ci.yaml.
# Ensures every new chart is scanned by the Trivy PR workflow.
set -euo pipefail

exclude_dirs_regex='^(\..*|simcore-charts)$'

return_code=0

for d in charts/*/; do
  name="$(basename "$d")"
  [[ "$name" =~ $exclude_dirs_regex ]] && continue
  grep -q "${name}/" charts/.ci-deployment/helmfile.yaml && continue
  echo "Missing in charts/.ci-deployment/helmfile.yaml: $name" >&2
  return_code=1
done

exit "$return_code"
