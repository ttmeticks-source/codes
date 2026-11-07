#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VERSION="${VERSION:-1.0.0}"
export MACOSX_DEPLOYMENT_TARGET=11.0
swift build -c release
BIN="$(swift build -c release --show-bin-path)/OceanForge"
APP="$ROOT/build/OceanForge.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"\nif [[ -f "$ROOT/Assets/OceanForge.icns.base64" ]]; then\n  base64 -D "$ROOT/Assets/OceanForge.icns.base64" > "$APP/Contents/Resources/OceanForge.icns"\nfi
cp "$BIN" "$APP/Contents/MacOS/OceanForge"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>OceanForge</string>
<key>CFBundleDisplayName</key><string>OceanForge</string>
<key>CFBundleIdentifier</key><string>com.ttmeticks.oceanforge</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleExecutable</key><string>OceanForge</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>\n<key>CFBundleIconFile</key><string>OceanForge</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP" >/dev/null
echo "Built $APP"
