#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INSTALL_DIR="${TERMINAL_BRAIN_INSTALL_DIR:-$HOME/Applications}"
APP_NAME="Terminal Brain.app"
BUILD_APP="$ROOT/mac-app/build/$APP_NAME"
DEST_APP="$INSTALL_DIR/$APP_NAME"
LAUNCH_AFTER_INSTALL="${TERMINAL_BRAIN_LAUNCH_AFTER_INSTALL:-0}"

if [[ "${1:-}" == "--launch" ]]; then
  LAUNCH_AFTER_INSTALL="1"
fi

"$ROOT/mac-app/scripts/build-app.zsh" >/dev/null

mkdir -p "$INSTALL_DIR"
rm -rf "$DEST_APP"
/usr/bin/ditto "$BUILD_APP" "$DEST_APP"

if [[ "$LAUNCH_AFTER_INSTALL" == "1" ]]; then
  open -a "$DEST_APP"
fi

echo "$DEST_APP"
