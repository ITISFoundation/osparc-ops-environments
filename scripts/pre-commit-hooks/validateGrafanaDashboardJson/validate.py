#!/usr/bin/env python3
"""Fails if a Grafana dashboard JSON is not a V2 model export shareable with another instance."""

import json
import sys

V2_API_VERSION_PREFIX = "dashboard.grafana.app/v2"
INSTANCE_SPECIFIC_KEYS = (
    "namespace",
    "uid",
    "resourceVersion",
    "labels",
    "annotations",
)
HINT = 'Export > Model: V2 with "Share dashboard with another instance" switched on'


def find_errors(dashboard: dict) -> list[str]:
    """Lists everything that makes the dashboard unfit for the repository."""
    api_version = dashboard.get("apiVersion")
    errors = []
    if not str(api_version).startswith(V2_API_VERSION_PREFIX):
        errors.append(f"apiVersion {api_version!r} is not the V2 model")
    for key in INSTANCE_SPECIFIC_KEYS:
        value = dashboard.get("metadata", {}).get(key)
        if value:
            errors.append(f"metadata.{key} is instance-specific: {value!r}")
    return errors


def main(paths: list[str]) -> int:
    """Reports every invalid dashboard file and returns the exit code."""
    failed = False
    for path in paths:
        with open(path, encoding="utf-8") as file:
            errors = find_errors(json.load(file))
        for error in errors:
            print(f"ERROR: {path}: {error}")
        if errors:
            print(f"       re-export it from the Grafana UI with {HINT}")
            failed = True
    return int(failed)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
