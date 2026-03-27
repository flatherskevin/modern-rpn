#!/usr/bin/env bash

set -euo pipefail

SCREENSHOTS_DIR="${1:-screenshots}"
OUTPUT_PREFIX="${2:-APP - }"
PHONE_WIDTH=1284
PHONE_HEIGHT=2778

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required: missing 'magick' command." >&2
  exit 1
fi

if [ ! -d "$SCREENSHOTS_DIR" ]; then
  echo "Screenshots directory not found: $SCREENSHOTS_DIR" >&2
  exit 1
fi

shopt -s nullglob
pngs=("$SCREENSHOTS_DIR"/*.png "$SCREENSHOTS_DIR"/*.PNG)

if [ "${#pngs[@]}" -eq 0 ]; then
  echo "No PNG files found in $SCREENSHOTS_DIR"
  exit 0
fi

is_phone_screenshot() {
  local file="$1"
  local name width height
  local -i ratio_scaled

  name="$(basename "$file")"
  name="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"

  if [[ "$name" == *iphone* || "$name" == *phone* ]]; then
    return 0
  fi

  read -r width height < <(magick identify -format "%w %h" "$file")

  if [ "$height" -le "$width" ]; then
    return 1
  fi

  ratio_scaled=$(( height * 1000 / width ))

  if [ "$ratio_scaled" -ge 2000 ] && [ "$ratio_scaled" -le 2300 ]; then
    return 0
  fi

  return 1
}

processed=0
skipped=0

for file in "${pngs[@]}"; do
  if [[ "$(basename "$file")" == "${OUTPUT_PREFIX}"* ]]; then
    echo "Skipping generated file: $(basename "$file")"
    skipped=$((skipped + 1))
    continue
  fi

  if is_phone_screenshot "$file"; then
    output_path="$(dirname "$file")/${OUTPUT_PREFIX}$(basename "$file")"
    echo "Resizing $(basename "$file") -> $(basename "$output_path")"
    magick "$file" -resize "${PHONE_WIDTH}x${PHONE_HEIGHT}!" "$output_path"
    processed=$((processed + 1))
  else
    echo "Skipping non-phone screenshot: $(basename "$file")"
    skipped=$((skipped + 1))
  fi
done

echo "Done. Processed: $processed, skipped: $skipped"
