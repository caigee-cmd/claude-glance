#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 /absolute/or/relative/path/to/icon-1024.png" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_ICON="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
APPICON_DIR="${REPO_ROOT}/ClaudeDash/Resources/Assets.xcassets/AppIcon.appiconset"
MENUBAR_DIR="${REPO_ROOT}/ClaudeDash/Resources/Assets.xcassets/MenuBarIcon.imageset"
MENUBAR_SCRIPT="${SCRIPT_DIR}/generate-menubar-icon.py"

if [[ ! -f "${SOURCE_ICON}" ]]; then
  echo "Source icon not found: ${SOURCE_ICON}" >&2
  exit 1
fi

mkdir -p "${APPICON_DIR}"
mkdir -p "${MENUBAR_DIR}"

generate_icon() {
  local size="$1"
  local output="$2"
  sips -s format png -z "${size}" "${size}" "${SOURCE_ICON}" --out "${APPICON_DIR}/${output}" >/dev/null
}

generate_icon 16 "icon_16x16.png"
generate_icon 32 "icon_16x16@2x.png"
generate_icon 32 "icon_32x32.png"
generate_icon 64 "icon_32x32@2x.png"
generate_icon 128 "icon_128x128.png"
generate_icon 256 "icon_128x128@2x.png"
generate_icon 256 "icon_256x256.png"
generate_icon 512 "icon_256x256@2x.png"
generate_icon 512 "icon_512x512.png"
generate_icon 1024 "icon_512x512@2x.png"

if python3 -c 'from PIL import Image' >/dev/null 2>&1; then
  python3 "${MENUBAR_SCRIPT}" "${SOURCE_ICON}" "${MENUBAR_DIR}/menubar_18x18.png" 18
  python3 "${MENUBAR_SCRIPT}" "${SOURCE_ICON}" "${MENUBAR_DIR}/menubar_18x18@2x.png" 36
else
  echo "Pillow not found; falling back to a direct menu bar icon resize." >&2
  sips -s format png -z 18 18 "${SOURCE_ICON}" --out "${MENUBAR_DIR}/menubar_18x18.png" >/dev/null
  sips -s format png -z 36 36 "${SOURCE_ICON}" --out "${MENUBAR_DIR}/menubar_18x18@2x.png" >/dev/null
fi

echo "Generated app icon set in:"
echo "${APPICON_DIR}"
echo
ls -la "${APPICON_DIR}"
echo
echo "Generated menu bar icon set in:"
echo "${MENUBAR_DIR}"
echo
ls -la "${MENUBAR_DIR}"
