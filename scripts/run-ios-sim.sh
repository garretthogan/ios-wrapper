#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${IOS_PROJECT_PATH:-WebShell.xcodeproj}"
SCHEME="${IOS_SCHEME:-WebShell}"
CONFIGURATION="${IOS_CONFIGURATION:-Debug}"
APP_NAME="${IOS_APP_NAME:-WebShell}"
DEVICE_NAME="${IOS_SIM_DEVICE:-iPhone 17}"
DERIVED_DATA_PATH="${IOS_DERIVED_DATA_PATH:-.build/DerivedData}"

list_iphone_simulators() {
  xcrun simctl list devices available 2>/dev/null | awk '/^[[:space:]]*iPhone /'
}

resolve_simulator() {
  local target_name="$1"
  local prefix_match=""
  local line name udid

  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*([^()]+)[[:space:]]+\(([A-F0-9-]+)\)[[:space:]]+\((Booted|Shutdown)\) ]] || continue
    name="${BASH_REMATCH[1]% }"
    udid="${BASH_REMATCH[2]}"

    if [[ "$name" == "$target_name" ]]; then
      echo "${udid}|${name}"
      return 0
    fi

    if [[ -z "$prefix_match" && "$name" == "$target_name"* ]]; then
      prefix_match="${udid}|${name}"
    fi
  done < <(list_iphone_simulators)

  echo "$prefix_match"
}

resolve_any_iphone() {
  local line name udid

  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*([^()]+)[[:space:]]+\(([A-F0-9-]+)\)[[:space:]]+\((Booted|Shutdown)\) ]] || continue
    name="${BASH_REMATCH[1]% }"
    udid="${BASH_REMATCH[2]}"
    echo "${udid}|${name}"
    return 0
  done < <(list_iphone_simulators)

  echo ""
}

SIM_RESOLUTION="$(resolve_simulator "$DEVICE_NAME")"
if [[ -z "$SIM_RESOLUTION" ]]; then
  echo "No available simulator matched '$DEVICE_NAME'."
  SIM_RESOLUTION="$(resolve_any_iphone)"
fi

if [[ -z "$SIM_RESOLUTION" ]]; then
  echo "Could not find any available iPhone simulator."
  echo "Available devices:"
  list_iphone_simulators
  exit 1
fi

SIM_UDID="${SIM_RESOLUTION%%|*}"
SIM_NAME="${SIM_RESOLUTION##*|}"

echo "Using simulator: ${SIM_NAME} (${SIM_UDID})"

# Boot and wait for readiness.
xcrun simctl boot "$SIM_UDID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIM_UDID" -b

# Bring Simulator UI to front for visibility.
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID" || true

echo "Building ${SCHEME} (${CONFIGURATION})..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "id=${SIM_UDID}" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build

APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}-iphonesimulator/${APP_NAME}.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app not found at: $APP_PATH"
  exit 1
fi

APP_INFO_PLIST="${APP_PATH}/Info.plist"
BUNDLE_ID="${IOS_APP_BUNDLE_ID:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_INFO_PLIST" 2>/dev/null || true)}"
if [[ -z "$BUNDLE_ID" ]]; then
  echo "Unable to determine bundle identifier. Set IOS_APP_BUNDLE_ID."
  exit 1
fi

echo "Installing ${APP_NAME}.app..."
xcrun simctl install "$SIM_UDID" "$APP_PATH"

echo "Launching ${BUNDLE_ID}..."
xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID"

echo "Done."
