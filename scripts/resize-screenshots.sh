#!/usr/bin/env bash

set -euo pipefail

SCREENSHOTS_DIR="${1:-screenshots}"
PHONE_PREFIX="${2:-APP - }"
PHONE_WIDTH=1284
PHONE_HEIGHT=2778
IPAD_PORTRAIT_WIDTH=2048
IPAD_PORTRAIT_HEIGHT=2732
IPAD_LANDSCAPE_WIDTH=2732
IPAD_LANDSCAPE_HEIGHT=2048

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required: missing 'magick' command." >&2
  exit 1
fi

if [ ! -d "$SCREENSHOTS_DIR" ]; then
  echo "Screenshots directory not found: $SCREENSHOTS_DIR" >&2
  exit 1
fi

pngs=()
while IFS= read -r -d '' file; do
  pngs+=("$file")
done < <(find "$SCREENSHOTS_DIR" -type f \( -iname '*.png' -o -iname '*.PNG' \) -print0 | sort -z)

if [ "${#pngs[@]}" -eq 0 ]; then
  echo "No PNG files found in $SCREENSHOTS_DIR"
  exit 0
fi

classify_screenshot() {
  local file="$1"
  local width="$2"
  local height="$3"
  local path name ratio_scaled

  path="$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')"
  name="$(basename "$path")"

  if [[ "$path" == */ipad/* || "$name" == *ipad* ]]; then
    echo "ipad"
    return 0
  fi

  if [[ "$name" == *iphone* || "$name" == *phone* ]]; then
    echo "phone"
    return 0
  fi

  if [ "$height" -gt "$width" ]; then
    ratio_scaled=$(( height * 1000 / width ))
    if [ "$ratio_scaled" -ge 2000 ] && [ "$ratio_scaled" -le 2300 ]; then
      echo "phone"
      return 0
    fi
  fi

  if [ "$height" -gt "$width" ]; then
    ratio_scaled=$(( height * 1000 / width ))
  else
    ratio_scaled=$(( width * 1000 / height ))
  fi

  if [ "$ratio_scaled" -ge 1280 ] && [ "$ratio_scaled" -le 1360 ]; then
    echo "ipad"
    return 0
  fi

  echo "other"
}

is_valid_phone_size() {
  local width="$1"
  local height="$2"
  [ "$width" -eq "$PHONE_WIDTH" ] && [ "$height" -eq "$PHONE_HEIGHT" ]
}

is_valid_ipad_size() {
  local width="$1"
  local height="$2"

  case "${width}x${height}" in
    2064x2752|2752x2064|2048x2732|2732x2048)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

processed=0
deleted=0
skipped=0

for file in "${pngs[@]}"; do
  read -r width height < <(magick identify -format "%w %h\n" "$file")
  screenshot_type="$(classify_screenshot "$file" "$width" "$height")"

  if [ "$screenshot_type" = "phone" ]; then
    output_path="$file"
    if [[ "$(basename "$file")" != "${PHONE_PREFIX}"* ]]; then
      output_path="$(dirname "$file")/${PHONE_PREFIX}$(basename "$file")"
    fi

    if [ "$file" = "$output_path" ] && is_valid_phone_size "$width" "$height"; then
      echo "Skipping valid phone screenshot: $(basename "$file")"
      skipped=$((skipped + 1))
      continue
    fi

    if [ -f "$output_path" ] && [ "$file" != "$output_path" ]; then
      read -r output_width output_height < <(magick identify -format "%w %h\n" "$output_path")
      if is_valid_phone_size "$output_width" "$output_height"; then
        echo "Keeping existing resized phone screenshot: $(basename "$output_path")"
      else
        echo "Resizing $(basename "$file") -> $(basename "$output_path")"
        magick "$file" -resize "${PHONE_WIDTH}x${PHONE_HEIGHT}!" "$output_path"
        processed=$((processed + 1))
      fi
    else
      echo "Resizing $(basename "$file") -> $(basename "$output_path")"
      magick "$file" -resize "${PHONE_WIDTH}x${PHONE_HEIGHT}!" "$output_path"
      processed=$((processed + 1))
    fi

    if [ "$file" != "$output_path" ] && ! is_valid_phone_size "$width" "$height"; then
      rm "$file"
      echo "Deleted source screenshot: $(basename "$file")"
      deleted=$((deleted + 1))
    fi
    continue
  fi

  if [ "$screenshot_type" = "ipad" ]; then
    if is_valid_ipad_size "$width" "$height"; then
      echo "Skipping valid iPad screenshot: $(basename "$file")"
      skipped=$((skipped + 1))
      continue
    fi

    temp_path="${file}.tmp.png"
    if [ "$height" -gt "$width" ]; then
      target="${IPAD_PORTRAIT_WIDTH}x${IPAD_PORTRAIT_HEIGHT}!"
    else
      target="${IPAD_LANDSCAPE_WIDTH}x${IPAD_LANDSCAPE_HEIGHT}!"
    fi

    echo "Resizing iPad screenshot $(basename "$file")"
    magick "$file" -resize "$target" "$temp_path"
    mv "$temp_path" "$file"
    processed=$((processed + 1))
    continue
  fi

  echo "Skipping unrecognized screenshot: $(basename "$file")"
  skipped=$((skipped + 1))
done

echo "Done. Processed: $processed, deleted: $deleted, skipped: $skipped"
