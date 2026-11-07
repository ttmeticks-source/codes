#!/bin/bash
set -Eeuo pipefail
REPO="ttmeticks-source/codes"
BRANCH="main"
APP="OceanForge"
MIN=11
fail(){ printf '\nERROR: %s\n' "$1" >&2; exit 1; }
printf '\n=== OCEANFORGE INSTALLER 3.0 ===\n'
[[ "$(/usr/bin/uname -s)" == Darwin ]] || fail "macOS only."
V="$(/usr/bin/sw_vers -productVersion)"; M="${V%%.*}"
[[ "$M" =~ ^[0-9]+$ ]] && (( M >= MIN )) || fail "Requires macOS 11 or newer; found $V."
CLT="/Library/Developer/CommandLineTools"
[[ -x "$CLT/usr/bin/swift" ]] || fail "Install standalone Command Line Tools using xcode-select --install. Do not install Xcode.app."
export DEVELOPER_DIR="$CLT" PATH="$CLT/usr/bin:$PATH" MACOSX_DEPLOYMENT_TARGET=11.0
T="$(/usr/bin/mktemp -d)"; trap '/bin/rm -rf "$T"' EXIT
printf 'Downloading OceanForge source...\n'
/usr/bin/curl --fail --location --silent --show-error --retry 3 "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" -o "$T/src.tgz" || fail "GitHub source archive returned an error. Confirm the repository is public."
/bin/mkdir "$T/src"; /usr/bin/tar -xzf "$T/src.tgz" -C "$T/src" --strip-components=1
[[ -f "$T/src/Package.swift" ]] || fail "Source archive is missing Package.swift."
cd "$T/src"
printf 'Building for macOS 11+...\n'
swift build -c release || fail "Build failed; compiler output is above."
BIN="$(swift build -c release --show-bin-path)/$APP"
[[ -x "$BIN" ]] || fail "Executable missing after build."
OUT="$T/$APP.app"; /bin/mkdir -p "$OUT/Contents/MacOS" "$OUT/Contents/Resources"
 /bin/cp "$BIN" "$OUT/Contents/MacOS/$APP"
if [[ -f "$T/src/Assets/OceanForge.icns.base64" ]]; then
  /usr/bin/base64 -D "$T/src/Assets/OceanForge.icns.base64" > "$OUT/Contents/Resources/OceanForge.icns"
fi
/usr/bin/plutil -create xml1 "$OUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $APP" "$OUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $APP" "$OUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.ttmeticks.oceanforge" "$OUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $APP" "$OUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$OUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string 1.0.0" "$OUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 1.0.0" "$OUT/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 11.0" "$OUT/Contents/Info.plist"
if [[ -f "$OUT/Contents/Resources/OceanForge.icns" ]]; then /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string OceanForge" "$OUT/Contents/Info.plist"; fi
/usr/bin/codesign --force --deep --sign - "$OUT" >/dev/null 2>&1 || fail "Could not sign app."
DEST="$HOME/Applications"; /bin/mkdir -p "$DEST"; /bin/rm -rf "$DEST/$APP.app"; /usr/bin/ditto "$OUT" "$DEST/$APP.app"
printf '\nInstalled: %s/%s.app\n' "$DEST" "$APP"
printf 'Minimum macOS: 11.0 | Toolchain: standalone Command Line Tools\n'
/usr/bin/open "$DEST/$APP.app"
