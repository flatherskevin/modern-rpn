#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_PATH="${1:-$ROOT_DIR/scripts/screenshot-manifest.tsv}"
CAPTURE_SCRIPT="$ROOT_DIR/scripts/capture-screenshot.sh"
ONLY_SCENARIO="${ONLY_SCENARIO:-}"
BUILT_ONCE=0

usage() {
  cat <<'EOF'
Usage:
  scripts/capture-screenshots.sh [manifest-path]

Environment:
  ONLY_SCENARIO=<name>  Capture only one scenario from the manifest
EOF
}

if [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ ! -f "$MANIFEST_PATH" ]; then
  echo "Manifest not found: $MANIFEST_PATH" >&2
  exit 1
fi

while IFS='|' read -r scenario device_name output_path profile; do
  if [ -z "${scenario:-}" ] || [[ "$scenario" == \#* ]]; then
    continue
  fi

  if [ -n "$ONLY_SCENARIO" ] && [ "$scenario" != "$ONLY_SCENARIO" ]; then
    continue
  fi

  command=(
    "$CAPTURE_SCRIPT"
    --scenario "$scenario"
    --device "$device_name"
    --output "$ROOT_DIR/$output_path"
    --profile "$profile"
  )

  if [ "$BUILT_ONCE" -eq 1 ]; then
    command+=(--skip-build)
  fi

  "${command[@]}"
  BUILT_ONCE=1
done <"$MANIFEST_PATH"
