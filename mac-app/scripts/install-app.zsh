#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INSTALL_DIR="${TERMINAL_BRAIN_INSTALL_DIR:-$HOME/Applications}"
APP_NAME="Terminal Brain.app"
BUILD_APP="$ROOT/mac-app/build/$APP_NAME"
DEST_APP="$INSTALL_DIR/$APP_NAME"

"$ROOT/mac-app/scripts/build-app.zsh" >/dev/null

mkdir -p "$INSTALL_DIR"
rm -rf "$DEST_APP"
/usr/bin/ditto "$BUILD_APP" "$DEST_APP"

open -a "$DEST_APP"

echo "$DEST_APP"
