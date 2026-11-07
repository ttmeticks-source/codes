#!/bin/bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
VERSION="${VERSION:-1.0.0}"
export MACOSX_DEPLOYMENT_TARGET=11.0
CLT="/Library/Developer/CommandLineTools"
if [[ -x "$CLT/usr/bin/swiftc" ]]; then export DEVELOPER_DIR="$CLT" PATH="$CLT/usr/bin:$PATH"; fi
mkdir -p "$ROOT/build"
# Build both Apple Silicon and Intel slices on the GitHub macOS builder.
for ARCH in arm64 x86_64; do
  swiftc -O -target "${ARCH}-apple-macosx11.0" -framework AppKit -framework SceneKit -framework SwiftUI -framework QuartzCore Sources/OceanForge/main.swift -o "$ROOT/build/OceanForge-$ARCH"
done
lipo -create "$ROOT/build/OceanForge-arm64" "$ROOT/build/OceanForge-x86_64" -output "$ROOT/build/OceanForge"
APP="$ROOT/build/OceanForge.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
if [[ -f "$ROOT/Assets/OceanForge.icns.base64" ]]; then
  base64 -D "$ROOT/Assets/OceanForge.icns.base64" > "$APP/Contents/Resources/OceanForge.icns"
fi
cp "$ROOT/build/OceanForge" "$APP/Contents/MacOS/OceanForge"
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
<key>LSMinimumSystemVersion</key><string>11.0</string>
<key>CFBundleIconFile</key><string>OceanForge</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP" >/dev/null
echo "Built universal app: $APP"
