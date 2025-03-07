#!/bin/bash
set -e

DIRECTORY=$1

# Find all JSON files within the directory
FILES=$(find "$DIRECTORY" -mindepth 1 -maxdepth 1 -type f -name '*.json')

# Create a JSON object where each file's basename is the key, with full paths as values
JSON_OBJECT=$(echo "$FILES" | while read -r FILE; do
    BASENAME=$(basename "$FILE" .json)
    echo "{\"$BASENAME\": \"$FILE\"}"
done | jq -s 'add')

# Output the JSON map
jq -n --argjson files "$JSON_OBJECT" '$files'
