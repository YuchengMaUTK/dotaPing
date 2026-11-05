#!/bin/bash
set -euo pipefail
ROOT="$(dirname "$(realpath "$0")")"
python3 "$ROOT/tools/check-assets-ready.py"
swift build --package-path "$ROOT" -c release
APP="$ROOT/dist/DotaPing.app"
mkdir -p "$APP/Contents/MacOS"
BIN="$(swift build --package-path "$ROOT" -c release --show-bin-path)"
cp "$BIN/DotaPing" "$APP/Contents/MacOS/DotaPing"
mkdir -p "$APP/Contents/Resources"
cp -R "$BIN/DotaPing_DotaPing.bundle" "$APP/Contents/Resources/"
cp "$ROOT/Design/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>DotaPing</string>
<key>CFBundleIdentifier</key><string>local.dotaping.prototype</string>
<key>CFBundleName</key><string>DotaPing</string>
<key>CFBundleDisplayName</key><string>DotaPing</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.8.5</string>
<key>CFBundleVersion</key><string>14</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP"
plutil -lint "$APP/Contents/Info.plist"
codesign --verify --strict "$APP"
printf '\nBuilt: %s\n' "$APP"
