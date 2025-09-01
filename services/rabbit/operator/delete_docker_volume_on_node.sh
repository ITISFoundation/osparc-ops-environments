#!/usr/bin/env sh
set -eu

VOLUME="${VOLUME:-}"
TIMEOUT="${TIMEOUT:-60}"
INTERVAL="${INTERVAL:-5}"

if [ -z "$VOLUME" ]; then
  echo "ERROR: VOLUME not set. Usage: VOLUME=name [TIMEOUT=60] [INTERVAL=5] $0"
  exit 1
fi

echo "Deleting volume '$VOLUME'"
echo "Timeout: ${TIMEOUT}s"
echo "Interval: ${INTERVAL}s"

if ! docker volume inspect "$VOLUME" >/dev/null 2>&1; then
  echo "Volume '$VOLUME' does not exist. Nothing to do."
  exit 0
fi

elapsed=0
while [ "$elapsed" -lt "$TIMEOUT" ]; do
  if docker volume rm "$VOLUME" >/dev/null 2>&1; then
    echo "Volume '$VOLUME' removed successfully."
    exit 0
  fi
  remaining=$(( TIMEOUT - elapsed ))
  echo "Volume '$VOLUME' still in use. Retrying in ${INTERVAL}s. Time left: ${remaining}s."
  sleep "$INTERVAL"
  elapsed=$(( elapsed + INTERVAL ))
done

echo "Timeout reached. Exiting."
exit 1
