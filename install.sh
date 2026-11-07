#!/bin/bash
set -euo pipefail
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "OceanForge can only be installed on macOS." >&2; exit 1
fi
VERSION="$(/usr/bin/sw_vers -productVersion)"
MAJOR="${VERSION%%.*}"
if (( MAJOR < 11 )); then
  echo "OceanForge requires macOS 11.0 or later. This Mac is running $VERSION." >&2; exit 1
fi
echo "Installing OceanForge for macOS $VERSION..."
API="https://api.github.com/repos/ttmeticks-source/codes/releases/latest"
URL="$(/usr/bin/curl -fsSL "$API" | /usr/bin/python3 -c 'import json,sys; d=json.load(sys.stdin); print(next((a["browser_download_url"] for a in d.get("assets",[]) if a["name"]=="OceanForge-macOS.zip"), ""))')"
if [[ -z "$URL" ]]; then
  echo "No published release found yet: https://github.com/ttmeticks-source/codes/releases" >&2; exit 1
fi
TMP="$(/usr/bin/mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
/usr/bin/curl -fL "$URL" -o "$TMP/app.zip"
/usr/bin/ditto -x -k "$TMP/app.zip" "$TMP"
DEST="/Applications"
if [[ ! -w "$DEST" ]]; then DEST="$HOME/Applications"; mkdir -p "$DEST"; fi
rm -rf "$DEST/OceanForge.app"
/usr/bin/ditto "$TMP/OceanForge.app" "$DEST/OceanForge.app"
echo "Installed: $DEST/OceanForge.app"
