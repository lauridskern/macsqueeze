#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MacSqueeze"
VERSION="${1:-0.1.0}"
DIST_DIR="${ROOT_DIR}/dist"
STAGE_DIR="${DIST_DIR}/dmg"
DMG_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.dmg"
CHECKSUM_PATH="${DMG_PATH}.sha256"

"${ROOT_DIR}/scripts/build-app.sh" "$VERSION" >/dev/null

rm -rf "$STAGE_DIR" "$DMG_PATH" "$CHECKSUM_PATH"
mkdir -p "$STAGE_DIR"

cp -R "$DIST_DIR/${APP_NAME}.app" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

shasum -a 256 "$DMG_PATH" > "$CHECKSUM_PATH"

echo "$DMG_PATH"
