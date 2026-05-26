#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/Modern RPN.xcodeproj"
SCHEME_NAME="Modern RPN"
BUNDLE_IDENTIFIER="comixmastertech.Modern-RPN"
APP_NAME="Modern RPN.app"
SCENARIO_ARGUMENT="-modern-rpn-screenshot-scenario"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.derived-data/screenshots}"
BUILD_LOG_PATH="${BUILD_LOG_PATH:-$ROOT_DIR/.derived-data/screenshots-build.log}"
PHONE_WIDTH=1284
PHONE_HEIGHT=2778
IPAD_WIDTH=2064
IPAD_HEIGHT=2752

SCENARIO=""
DEVICE_NAME=""
OUTPUT_PATH=""
PROFILE=""
SKIP_BUILD=0

usage() {
  cat <<'EOF'
Usage:
  scripts/capture-screenshot.sh --scenario <name> --device <simulator name> --output <png path> --profile <phone|ipad>

Options:
  --scenario   Screenshot scenario name wired into the app launch config
  --device     Simulator device name, for example: iPhone SE (3rd generation)
  --output     Raw screenshot path to write
  --profile    Resize profile: phone or ipad
  --skip-build Reuse the existing derived-data build output
  --help       Show this message
EOF
}

require_tool() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Missing required tool: $name" >&2
    exit 1
  fi
}

resolve_udid() {
  local selector="$1"
  if [[ "$selector" =~ ^[A-F0-9-]{36}$ ]]; then
    printf '%s\n' "$selector"
    return 0
  fi

  local line
  line="$(
    xcrun simctl list devices available |
      grep -F "    $selector (" |
      tail -n 1
  )"

  if [ -z "$line" ]; then
    echo "Unable to find an available simulator named: $selector" >&2
    exit 1
  fi

  printf '%s\n' "$line" | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/'
}

build_app() {
  local udid="$1"

  mkdir -p "$(dirname "$BUILD_LOG_PATH")"
  rm -rf "$DERIVED_DATA_PATH"

  if ! xcodebuild build \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "id=$udid" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    >"$BUILD_LOG_PATH" 2>&1; then
    cat "$BUILD_LOG_PATH" >&2
    exit 1
  fi
}

resize_output() {
  local raw_path="$1"
  local profile="$2"

  case "$profile" in
    phone)
      magick "$raw_path" -resize "${PHONE_WIDTH}x${PHONE_HEIGHT}!" "$raw_path"
      printf 'Resized %s in place\n' "$raw_path"
      ;;
    ipad)
      magick "$raw_path" -resize "${IPAD_WIDTH}x${IPAD_HEIGHT}!" "$raw_path"
      printf 'Resized %s in place\n' "$raw_path"
      ;;
    *)
      echo "Unknown profile: $profile" >&2
      exit 1
      ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --scenario)
      SCENARIO="${2:-}"
      shift 2
      ;;
    --device)
      DEVICE_NAME="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$SCENARIO" ] || [ -z "$DEVICE_NAME" ] || [ -z "$OUTPUT_PATH" ] || [ -z "$PROFILE" ]; then
  usage >&2
  exit 1
fi

require_tool xcodebuild
require_tool xcrun
require_tool open
require_tool magick

UDID="$(resolve_udid "$DEVICE_NAME")"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator/$APP_NAME"

mkdir -p "$(dirname "$OUTPUT_PATH")"

echo "Booting simulator: $DEVICE_NAME ($UDID)"
open -a Simulator --args -CurrentDeviceUDID "$UDID"
xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$UDID" -b

if [ "$SKIP_BUILD" -eq 0 ]; then
  echo "Building app for simulator capture"
  build_app "$UDID"
fi

if [ ! -d "$APP_PATH" ]; then
  echo "Built app not found at $APP_PATH" >&2
  exit 1
fi

echo "Installing app"
xcrun simctl install "$UDID" "$APP_PATH"
xcrun simctl terminate "$UDID" "$BUNDLE_IDENTIFIER" >/dev/null 2>&1 || true

echo "Launching scenario: $SCENARIO"
xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_IDENTIFIER" \
  "$SCENARIO_ARGUMENT" "$SCENARIO" >/dev/null

sleep 1

echo "Capturing screenshot -> $OUTPUT_PATH"
rm -f "$OUTPUT_PATH"
xcrun simctl io "$UDID" screenshot "$OUTPUT_PATH" >/dev/null

resize_output "$OUTPUT_PATH" "$PROFILE"
echo "Done"
