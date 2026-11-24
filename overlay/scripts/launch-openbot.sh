#!/usr/bin/env bash
# Ubuntu app-menu launcher: start the local stack when necessary, then open it
# in Chrome's app window mode. No credentials or session URL are printed.

. "$(dirname "$0")/require-bash.sh"

set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$PWD"
LOG_DIR="$ROOT/.logs"
LOG_FILE="$LOG_DIR/launcher.log"

mkdir -p "$LOG_DIR"

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send --app-name=OpenBot "$1" "$2" >/dev/null 2>&1 || true
}

is_ready() {
  curl -fsS --max-time 3 http://127.0.0.1:3001/health >/dev/null 2>&1 \
    && curl -fsS --max-time 3 http://127.0.0.1:3010/ >/dev/null 2>&1 \
    && docker compose exec -T postgres pg_isready -U openbot -d openbot >/dev/null 2>&1
}

# A second click while startup is in progress should not race Docker or Vite.
exec 9>"$LOG_DIR/launcher.lock"
if command -v flock >/dev/null 2>&1 && ! flock -n 9; then
  notify "OpenBot is starting" "The local launcher is already running."
  exit 0
fi

if ! is_ready; then
  notify "Starting OpenBot" "This can take a short while on the first launch."
  if ! OPENBOT_IMAGE_PULL_POLICY=never bash "$ROOT/scripts/use-model.sh" start >>"$LOG_FILE" 2>&1; then
    notify "OpenBot did not start" "See .logs/launcher.log for details."
    exit 1
  fi
fi

if ! bash "$ROOT/scripts/open-openbot.sh" --app >>"$LOG_FILE" 2>&1; then
  notify "OpenBot could not open" "See .logs/launcher.log for details."
  exit 1
fi
