#!/bin/bash
# Builds the universal app, signs it with Developer ID, packs a DMG,
# notarizes it, and staples the ticket to the DMG and the app.
#
# One-time setup:
#   xcrun notarytool store-credentials hardeep-notary
#
# Override with SIGN=<identity> and NOTARY_PROFILE=<profile>.
# Contributors without a certificate use dist/build.sh (ad-hoc) instead.
set -euo pipefail
cd "$(dirname "$0")/.."

export SIGN="${SIGN:-Developer ID Application: Hardeep Singh (82GK3L7J3A)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-hardeep-notary}"

if [[ "${SIGN}" == "-" ]]; then
  echo "Error: notarization needs a Developer ID identity, not an ad-hoc signature."
  exit 1
fi

PRODUCT_NAME="QuickSpaceSwitch"
APP_BUNDLE="build/${PRODUCT_NAME}.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)
DMG="build/${PRODUCT_NAME}-${VERSION}.dmg"

./dist/build.sh --clean
codesign --verify --deep --strict "${APP_BUNDLE}"
./dist/deploy-to-dmg.sh

echo ""
echo "Notarizing ${DMG}..."
RESULT="build/notarization.json"
xcrun notarytool submit "${DMG}" --keychain-profile "${NOTARY_PROFILE}" \
  --wait --output-format json > "${RESULT}"
SUBMISSION_ID=$(plutil -extract id raw "${RESULT}")
STATUS=$(plutil -extract status raw "${RESULT}")
echo "Submission ${SUBMISSION_ID}: ${STATUS}"

if [[ "${STATUS}" != "Accepted" ]]; then
  xcrun notarytool log "${SUBMISSION_ID}" --keychain-profile "${NOTARY_PROFILE}"
  exit 1
fi

xcrun stapler staple "${DMG}"
xcrun stapler staple "${APP_BUNDLE}"
spctl -a -vv -t open --context context:primary-signature "${DMG}"
spctl -a -vv "${APP_BUNDLE}"

echo ""
echo "Release ready at $(pwd)/${DMG}"
