#!/bin/bash
set -euo pipefail

PRODUCT_NAME="QuickSpaceSwitch"
VOLUME_NAME="Quick Space Switch"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${PRODUCT_NAME}.app"
SIGN="${SIGN:--}"

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist 2>/dev/null || echo "unknown")
DMG_NAME="${BUILD_DIR}/${PRODUCT_NAME}-${VERSION}.dmg"

if [[ ! -d "${APP_BUNDLE}" ]]; then
  echo "Error: ${APP_BUNDLE} not found. Run dist/build.sh first."
  exit 1
fi

STAGE=$(mktemp -d)
trap 'rm -rf "${STAGE}"' EXIT
cp -R "${APP_BUNDLE}" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"

echo "Creating DMG..."
hdiutil create -volname "${VOLUME_NAME}" -srcfolder "${STAGE}" \
  -fs HFS+ -format UDZO -imagekey zlib-level=9 -ov "${DMG_NAME}" >/dev/null

if [[ "${SIGN}" != "-" ]]; then
  codesign --force --sign "${SIGN}" --timestamp "${DMG_NAME}"
fi

echo "DMG created at $(pwd)/${DMG_NAME}"
