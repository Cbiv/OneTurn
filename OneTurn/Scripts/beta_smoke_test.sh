#!/bin/zsh
set -euo pipefail

ROOT="/Users/christopherbivins/Desktop/Coding Thangs/OneTurn"
DERIVED="${HOME}/Library/Developer/Xcode/DerivedData/OneTurn-cgrtbyasckjqfybwzoqkbqqguzns"
APP_PATH="${DERIVED}/Build/Products/Debug-iphonesimulator/OneTurn.app"
SCREENSHOT_DIR="${ROOT}/QA/SmokeCaptures"
XCRUN=(env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun)

mkdir -p "${SCREENSHOT_DIR}"

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project "${ROOT}/OneTurn.xcodeproj" \
  -scheme OneTurn \
  -sdk iphonesimulator \
  -configuration Debug \
  build

BOOTED="$("${XCRUN[@]}" simctl list devices booted | awk -F '[()]' '/Booted/ {print $2; exit}')"

if [[ -z "${BOOTED}" ]]; then
  BOOTED="$("${XCRUN[@]}" simctl list devices available | awk -F '[()]' '/iPhone 16/ {print $2; exit}')"
  if [[ -z "${BOOTED}" ]]; then
    echo "No suitable simulator found."
    exit 1
  fi
  "${XCRUN[@]}" simctl boot "${BOOTED}" || true
fi

"${XCRUN[@]}" simctl install "${BOOTED}" "${APP_PATH}"
"${XCRUN[@]}" simctl launch "${BOOTED}" com.christopherbivins.oneturn
sleep 2
"${XCRUN[@]}" simctl io "${BOOTED}" screenshot "${SCREENSHOT_DIR}/smoke-home.png"

echo "Smoke test completed on simulator ${BOOTED}."
