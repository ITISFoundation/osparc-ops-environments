#!/usr/bin/env sh
set -eu

VOLUME="${VOLUME:-}"
TIMEOUT_MINUTES="${TIMEOUT_MINUTES:-2}"
INTERVAL_SECONDS="${INTERVAL_SECONDS:-5}"

if [ -z "$VOLUME" ]; then
  echo "ERROR: VOLUME not set. Usage: VOLUME=name [TIMEOUT_MINUTES=2] [INTERVAL_SECONDS=5] $0"
  exit 1
fi

case "$VOLUME" in
  *rabbit*) ;;
  *)
    echo "[SAFEGUARD] ERROR: VOLUME name must contain 'rabbit'."
    exit 1
    ;;
esac

echo "Deleting volume '$VOLUME'"
echo "Timeout: ${TIMEOUT_MINUTES}m"
echo "Interval: ${INTERVAL_SECONDS},"

if ! docker volume inspect "$VOLUME" >/dev/null 2>&1; then
  echo "Volume '$VOLUME' does not exist. Nothing to do."
  exit 0
fi

elapsed=0
timeout_seconds=$(( TIMEOUT_MINUTES * 60 ))
while [ "$elapsed" -lt "$timeout_seconds" ]; do
  if docker volume rm "$VOLUME" >/dev/null 2>&1; then
    echo "Volume '$VOLUME' removed successfully."
    exit 0
  fi

  remaining=$(( timeout_seconds - elapsed ))
  echo "Volume '$VOLUME' still in use. Retrying in ${INTERVAL_SECONDS}s. Time left: ${remaining}s."
  sleep "$INTERVAL_SECONDS"

  elapsed=$(( elapsed + INTERVAL_SECONDS ))
done

echo "Timeout reached. Exiting."
exit 1
