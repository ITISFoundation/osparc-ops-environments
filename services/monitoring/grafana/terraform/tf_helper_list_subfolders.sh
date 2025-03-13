#!/bin/bash
set -e

DIRECTORY=$1

# Use `find` to get the directories' base names
SUBFOLDERS=$(find "$DIRECTORY" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

# Convert the subfolder names into a JSON object with jq, where each is paired with itself
JSON_OBJECT=$(echo "$SUBFOLDERS" | tr ' ' '\n' | jq -Rn '
  [inputs] |
  map(select(. != "")) |
  map({key: ., value: .}) |
  from_entries')
# Output the JSON map
jq -n --argjson subfolders "$JSON_OBJECT" '$subfolders'
