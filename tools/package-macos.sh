#!/bin/bash
# Local unsigned preview, or Developer ID signed + notarized installer.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-release}"
case "$MODE" in
  preview) ;;
  release)
    : "${DOTAPING_APP_IDENTITY:?Set the Developer ID Application identity}"
    : "${DOTAPING_INSTALLER_IDENTITY:?Set the Developer ID Installer identity}"
    : "${DOTAPING_NOTARY_PROFILE:?Set the notarytool Keychain profile name}"
    [[ "$DOTAPING_APP_IDENTITY" == "Developer ID Application:"* ]] || { echo 'Expected a Developer ID Application certificate' >&2; exit 1; }
    [[ "$DOTAPING_INSTALLER_IDENTITY" == "Developer ID Installer:"* ]] || { echo 'Expected a Developer ID Installer certificate' >&2; exit 1; }
    ;;
  *) echo 'Usage: bash tools/package-macos.sh [preview|release]' >&2; exit 2 ;;
esac
if [[ "$MODE" == preview ]]; then
  unset DOTAPING_APP_IDENTITY
fi
bash "$ROOT/build.sh"
APP="$ROOT/dist/DotaPing.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
if [[ "$MODE" == preview ]]; then
  PKG="$ROOT/dist/DotaPing-$VERSION-local-preview.pkg"
  pkgbuild --component "$APP" --install-location /Applications "$PKG"
  echo "Unsigned local preview only: $PKG"
  exit 0
fi
PKG="$ROOT/dist/DotaPing-$VERSION.pkg"
pkgbuild --component "$APP" --install-location /Applications \
  --sign "$DOTAPING_INSTALLER_IDENTITY" --timestamp "$PKG"
pkgutil --check-signature "$PKG"
# Keep the complete result so a rejected submission can be inspected.
xcrun notarytool submit "$PKG" --keychain-profile "$DOTAPING_NOTARY_PROFILE" \
  --wait --output-format json > "$ROOT/dist/notarization-result.json"
python3 - "$ROOT/dist/notarization-result.json" <<'PY'
import json, sys
result = json.load(open(sys.argv[1]))
if result.get('status') != 'Accepted':
    raise SystemExit('Notarization was not accepted. Inspect dist/notarization-result.json and retrieve the notarytool log using its submission id.')
PY
xcrun stapler staple "$PKG"
xcrun stapler validate "$PKG"
spctl --assess --type install --verbose=2 "$PKG"
shasum -a 256 "$PKG" > "$PKG.sha256"
echo "Signed, notarized installer: $PKG"
