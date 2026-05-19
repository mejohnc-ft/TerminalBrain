#!/usr/bin/env zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INSTALL_DIR="${TERMINAL_BRAIN_INSTALL_DIR:-$HOME/Applications}"
APP_NAME="Terminal Brain.app"
BUILD_APP="$ROOT/mac-app/build/$APP_NAME"
DEST_APP="$INSTALL_DIR/$APP_NAME"
LAUNCH_AFTER_INSTALL="${TERMINAL_BRAIN_LAUNCH_AFTER_INSTALL:-0}"

case "${1:-}" in
  --help|-h)
    cat <<'EOF'
Usage: ./mac-app/scripts/install-app.zsh [--launch]

Builds and copies Terminal Brain to ~/Applications.
Default behavior does not launch or foreground the app.

Options:
  --launch  Launch Terminal Brain after install.
  --help    Show this help.
EOF
    exit 0
    ;;
  --launch)
    LAUNCH_AFTER_INSTALL="1"
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

if [[ "$LAUNCH_AFTER_INSTALL" == "1" ]]; then
  open -a "$DEST_APP"
fi

echo "$DEST_APP"
