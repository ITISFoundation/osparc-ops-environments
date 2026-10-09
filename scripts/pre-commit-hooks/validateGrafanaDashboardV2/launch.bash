#!/bin/bash
#
# Fails if a Grafana dashboard JSON is not exported with the V2 model.

set -o nounset
set -o pipefail
IFS=$'\n\t'

error=0
for file in "$@"; do
  if ! grep -q '"apiVersion"[[:space:]]*:[[:space:]]*"dashboard\.grafana\.app/v2' "$file"; then
    echo "ERROR: $file is not a Grafana V2 model dashboard (re-export from Grafana UI with Export > Model: V2)"
    error=1
  fi
done

exit "$error"
