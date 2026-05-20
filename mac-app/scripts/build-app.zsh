#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Terminal Brain.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"

cp "$ROOT/Info.plist" "$CONTENTS/Info.plist"

swiftc \
  -target arm64-apple-macosx14.0 \
  -framework SwiftUI \
  -framework AppKit \
  -framework Network \
  -framework AppIntents \
  "$ROOT"/Sources/TerminalBrain/*.swift \
  -o "$MACOS/TerminalBrain"

chmod +x "$MACOS/TerminalBrain"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP" >/dev/null
fi

printf '%s\n' "$APP"
