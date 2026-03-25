#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${REPO_ROOT}"

APP_NAME="ClaudeGlance.app"
DIST_DIR="${REPO_ROOT}/dist"
DERIVED_DATA_DIR="${REPO_ROOT}/build/DerivedData"
APP_SOURCE_PATH="${DERIVED_DATA_DIR}/Build/Products/Release/${APP_NAME}"
APP_DIST_PATH="${DIST_DIR}/${APP_NAME}"
ZIP_PATH="${DIST_DIR}/ClaudeGlance.zip"

rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

xcodebuild build \
  -project ClaudeDash.xcodeproj \
  -scheme ClaudeDash \
  -configuration Release \
  -derivedDataPath "${DERIVED_DATA_DIR}" \
  -destination "platform=macOS"

if [[ ! -d "${APP_SOURCE_PATH}" ]]; then
  echo "Release app not found at ${APP_SOURCE_PATH}" >&2
  exit 1
fi

ditto "${APP_SOURCE_PATH}" "${APP_DIST_PATH}"
ditto -c -k --sequesterRsrc --keepParent "${APP_DIST_PATH}" "${ZIP_PATH}"

echo
echo "Built artifacts:"
ls -la "${DIST_DIR}"
echo
echo "SHA-256:"
shasum -a 256 "${ZIP_PATH}"
