#!/usr/bin/env bash
# Apply the Ubuntu-only OpenBot configuration to an official source checkout.

set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$KIT_ROOT/ubuntu-config"
TARGET_INPUT="${1:-.}"

usage() {
  cat <<'EOF'
Usage: bash install.sh [OPENBOT_CHECKOUT]

Applies the OpenBot Ubuntu Init configuration to an existing official OpenBot checkout.
If the checkout path is omitted, the current directory is used.

This installer never writes .env, credentials, OAuth sessions, or model API keys.
EOF
}

case "$TARGET_INPUT" in
  -h|--help) usage; exit 0 ;;
esac

[ -d "$TARGET_INPUT" ] || { printf 'OpenBot checkout not found: %s\n' "$TARGET_INPUT" >&2; exit 1; }
TARGET="$(cd "$TARGET_INPUT" && pwd)"

for required in docker-compose.yml scripts/start.sh scripts/stop.sh scripts/require-bash.sh; do
  [ -f "$TARGET/$required" ] || {
    printf 'This does not look like an OpenBot source checkout: %s\n' "$TARGET" >&2
    exit 1
  }
done

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$TARGET/.openbot-ubuntu-init-backup/$STAMP"

backup_if_replaced() {
  local relative source destination
  relative="$1"
  source="$CONFIG_DIR/$relative"
  destination="$TARGET/$relative"
  [ -e "$destination" ] || return 0
  cmp -s "$source" "$destination" && return 0
  mkdir -p "$(dirname "$BACKUP_ROOT/$relative")"
  cp -a "$destination" "$BACKUP_ROOT/$relative"
}

copy_config() {
  local relative mode source destination
  relative="$1"
  mode="$2"
  source="$CONFIG_DIR/$relative"
  destination="$TARGET/$relative"
  [ -f "$source" ] || { printf 'Missing configuration file: %s\n' "$source" >&2; exit 1; }
  backup_if_replaced "$relative"
  mkdir -p "$(dirname "$destination")"
  install -m "$mode" "$source" "$destination"
}

ensure_line() {
  local file="$1" line="$2"
  touch "$file"
  grep -Fqx -- "$line" "$file" || printf '%s\n' "$line" >>"$file"
}

copy_config Makefile 644
copy_config .env.model-profiles.example 644
copy_config desktop/openbot-local.desktop.in 644
copy_config scripts/open-openbot.sh 755
copy_config scripts/use-model.sh 755
copy_config scripts/launch-openbot.sh 755
copy_config scripts/install-ubuntu-launcher.sh 755

ensure_line "$TARGET/.gitignore" '!.env.model-profiles.example'
ensure_line "$TARGET/.gitignore" '.langchain/'
ensure_line "$TARGET/.gitignore" '.copilotkit/'
ensure_line "$TARGET/.gitignore" '.openbot-ubuntu-init-backup/'
ensure_line "$TARGET/.dockerignore" '.langchain'
ensure_line "$TARGET/.dockerignore" '.copilotkit'

bash "$TARGET/scripts/install-ubuntu-launcher.sh"

if [ -d "$BACKUP_ROOT" ]; then
  printf 'Backed up replaced files to: %s\n' "$BACKUP_ROOT"
fi

cat <<EOF

OpenBot Ubuntu configuration installed in: $TARGET

Next steps:
  1. cd "$TARGET"
  2. cp .env.example .env       # if you do not have one already
  3. bun install
  4. Configure CopilotKit Intelligence and a model connection.
  5. make start-local
EOF
