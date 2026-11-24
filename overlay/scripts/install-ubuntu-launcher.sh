#!/usr/bin/env bash
# Install a menu entry that points at this particular source checkout.

. "$(dirname "$0")/require-bash.sh"

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
TEMPLATE="$ROOT/desktop/openbot-local.desktop.in"
APPLICATIONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
DESTINATION="$APPLICATIONS_DIR/openbot-local.desktop"

[ -f "$TEMPLATE" ] || { printf 'Launcher template not found: %s\n' "$TEMPLATE" >&2; exit 1; }
mkdir -p "$APPLICATIONS_DIR"

# Escape sed's replacement metacharacters so a checkout path containing them remains valid.
escaped_root="$(printf '%s' "$ROOT" | sed 's/[&|]/\\&/g')"
temporary="$(mktemp "$APPLICATIONS_DIR/.openbot-local.desktop.XXXXXX")"
sed "s|@OPENBOT_ROOT@|$escaped_root|g" "$TEMPLATE" >"$temporary"
mv "$temporary" "$DESTINATION"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPLICATIONS_DIR"
fi

printf 'Installed Ubuntu launcher: %s\n' "$DESTINATION"
