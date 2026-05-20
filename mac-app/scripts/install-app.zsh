#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INSTALL_DIR="${TERMINAL_BRAIN_INSTALL_DIR:-$HOME/Applications}"
APP_NAME="Terminal Brain.app"
BUILD_APP="$ROOT/mac-app/build/$APP_NAME"
DEST_APP="$INSTALL_DIR/$APP_NAME"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/install-app.zsh

Builds and copies Terminal Brain to ~/Applications.
This script never launches or foregrounds the app.

Options:
  --help  Show this help.
EOF
    exit 0
    ;;
  --launch)
    echo "--launch is disabled. Start Terminal Brain manually when you want it in focus." >&2
    exit 64
    ;;
  "")
    ;;
  *)
    echo "Unknown option: $1" >&2
    echo "Run ./mac-app/scripts/install-app.zsh --help" >&2
    exit 64
    ;;
esac

"$ROOT/mac-app/scripts/build-app.zsh" >/dev/null

mkdir -p "$INSTALL_DIR"
rm -rf "$DEST_APP"
/usr/bin/ditto "$BUILD_APP" "$DEST_APP"

echo "$DEST_APP"
