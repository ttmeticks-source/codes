#!/bin/bash
set -Eeuo pipefail
APP="OceanForge"
MIN=11
fail(){ printf '\nERROR: %s\n' "$1" >&2; exit 1; }
printf '\n=== OCEANFORGE ONE-COMMAND INSTALLER ===\n'
[[ "$(/usr/bin/uname -s)" == Darwin ]] || fail "macOS only."
V="$(/usr/bin/sw_vers -productVersion)"; M="${V%%.*}"
[[ "$M" =~ ^[0-9]+$ ]] && (( M >= MIN )) || fail "Requires macOS 11 or newer; found $V."
T="$(/usr/bin/mktemp -d)"; trap '/bin/rm -rf "$T"' EXIT
URL="https://github.com/ttmeticks-source/codes/releases/download/latest/OceanForge-macOS.zip"
printf 'Downloading prebuilt universal macOS app...\n'
/usr/bin/curl --fail --location --silent --show-error --retry 3 "$URL" -o "$T/OceanForge.zip" || fail "The prebuilt app release is not ready yet. Try again in a minute."
/usr/bin/unzip -q "$T/OceanForge.zip" -d "$T" || fail "The app archive could not be unpacked."
[[ -d "$T/OceanForge.app" ]] || fail "The release archive did not contain OceanForge.app."
/usr/bin/codesign --verify --deep --strict "$T/OceanForge.app" >/dev/null 2>&1 || fail "The downloaded app failed its code-signature integrity check."
DEST="$HOME/Applications"
/bin/mkdir -p "$DEST"
/bin/rm -rf "$DEST/$APP.app"
/usr/bin/ditto "$T/OceanForge.app" "$DEST/$APP.app"
printf '\nInstalled: %s/%s.app\n' "$DEST" "$APP"
printf 'No Xcode, Swift compiler, or Command Line Tools required on this Mac.\n'
/usr/bin/open "$DEST/$APP.app"
