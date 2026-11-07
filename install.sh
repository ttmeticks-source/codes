#!/bin/bash
set -Eeuo pipefail

REPO="ttmeticks-source/codes"
BRANCH="main"
APP_NAME="OceanForge"
MIN_MACOS_MAJOR=11
TMP=""

cleanup() {
  if [[ -n "${TMP:-}" && -d "$TMP" ]]; then
    /bin/rm -rf "$TMP"
  fi
}
trap cleanup EXIT

fail() {
  printf '\nERROR: %s\n' "$1" >&2
  exit 1
}

printf '========================================\n'
printf '        OceanForge macOS Installer      \n'
printf '========================================\n\n'

[[ "$(/usr/bin/uname -s)" == "Darwin" ]] || fail "This installer only works on macOS."

MACOS_VERSION="$(/usr/bin/sw_vers -productVersion)"
MACOS_MAJOR="${MACOS_VERSION%%.*}"
[[ "$MACOS_MAJOR" =~ ^[0-9]+$ ]] || fail "Could not determine the macOS version."
(( MACOS_MAJOR >= MIN_MACOS_MAJOR )) || fail "OceanForge requires macOS 11.0 or newer. Detected: $MACOS_VERSION"

printf 'macOS detected: %s\n' "$MACOS_VERSION"
printf 'Minimum supported version: 11.0\n\n'

# Use the standalone Command Line Tools installation, never an Xcode.app toolchain.
CLT="/Library/Developer/CommandLineTools"
if [[ -x "$CLT/usr/bin/swift" ]]; then
  export DEVELOPER_DIR="$CLT"
  export PATH="$CLT/usr/bin:$PATH"
else
  fail "Swift was not found. Install Apple's standalone Command Line Tools with: xcode-select --install . You do NOT need to install or open the Xcode app. Then run this installer again."
fi

command -v swift >/dev/null 2>&1 || fail "Swift is unavailable in the selected Command Line Tools."
printf 'Swift toolchain: '
swift --version | /usr/bin/head -n 1
printf 'Using Command Line Tools; no Xcode project or Xcode.app is required.\n\n'

TMP="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/oceanforge-install.XXXXXX")"
ARCHIVE="$TMP/source.tar.gz"
SOURCE_DIR="$TMP/source"

printf 'Downloading source from GitHub...\n'
/usr/bin/curl --fail --location --silent --show-error --retry 3 \
  "https://codeload.github.com/$REPO/tar.gz/refs/heads/$BRANCH" \
  --output "$ARCHIVE" || fail "Could not download the source archive. Check your internet connection and try again."

/bin/mkdir -p "$SOURCE_DIR"
/usr/bin/tar -xzf "$ARCHIVE" -C "$SOURCE_DIR" --strip-components=1
[[ -f "$SOURCE_DIR/Package.swift" ]] || fail "The downloaded source archive does not contain Package.swift."

printf '\nBuilding %s from source (this can take a few minutes)...\n' "$APP_NAME"
cd "$SOURCE_DIR"
export MACOSX_DEPLOYMENT_TARGET=11.0
swift build --configuration release || fail "The Swift build failed. The full compiler output above should show the reason."

BIN_PATH="$(swift build --configuration release --show-bin-path)"
EXECUTABLE="$BIN_PATH/$APP_NAME"
[[ -x "$EXECUTABLE" ]] || fail "Build completed but the expected executable was not found: $EXECUTABLE"

APP="$TMP/$APP_NAME.app"
/bin/mkdir -p "$APP/Contents/MacOS"
/bin/cp "$EXECUTABLE" "$APP/Contents/MacOS/$APP_NAME"
/bin/cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>OceanForge</string>
<key>CFBundleDisplayName</key><string>OceanForge</string>
<key>CFBundleIdentifier</key><string>com.ttmeticks.oceanforge</string>
<key>CFBundleVersion</key><string>1.0.0</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleExecutable</key><string>OceanForge</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST

/usr/bin/codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || fail "Could not ad-hoc sign the app bundle."

DEST="/Applications"
if [[ ! -w "$DEST" ]]; then
  DEST="$HOME/Applications"
  /bin/mkdir -p "$DEST"
fi

/bin/rm -rf "$DEST/$APP_NAME.app"
/usr/bin/ditto "$APP" "$DEST/$APP_NAME.app"

printf '\n========================================\n'
printf 'Installation complete!\n'
printf 'App: %s/%s.app\n' "$DEST" "$APP_NAME"
printf 'Minimum macOS: 11.0\n'
printf 'Built with: standalone Command Line Tools\n'
printf '========================================\n'
printf '\nOpen it with:\n  open "%s/%s.app"\n' "$DEST" "$APP_NAME"
